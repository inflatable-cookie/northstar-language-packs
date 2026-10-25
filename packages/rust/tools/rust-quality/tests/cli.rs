use serde_json::Value;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

struct Fixture {
    root: PathBuf,
}

impl Fixture {
    fn new(name: &str) -> Self {
        let nonce = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("clock after epoch")
            .as_nanos();
        let root = std::env::temp_dir().join(format!(
            "northstar-rust-{name}-{}-{nonce}",
            std::process::id()
        ));
        fs::create_dir_all(&root).expect("create fixture root");
        command(&root, "git", &["init", "--quiet"]);
        Self { root }
    }

    /// The engine child for this fixture.
    ///
    /// Oxide exports its shared Cargo build directory to every leased command,
    /// and a shared build directory gives two fixture crates with the same
    /// package name and version one Cargo unit, so a passing fixture could hide
    /// a failing one. Each fixture therefore builds into its own target
    /// directory under `.git/`, where neither the worktree scope nor a commit
    /// can see it.
    fn engine(&self) -> Command {
        let mut command = Command::new(env!("CARGO_BIN_EXE_northstar-rust-quality"));
        command
            .env(
                "CARGO_TARGET_DIR",
                self.root.join(".git/northstar-test-target"),
            )
            .env_remove("CARGO_BUILD_BUILD_DIR");
        command
    }

    fn write(&self, relative: &str, contents: &str) {
        let path = self.root.join(relative);
        fs::create_dir_all(path.parent().expect("fixture file parent")).expect("create parent");
        fs::write(path, contents).expect("write fixture file");
    }

    fn commit(&self) {
        command(&self.root, "git", &["add", "."]);
        command(
            &self.root,
            "git",
            &[
                "-c",
                "user.name=Northstar Test",
                "-c",
                "user.email=northstar@example.invalid",
                "commit",
                "--quiet",
                "-m",
                "fixture",
            ],
        );
    }

    fn inspect(&self) -> Value {
        self.inspect_scope("worktree")
    }

    fn inspect_scope(&self, scope: &str) -> Value {
        let output = self.engine()
            .args(["inspect", "--repo"])
            .arg(&self.root)
            .args(["--scope", scope])
            .output()
            .expect("run prototype");
        assert!(
            output.status.success(),
            "prototype failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
        serde_json::from_slice(&output.stdout).expect("parse prototype output")
    }

    fn inspect_failure(&self, scope: &str) -> std::process::Output {
        self.engine()
            .args(["inspect", "--repo"])
            .arg(&self.root)
            .args(["--scope", scope])
            .output()
            .expect("run prototype")
    }

    fn plan(&self, discovery: &Value, input: &Value) -> std::process::Output {
        let scratch = self.root.join(".git/northstar-test-inputs");
        fs::create_dir_all(&scratch).expect("create plan scratch");
        let discovery_path = scratch.join("discovery.json");
        let input_path = scratch.join("plan-input.json");
        fs::write(
            &discovery_path,
            serde_json::to_vec(discovery).expect("serialize discovery"),
        )
        .expect("write discovery");
        fs::write(
            &input_path,
            serde_json::to_vec(input).expect("serialize plan input"),
        )
        .expect("write plan input");
        self.engine()
            .args(["plan", "--discovery"])
            .arg(discovery_path)
            .args(["--input"])
            .arg(input_path)
            .output()
            .expect("run scope planner")
    }

    fn plan_value(&self, discovery: &Value, input: &Value) -> Value {
        let output = self.plan(discovery, input);
        assert_success(&output, "plan")
    }

    fn init_audit(&self, discovery: &Value, plan: &Value) -> std::process::Output {
        let scratch = self.root.join(".git/northstar-test-inputs");
        fs::create_dir_all(&scratch).expect("create lifecycle scratch");
        let discovery_path = scratch.join("lifecycle-discovery.json");
        let plan_path = scratch.join("lifecycle-plan.json");
        let profile_path = scratch.join("rust-quality-profile.json");
        let deviations_path = scratch.join("rust-quality-deviations.json");
        fs::write(
            &discovery_path,
            serde_json::to_vec(discovery).expect("discovery json"),
        )
        .expect("write discovery");
        fs::write(&plan_path, serde_json::to_vec(plan).expect("plan json")).expect("write plan");
        fs::write(
            &profile_path,
            br#"{"schema_version":"1.0.0","language":"rust","profile":"strict"}"#,
        )
        .expect("write profile");
        fs::write(
            &deviations_path,
            br#"{"schema_version":"1.0.0","language":"rust","deviations":[]}"#,
        )
        .expect("write deviations");
        self.engine()
            .args(["init", "--repo"])
            .arg(&self.root)
            .args(["--discovery"])
            .arg(discovery_path)
            .args(["--plan"])
            .arg(plan_path)
            .args(["--rules"])
            .arg(strict_projection_path())
            .args(["--profile"])
            .arg(profile_path)
            .args(["--deviations"])
            .arg(deviations_path)
            .output()
            .expect("initialize audit")
    }

    fn audit_operation(
        &self,
        operation: &str,
        audit_id: &str,
        input: &Value,
    ) -> std::process::Output {
        let input_path = self
            .root
            .join(".git/northstar-test-inputs")
            .join(format!("{operation}-input.json"));
        fs::write(
            &input_path,
            serde_json::to_vec(input).expect("operation json"),
        )
        .expect("write operation input");
        self.engine()
            .arg(operation)
            .args(["--repo"])
            .arg(&self.root)
            .args(["--audit", audit_id, "--input"])
            .arg(input_path)
            .output()
            .expect("run audit operation")
    }

    fn finalize(&self, audit_id: &str) -> std::process::Output {
        self.engine()
            .args(["finalize", "--repo"])
            .arg(&self.root)
            .args(["--audit", audit_id])
            .output()
            .expect("finalize audit")
    }

    fn closeout(&self, input: &Value) -> std::process::Output {
        self.closeout_in("closeout", input, &[])
    }

    fn closeout_committed(&self, input: &Value, base: &str, head: &str) -> std::process::Output {
        self.closeout_in("closeout-committed", input, &["--base", base, "--head", head])
    }

    fn closeout_in(&self, label: &str, input: &Value, extra: &[&str]) -> std::process::Output {
        let input_path = self
            .root
            .join(format!(".git/northstar-test-inputs/{label}.json"));
        fs::create_dir_all(input_path.parent().expect("closeout input parent"))
            .expect("create closeout input parent");
        fs::write(
            &input_path,
            serde_json::to_vec(input).expect("closeout json"),
        )
        .expect("write closeout input");
        self.engine()
            .args(["closeout", "--repo"])
            .arg(&self.root)
            .args(["--input"])
            .arg(input_path)
            .args(extra)
            .output()
            .expect("run closeout")
    }

    fn inspect_committed(&self, base: &str, head: &str) -> std::process::Output {
        self.engine()
            .args(["inspect", "--repo"])
            .arg(&self.root)
            .args(["--scope", "committed", "--base", base, "--head", head])
            .output()
            .expect("run committed inspect")
    }

    fn rev(&self, revision: &str) -> String {
        let output = Command::new("git")
            .current_dir(&self.root)
            .args(["rev-parse", revision])
            .output()
            .expect("resolve revision");
        assert!(
            output.status.success(),
            "git rev-parse {revision} failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
        String::from_utf8_lossy(&output.stdout).trim().to_owned()
    }

    fn status(&self) -> String {
        let output = Command::new("git")
            .current_dir(&self.root)
            .args(["status", "--porcelain=v1", "--untracked-files=all"])
            .output()
            .expect("read git status");
        assert!(output.status.success(), "git status failed");
        String::from_utf8_lossy(&output.stdout).into_owned()
    }

    fn git(&self, arguments: &[&str]) {
        command(&self.root, "git", arguments);
    }

    fn validate_ledger(&self, input: &Value) -> std::process::Output {
        let input_path = self.root.join("assessment-input.json");
        fs::write(
            &input_path,
            serde_json::to_vec(input).expect("serialize assessment input"),
        )
        .expect("write assessment input");
        self.engine()
            .args(["validate-ledger", "--rules"])
            .arg(strict_projection_path())
            .args(["--input"])
            .arg(input_path)
            .output()
            .expect("run ledger validation")
    }
}

impl Drop for Fixture {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.root);
    }
}

#[test]
fn discovers_root_workspace() {
    let fixture = Fixture::new("root");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"root-fixture\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");

    let record = fixture.inspect();
    assert_eq!(record["scope"], "worktree");
    assert_eq!(
        record["workspaces"].as_array().expect("workspaces").len(),
        1
    );
    assert_eq!(
        record["workspaces"][0]["packages"][0]["name"],
        "root-fixture"
    );
    assert_eq!(record["workspaces"][0]["root"], ".");
    assert_eq!(record["workspaces"][0]["manifest_path"], "Cargo.toml");
    assert_eq!(record["rust_anchors"][0]["path"], "src/lib.rs");
}

#[test]
fn discovers_nested_rust_in_mixed_repository() {
    let fixture = Fixture::new("mixed");
    fixture.write("package.json", "{\"private\":true}\n");
    fixture.write(
        "services/engine/Cargo.toml",
        "[package]\nname = \"nested-engine\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write(
        "services/engine/src/lib.rs",
        "pub fn ready() -> bool { false }\n",
    );
    fixture.write("apps/site/package.json", "{\"private\":true}\n");
    fixture.commit();
    fixture.write(
        "services/engine/src/lib.rs",
        "pub fn ready() -> bool { true }\n",
    );

    let record = fixture.inspect();
    let canonical_root = fs::canonicalize(&fixture.root).expect("canonical fixture root");
    assert_eq!(
        record["repository_root"],
        canonical_root.to_string_lossy().as_ref()
    );
    assert_eq!(
        record["workspaces"].as_array().expect("workspaces").len(),
        1
    );
    assert_eq!(
        record["workspaces"][0]["packages"][0]["name"],
        "nested-engine"
    );
    assert_eq!(
        record["rust_anchors"][0]["path"],
        "services/engine/src/lib.rs"
    );
}

#[test]
fn discovers_root_workspace_members_and_independent_nested_workspace() {
    let fixture = Fixture::new("workspace-tree");
    fixture.write(
        "Cargo.toml",
        "[workspace]\nmembers = [\"crates/api\", \"crates/core\"]\nresolver = \"3\"\n\n[workspace.package]\nversion = \"0.1.0\"\nedition = \"2024\"\n",
    );
    fixture.write(
        "crates/api/Cargo.toml",
        "[package]\nname = \"api\"\nversion.workspace = true\nedition.workspace = true\n",
    );
    fixture.write("crates/api/src/lib.rs", "pub fn api() {}\n");
    fixture.write(
        "crates/core/Cargo.toml",
        "[package]\nname = \"core\"\nversion.workspace = true\nedition.workspace = true\n",
    );
    fixture.write("crates/core/src/lib.rs", "pub fn core() {}\n");
    fixture.write(
        "tools/generator/Cargo.toml",
        "[workspace]\nmembers = [\"crate\"]\nresolver = \"3\"\n\n[workspace.package]\nversion = \"0.2.0\"\n",
    );
    fixture.write(
        "tools/generator/crate/Cargo.toml",
        "[package]\nname = \"generator\"\nversion.workspace = true\nedition = \"2024\"\n",
    );
    fixture.write("tools/generator/crate/src/main.rs", "fn main() {}\n");
    fixture.commit();
    fixture.write("crates/core/src/lib.rs", "pub fn core() { }\n");

    let record = fixture.inspect();
    let workspaces = record["workspaces"].as_array().expect("workspaces");
    assert_eq!(workspaces.len(), 2);

    let root = workspaces
        .iter()
        .find(|workspace| workspace["root"] == ".")
        .expect("root workspace");
    assert_eq!(root["manifest_path"], "Cargo.toml");
    let members: Vec<(&str, &str)> = root["packages"]
        .as_array()
        .expect("packages")
        .iter()
        .map(|package| {
            (
                package["name"].as_str().expect("package name"),
                package["manifest_path"].as_str().expect("manifest path"),
            )
        })
        .collect();
    assert_eq!(
        members,
        vec![
            ("api", "crates/api/Cargo.toml"),
            ("core", "crates/core/Cargo.toml"),
        ]
    );

    let generator = workspaces
        .iter()
        .find(|workspace| workspace["root"] == "tools/generator")
        .expect("independent nested workspace");
    assert_eq!(generator["manifest_path"], "tools/generator/Cargo.toml");
    assert_eq!(generator["packages"][0]["name"], "generator");
    assert_eq!(
        generator["packages"][0]["manifest_path"],
        "tools/generator/crate/Cargo.toml"
    );

    // Membership and attribution are deterministic across runs.
    let repeat = fixture.inspect();
    assert_eq!(record["workspaces"], repeat["workspaces"]);
    assert_eq!(record["snapshot_sha256"], repeat["snapshot_sha256"]);
}

#[test]
fn skips_unowned_workspace_templates() {
    let fixture = Fixture::new("unowned-templates");
    fixture.write(
        "Cargo.toml",
        "[workspace]\nmembers = [\"crates/core\"]\nexclude = [\"examples/excluded-template\"]\nresolver = \"3\"\n\n[workspace.package]\nversion = \"0.1.0\"\nedition = \"2024\"\n\n[workspace.dependencies]\nserde = \"1.0\"\n",
    );
    fixture.write(
        "crates/core/Cargo.toml",
        "[package]\nname = \"core\"\nversion.workspace = true\nedition.workspace = true\n\n[dependencies]\nserde.workspace = true\n",
    );
    fixture.write("crates/core/src/lib.rs", "pub fn core() {}\n");
    // Beneath the workspace root, but not a member and not excluded.
    fixture.write(
        "examples/template-in-root/Cargo.toml",
        "[package]\nname = \"template-in-root\"\nversion = \"0.0.0\"\nedition.workspace = true\n\n[dependencies]\nserde.workspace = true\n",
    );
    fixture.write(
        "examples/template-in-root/src/lib.rs",
        "pub fn template() {}\n",
    );
    // Explicitly excluded from the workspace and inheriting from no root.
    fixture.write(
        "examples/excluded-template/Cargo.toml",
        "[package]\nname = \"excluded-template\"\nversion = \"0.0.0\"\nedition.workspace = true\n",
    );
    fixture.write(
        "examples/excluded-template/src/lib.rs",
        "pub fn template() {}\n",
    );
    // Outside every workspace root and inheriting from no root.
    fixture.write(
        "vendored/template-no-root/Cargo.toml",
        "[package]\nname = \"template-no-root\"\nversion.workspace = true\nedition = \"2024\"\n",
    );
    fixture.write(
        "vendored/template-no-root/src/lib.rs",
        "pub fn template() {}\n",
    );
    // Unrelated non-Rust content and an ignored directory tree.
    fixture.write("package.json", "{\"private\":true}\n");
    fixture.write("docs/notes.md", "not a Rust workspace\n");
    fixture.write("node_modules/legacy/Cargo.toml", "[package\n");
    fixture.commit();
    fixture.write("crates/core/src/lib.rs", "pub fn core() { }\n");

    let record = fixture.inspect();
    let workspaces = record["workspaces"].as_array().expect("workspaces");
    assert_eq!(workspaces.len(), 1);
    assert_eq!(workspaces[0]["root"], ".");
    let names: Vec<&str> = workspaces[0]["packages"]
        .as_array()
        .expect("packages")
        .iter()
        .map(|package| package["name"].as_str().expect("package name"))
        .collect();
    assert_eq!(names, vec!["core"]);
    let manifests: Vec<&str> = workspaces[0]["packages"]
        .as_array()
        .expect("packages")
        .iter()
        .map(|package| package["manifest_path"].as_str().expect("manifest path"))
        .collect();
    assert!(
        !manifests.iter().any(|path| path.contains("template")),
        "unowned template entered discovery: {manifests:?}"
    );

    let repository = fixture.inspect_scope("repository");
    assert_eq!(repository["workspaces"], record["workspaces"]);
    assert_eq!(fixture.inspect()["workspaces"], record["workspaces"]);
}

#[test]
fn unowned_template_does_not_hide_a_malformed_member() {
    let fixture = Fixture::new("malformed-member");
    fixture.write(
        "Cargo.toml",
        "[workspace]\nmembers = [\"crates/core\", \"crates/broken\"]\nresolver = \"3\"\n\n[workspace.package]\nversion = \"0.1.0\"\nedition = \"2024\"\n",
    );
    fixture.write(
        "crates/core/Cargo.toml",
        "[package]\nname = \"core\"\nversion.workspace = true\nedition.workspace = true\n",
    );
    fixture.write("crates/core/src/lib.rs", "pub fn core() {}\n");
    fixture.write("crates/broken/Cargo.toml", "[package\nname = \"broken\"\n");
    fixture.write("crates/broken/src/lib.rs", "pub fn broken() {}\n");
    fixture.write(
        "examples/template-in-root/Cargo.toml",
        "[package]\nname = \"template-in-root\"\nversion = \"0.0.0\"\nedition.workspace = true\n",
    );
    fixture.write(
        "examples/template-in-root/src/lib.rs",
        "pub fn template() {}\n",
    );
    fixture.commit();
    fixture.write("crates/core/src/lib.rs", "pub fn core() { }\n");

    let output = fixture.inspect_failure("worktree");
    assert_eq!(output.status.code(), Some(2));
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        stderr.contains("cargo.metadata.failed"),
        "malformed member was not reported: {stderr}"
    );
    assert!(
        stderr.contains("crates/broken/Cargo.toml"),
        "malformed member path missing from {stderr}"
    );
}

#[test]
fn reports_broken_inheritance_in_a_real_member() {
    let fixture = Fixture::new("broken-inheritance");
    fixture.write(
        "Cargo.toml",
        "[workspace]\nmembers = [\"crates/core\"]\nresolver = \"3\"\n\n[workspace.package]\nversion = \"0.1.0\"\n",
    );
    fixture.write(
        "crates/core/Cargo.toml",
        "[package]\nname = \"core\"\nversion.workspace = true\nedition.workspace = true\n",
    );
    fixture.write("crates/core/src/lib.rs", "pub fn core() {}\n");
    fixture.commit();
    fixture.write("crates/core/src/lib.rs", "pub fn core() { }\n");

    let output = fixture.inspect_failure("worktree");
    assert_eq!(output.status.code(), Some(2));
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        stderr.contains("cargo.metadata.failed"),
        "broken member inheritance was not reported: {stderr}"
    );
    assert!(
        stderr.contains("workspace.package.edition") && stderr.contains("was not defined"),
        "member inheritance failure lost its cause: {stderr}"
    );
    assert!(
        !stderr.contains("failed to find a workspace root"),
        "member failure matched the unowned-template class: {stderr}"
    );
}

#[test]
fn rejects_anchorless_worktree_scope() {
    let fixture = Fixture::new("anchorless");
    fixture.write(
        "crates/core/Cargo.toml",
        "[package]\nname = \"core-fixture\"\nversion = \"0.1.0\"\nedition = \"2024\"\n",
    );
    fixture.write("crates/core/src/lib.rs", "pub fn stable() {}\n");
    fixture.write("README.md", "initial\n");
    fixture.commit();
    fixture.write("README.md", "changed\n");

    let output = fixture.engine()
        .args(["inspect", "--repo"])
        .arg(&fixture.root)
        .args(["--scope", "worktree"])
        .output()
        .expect("run prototype");
    assert_eq!(output.status.code(), Some(2));
    assert!(String::from_utf8_lossy(&output.stderr).contains("scope.no_worktree_anchor"));
}

#[test]
fn verifies_its_source_payload() {
    let crate_root = Path::new(env!("CARGO_MANIFEST_DIR"));
    let output = Command::new(env!("CARGO_BIN_EXE_northstar-rust-quality"))
        .args(["verify-install", "--source-root"])
        .arg(crate_root)
        .output()
        .expect("run install verification");
    assert!(
        output.status.success(),
        "verification failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let record: Value = serde_json::from_slice(&output.stdout).expect("parse receipt");
    assert_eq!(record["current"], true);
    assert_eq!(
        record["embedded_payload_sha256"],
        record["source_payload_sha256"]
    );
}

#[test]
fn plans_owned_worktree_scope_with_related_context() {
    let fixture = Fixture::new("worktree-plan");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"plan-fixture\"\nversion = \"0.1.0\"\nedition = \"2024\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.write("README.md", "answer: 41\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    fixture.write("README.md", "answer: 42\n");
    let discovery = fixture.inspect();
    let input = serde_json::json!({
        "audit_id": "worktree-plan",
        "units": [{
            "unit_id": "answer",
            "anchors": ["src/lib.rs"],
            "context": [{
                "path": "README.md",
                "anchor": "src/lib.rs",
                "relation": "governed_documentation"
            }]
        }],
        "excluded_dirty_files": [],
        "repository_coverage": null
    });
    let output = fixture.plan(&discovery, &input);
    assert!(
        output.status.success(),
        "plan failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let plan: Value = serde_json::from_slice(&output.stdout).expect("parse scope plan");
    assert_eq!(plan["units"][0]["mutable_files"][0], "src/lib.rs");
    assert_eq!(
        plan["units"][0]["read_only_context"][0]["path"],
        "README.md"
    );
}

#[test]
fn rejects_undisposed_dirty_context() {
    let fixture = Fixture::new("undisposed");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"undisposed-fixture\"\nversion = \"0.1.0\"\nedition = \"2024\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.write("README.md", "answer: 41\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    fixture.write("README.md", "answer: 42\n");
    let discovery = fixture.inspect();
    let input = serde_json::json!({
        "audit_id": "undisposed",
        "units": [{"unit_id": "answer", "anchors": ["src/lib.rs"], "context": []}],
        "excluded_dirty_files": [],
        "repository_coverage": null
    });
    let output = fixture.plan(&discovery, &input);
    assert_eq!(output.status.code(), Some(2));
    assert!(String::from_utf8_lossy(&output.stderr).contains("scope.dirty_undisposed"));
}

#[test]
fn proves_full_repository_coverage_from_cargo_inventory() {
    let fixture = Fixture::new("repository-plan");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"repository-fixture\"\nversion = \"0.1.0\"\nedition = \"2024\"\n[features]\nstrict = []\n",
    );
    fixture.write("src/lib.rs", "pub fn stable() {}\n");
    fixture.commit();
    let discovery = fixture.inspect_scope("repository");
    let input = serde_json::json!({
        "audit_id": "repository-plan",
        "units": [{
            "unit_id": "repository-fixture",
            "anchors": ["Cargo.toml", "src/lib.rs"],
            "context": []
        }],
        "excluded_dirty_files": [],
        "repository_coverage": {
            "claim": "full_repository",
            "workspaces": ["."],
            "packages": ["Cargo.toml"],
            "targets": ["src/lib.rs"],
            "features": ["repository-fixture:strict"],
            "public_api_surfaces": ["src/lib.rs"],
            "risk_boundaries": ["none: fixture has no unsafe, async, or FFI boundary"]
        }
    });
    let output = fixture.plan(&discovery, &input);
    assert!(
        output.status.success(),
        "repository plan failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn accepts_complete_strict_assessment() {
    let fixture = Fixture::new("ledger-complete");
    let output = fixture.validate_ledger(&complete_assessment());
    assert!(
        output.status.success(),
        "ledger failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let assessment: Value = serde_json::from_slice(&output.stdout).expect("parse assessment");
    assert_eq!(
        assessment["schema_version"],
        "northstar.rust-quality.assessment.v1"
    );
    assert_eq!(
        assessment["verdicts"].as_array().expect("verdicts").len(),
        6
    );
}

#[test]
fn rejects_incomplete_or_hollow_assessments() {
    let fixture = Fixture::new("ledger-hollow");
    let mut missing_rule = complete_assessment();
    missing_rule["verdicts"]
        .as_array_mut()
        .expect("verdicts")
        .pop();
    assert_ledger_error(
        &fixture.validate_ledger(&missing_rule),
        "ledger.verdict_inventory_mismatch",
    );

    let mut empty_attestation = complete_assessment();
    empty_attestation["attestations"][0]["evidence"] = serde_json::json!([]);
    assert_ledger_error(
        &fixture.validate_ledger(&empty_attestation),
        "ledger.attestation_evidence_empty",
    );

    let mut duplicate_rule = complete_assessment();
    let duplicate = duplicate_rule["verdicts"][0].clone();
    duplicate_rule["verdicts"]
        .as_array_mut()
        .expect("verdicts")
        .push(duplicate);
    assert_ledger_error(
        &fixture.validate_ledger(&duplicate_rule),
        "ledger.verdict_duplicate",
    );
}

#[test]
fn rejects_orphan_records_and_unauthorized_repairs() {
    let fixture = Fixture::new("ledger-authority");
    let mut orphan = complete_assessment();
    orphan["limitations"] = serde_json::json!([{
        "key": "service-unavailable",
        "kind": "external_service",
        "evidence": ["S3 was unavailable"]
    }]);
    assert_ledger_error(
        &fixture.validate_ledger(&orphan),
        "ledger.limitation_orphan_or_duplicate",
    );

    let mut unauthorized = complete_assessment();
    let unsafe_index = unauthorized["verdicts"]
        .as_array()
        .expect("verdicts")
        .iter()
        .position(|verdict| verdict["rule_id"] == "RUST-UNSAFE-001")
        .expect("unsafe verdict");
    unauthorized["verdicts"][unsafe_index]["verdict"] = serde_json::json!("finding");
    unauthorized["verdicts"][unsafe_index]["finding_ids"] = serde_json::json!(["unsafe-1"]);
    unauthorized["findings"] = serde_json::json!([{
        "finding_id": "unsafe-1",
        "rule_id": "RUST-UNSAFE-001",
        "action": "change_unsafe_boundary",
        "file": "src/lib.rs",
        "evidence": "Safety invariant is incomplete",
        "disposition": "repair_planned"
    }]);
    unauthorized["repair_plans"] = serde_json::json!([{
        "plan_id": "unsafe-repair",
        "finding_ids": ["unsafe-1"],
        "owned_files": ["src/lib.rs"],
        "preserved_behavior": ["Public API remains stable"]
    }]);
    assert_ledger_error(
        &fixture.validate_ledger(&unauthorized),
        "ledger.plan_authority_invalid",
    );
}

#[test]
fn runs_checked_repair_lifecycle_with_pre_mutation_extension() {
    let fixture = Fixture::new("lifecycle-repair");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"lifecycle-fixture\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.write("tests/answer.rs", "#[test]\nfn answer_is_stable() {}\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let discovery = fixture.inspect();
    let plan = fixture.plan_value(
        &discovery,
        &serde_json::json!({
            "audit_id": "repair-wave",
            "units": [{"unit_id": "core", "anchors": ["src/lib.rs"], "context": []}],
            "excluded_dirty_files": [],
            "repository_coverage": null
        }),
    );
    assert_success(&fixture.init_audit(&discovery, &plan), "init");
    assert_success(
        &fixture.audit_operation(
            "assess",
            "repair-wave",
            &assessment_with_readability_repair(),
        ),
        "assess",
    );
    assert_success(
        &fixture.audit_operation(
            "extend",
            "repair-wave",
            &serde_json::json!({
                "unit_id": "core",
                "reason": "focused regression coverage for the repair",
                "files": [{"path": "tests/answer.rs", "anchor": "src/lib.rs", "relation": "focused_test"}],
                "plan_extensions": [{"plan_id": "readability-repair", "files": ["tests/answer.rs"]}]
            }),
        ),
        "extend",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 43 }\n");
    fixture.write(
        "tests/answer.rs",
        "#[test]\nfn answer_is_stable() { assert_eq!(43, 43); }\n",
    );
    let evidence = assert_success(
        &fixture.audit_operation(
            "collect",
            "repair-wave",
            &serde_json::json!({
                "applicable_classes": ["test"],
                "requests": [{
                    "evidence_id": "focused-tests",
                    "unit_id": "core",
                    "evidence_class": "test",
                    "selector": "cargo test",
                    "origin": "cargo_native",
                    "package_cwd": ".",
                    "environment": "fixture; Rust 1.95+",
                    "execution": {
                        "kind": "command",
                        "program": "cargo",
                        "args": ["test", "--message-format=json-diagnostic-rendered-ansi"],
                        "format": "cargo_json"
                    }
                }]
            }),
        ),
        "collect evidence",
    );
    assert_eq!(evidence["records"][0]["status"], "passed");
    assert_success(
        &fixture.audit_operation(
            "complete",
            "repair-wave",
            &serde_json::json!({
                "unit_id": "core",
                "repairs": [{
                    "plan_id": "readability-repair",
                    "status": "applied",
                    "changed_files": ["src/lib.rs", "tests/answer.rs"]
                }],
                "evidence_ids": ["focused-tests"]
            }),
        ),
        "complete",
    );
    let result = assert_success(&fixture.finalize("repair-wave"), "finalize");
    assert_eq!(result["status"], "clean");
    assert_eq!(
        result["changed_files"].as_array().expect("changed").len(),
        2
    );
    assert!(
        fixture
            .root
            .join(".git/northstar/rust-quality/audits/repair-wave/report.md")
            .is_file()
    );
}

#[test]
fn distinguishes_warning_unavailable_and_unrun_evidence() {
    let fixture = initialized_lifecycle_fixture("evidence-wave", false);
    fixture.write(
        "src/lib.rs",
        "#![warn(missing_debug_implementations)]\npub struct Public;\n",
    );
    let result = assert_success(
        &fixture.audit_operation(
            "collect",
            "evidence-wave",
            &serde_json::json!({
                "applicable_classes": ["compiler", "lint", "test"],
                "requests": [
                    {
                        "evidence_id": "compiler-warning",
                        "unit_id": "core",
                        "evidence_class": "compiler",
                        "selector": "cargo check",
                        "origin": "cargo_native",
                        "package_cwd": ".",
                        "environment": "fixture; Rust 1.95+",
                        "execution": {
                            "kind": "command",
                            "program": "cargo",
                            "args": ["check", "--message-format=json-diagnostic-rendered-ansi"],
                            "format": "cargo_json"
                        }
                    },
                    {
                        "evidence_id": "lint-runner",
                        "unit_id": "core",
                        "evidence_class": "lint",
                        "selector": "missing lint runner",
                        "origin": "repository_task",
                        "package_cwd": ".",
                        "environment": "fixture",
                        "execution": {
                            "kind": "command",
                            "program": "northstar-definitely-missing-command",
                            "args": [],
                            "format": "generic"
                        }
                    }
                ]
            }),
        ),
        "collect warning evidence",
    );
    let records = result["records"].as_array().expect("records");
    let warning = records
        .iter()
        .find(|record| record["evidence_id"] == "compiler-warning")
        .expect("warning record");
    assert_eq!(warning["status"], "warning");
    assert_eq!(warning["exit_status"], 0);
    assert_eq!(warning["failure_stage"], "source");
    assert!(
        warning["diagnostics"]
            .as_array()
            .expect("diagnostics")
            .iter()
            .any(
                |diagnostic| diagnostic["identifier"] == "missing_debug_implementations"
                    && diagnostic["catalogue_evidence"] == serde_json::json!(["RUST-API-001"])
                    && diagnostic["mapping_disposition"] == "promote_evidence"
            )
    );
    assert_eq!(
        records
            .iter()
            .find(|record| record["evidence_id"] == "lint-runner")
            .expect("unavailable")["failure_stage"],
        "startup"
    );
    assert_eq!(
        records
            .iter()
            .find(|record| record["evidence_id"] == "unrun-test-core")
            .expect("unrun")["status"],
        "unrun"
    );
    assert_eq!(
        result["limitations"].as_array().expect("limitations").len(),
        3
    );
    assert!(result.get("findings").is_none());
    assert!(result.get("repair_plans").is_none());
}

#[test]
fn partial_later_collect_does_not_fabricate_unrun_for_sealed_classes() {
    let fixture = initialized_multi_unit_fixture("partial-collect-wave");
    let evidence_root = fixture
        .root
        .join(".git/northstar/rust-quality/audits/partial-collect-wave/evidence");

    let first = assert_success(
        &fixture.audit_operation(
            "collect",
            "partial-collect-wave",
            &serde_json::json!({
                "applicable_classes": ["test"],
                "requests": [{
                    "evidence_id": "test-core",
                    "unit_id": "core",
                    "evidence_class": "test",
                    "selector": "true",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "true",
                        "args": [],
                        "format": "generic"
                    }
                }]
            }),
        ),
        "first collect seals test/core",
    );
    assert_eq!(first["records"][0]["status"], "passed");
    let sealed_path = evidence_root.join("test-core.json");
    let sealed_before = fs::read(&sealed_path).expect("read sealed record");
    let inventory_before = evidence_inventory(&evidence_root);

    let second = assert_success(
        &fixture.audit_operation(
            "collect",
            "partial-collect-wave",
            &serde_json::json!({
                "applicable_classes": ["lint", "test"],
                "requests": [{
                    "evidence_id": "lint-core",
                    "unit_id": "core",
                    "evidence_class": "lint",
                    "selector": "true",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "true",
                        "args": [],
                        "format": "generic"
                    }
                }]
            }),
        ),
        "partial later collect omits sealed test request",
    );
    let second_ids: Vec<_> = second["records"]
        .as_array()
        .expect("second records")
        .iter()
        .map(|record| record["evidence_id"].as_str().expect("id").to_owned())
        .collect();
    assert!(
        !second_ids.iter().any(|id| id == "unrun-test-core"),
        "fabricated unrun-test-core contradicting sealed evidence: {second_ids:?}"
    );
    assert!(
        !second_ids.iter().any(|id| id == "unrun-test-extra"),
        "audit-wide unrun expansion outside call scope: {second_ids:?}"
    );
    assert!(
        second_ids.iter().any(|id| id == "lint-core"),
        "expected lint-core in second receipt: {second_ids:?}"
    );
    assert_eq!(
        fs::read(&sealed_path).expect("reread sealed record"),
        sealed_before,
        "sealed record bytes must stay immutable"
    );
    let inventory_after = evidence_inventory(&evidence_root);
    for id in &inventory_before {
        assert!(
            inventory_after.contains(id),
            "pre-existing evidence disappeared: {id}"
        );
    }
    assert!(
        !inventory_after.iter().any(|id| id == "unrun-test-core"),
        "unrun-test-core must not appear on disk"
    );
    assert!(
        !inventory_after.iter().any(|id| id == "unrun-test-extra"),
        "unrun-test-extra must not appear on disk"
    );
}

#[test]
fn scoped_missing_coverage_still_emits_unrun() {
    let fixture = initialized_multi_unit_fixture("missing-coverage-wave");
    let evidence_root = fixture
        .root
        .join(".git/northstar/rust-quality/audits/missing-coverage-wave/evidence");
    assert_success(
        &fixture.audit_operation(
            "collect",
            "missing-coverage-wave",
            &serde_json::json!({
                "applicable_classes": ["test"],
                "requests": [{
                    "evidence_id": "test-core",
                    "unit_id": "core",
                    "evidence_class": "test",
                    "selector": "true",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "true",
                        "args": [],
                        "format": "generic"
                    }
                }]
            }),
        ),
        "seal test/core",
    );
    let sealed_before = fs::read(evidence_root.join("test-core.json")).expect("sealed");
    let result = assert_success(
        &fixture.audit_operation(
            "collect",
            "missing-coverage-wave",
            &serde_json::json!({
                "applicable_classes": ["lint", "test"],
                "requests": [{
                    "evidence_id": "lint-extra",
                    "unit_id": "extra",
                    "evidence_class": "lint",
                    "selector": "true",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "true",
                        "args": [],
                        "format": "generic"
                    }
                }]
            }),
        ),
        "collect scoped missing test for extra",
    );
    let ids: Vec<_> = result["records"]
        .as_array()
        .expect("records")
        .iter()
        .map(|record| record["evidence_id"].as_str().expect("id").to_owned())
        .collect();
    assert!(ids.iter().any(|id| id == "lint-extra"), "{ids:?}");
    assert!(ids.iter().any(|id| id == "unrun-test-extra"), "{ids:?}");
    assert!(!ids.iter().any(|id| id == "unrun-test-core"), "{ids:?}");
    assert!(!ids.iter().any(|id| id == "unrun-lint-core"), "{ids:?}");
    assert_eq!(
        fs::read(evidence_root.join("test-core.json")).expect("reread"),
        sealed_before
    );
}

#[test]
fn colliding_unit_class_request_fails_before_write() {
    let fixture = initialized_multi_unit_fixture("collision-wave");
    let evidence_root = fixture
        .root
        .join(".git/northstar/rust-quality/audits/collision-wave/evidence");
    assert_success(
        &fixture.audit_operation(
            "collect",
            "collision-wave",
            &serde_json::json!({
                "applicable_classes": ["test"],
                "requests": [{
                    "evidence_id": "test-core",
                    "unit_id": "core",
                    "evidence_class": "test",
                    "selector": "true",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "true",
                        "args": [],
                        "format": "generic"
                    }
                }]
            }),
        ),
        "seal test/core",
    );
    let before = evidence_inventory(&evidence_root);
    let sealed_before = fs::read(evidence_root.join("test-core.json")).expect("sealed");
    let output = fixture.audit_operation(
        "collect",
        "collision-wave",
        &serde_json::json!({
            "applicable_classes": ["test"],
            "requests": [{
                "evidence_id": "test-core-again",
                "unit_id": "core",
                "evidence_class": "test",
                "selector": "true",
                "origin": "agent_resolved",
                "package_cwd": ".",
                "environment": "fixture",
                "execution": {
                    "kind": "command",
                    "program": "true",
                    "args": [],
                    "format": "generic"
                }
            }]
        }),
    );
    assert_lifecycle_error(&output, "evidence.coverage_exists");
    assert_eq!(evidence_inventory(&evidence_root), before);
    assert_eq!(
        fs::read(evidence_root.join("test-core.json")).expect("reread"),
        sealed_before
    );
}

#[test]
fn duplicate_unit_class_requests_fail_before_execution() {
    let fixture = initialized_multi_unit_fixture("duplicate-coverage-wave");
    let evidence_root = fixture
        .root
        .join(".git/northstar/rust-quality/audits/duplicate-coverage-wave/evidence");
    let marker = fixture.root.join("side-effect-marker");
    let output = fixture.audit_operation(
        "collect",
        "duplicate-coverage-wave",
        &serde_json::json!({
            "applicable_classes": ["test"],
            "requests": [
                {
                    "evidence_id": "test-core-a",
                    "unit_id": "core",
                    "evidence_class": "test",
                    "selector": "touch marker",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "touch",
                        "args": ["side-effect-marker"],
                        "format": "generic"
                    }
                },
                {
                    "evidence_id": "test-core-b",
                    "unit_id": "core",
                    "evidence_class": "test",
                    "selector": "touch marker again",
                    "origin": "agent_resolved",
                    "package_cwd": ".",
                    "environment": "fixture",
                    "execution": {
                        "kind": "command",
                        "program": "touch",
                        "args": ["side-effect-marker"],
                        "format": "generic"
                    }
                }
            ]
        }),
    );
    assert_lifecycle_error(&output, "evidence.coverage_duplicate");
    assert!(!evidence_root.exists() || evidence_inventory(&evidence_root).is_empty());
    assert!(!evidence_root.join("test-core-a.json").exists());
    assert!(!evidence_root.join("test-core-b.json").exists());
    assert!(
        !marker.exists(),
        "duplicate coverage must fail before command side effects"
    );
}

#[test]
fn records_compiler_source_failure_without_losing_raw_output() {
    let fixture = initialized_lifecycle_fixture("source-failure-wave", false);
    fixture.write("src/lib.rs", "pub fn broken( {\n");
    let result = assert_success(
        &fixture.audit_operation(
            "collect",
            "source-failure-wave",
            &serde_json::json!({
                "applicable_classes": ["compiler"],
                "requests": [{
                    "evidence_id": "compiler-failure",
                    "unit_id": "core",
                    "evidence_class": "compiler",
                    "selector": "cargo check",
                    "origin": "cargo_native",
                    "package_cwd": ".",
                    "environment": "fixture; Rust 1.95+",
                    "execution": {
                        "kind": "command",
                        "program": "cargo",
                        "args": ["check", "--message-format=json-diagnostic-rendered-ansi"],
                        "format": "cargo_json"
                    }
                }]
            }),
        ),
        "collect source failure",
    );
    let record = &result["records"][0];
    assert_eq!(record["status"], "failed");
    assert_eq!(record["failure_stage"], "source");
    assert_ne!(record["exit_status"], 0);
    assert_eq!(
        record["raw_artifacts"].as_array().expect("artifacts").len(),
        2
    );
}

#[test]
fn closes_out_nested_rust_with_compact_evidence_only() {
    let fixture = Fixture::new("nested-closeout");
    fixture.write("package.json", "{\"private\":true}\n");
    fixture.write(
        "packages/engine/Cargo.toml",
        "[package]\nname = \"engine\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write(
        "packages/engine/src/lib.rs",
        "pub fn answer() -> u8 { 41 }\n",
    );
    fixture.commit();
    fixture.write(
        "packages/engine/src/lib.rs",
        "pub fn answer() -> u8 { 42 }\n",
    );
    let result = assert_success(
        &fixture.closeout(&serde_json::json!({
            "applicable_rules": ["RUST-READ-001", "RUST-ERR-001"],
            "evidence_plan": {
                "applicable_classes": ["compiler"],
                "requests": [{
                    "evidence_id": "nested-check",
                    "evidence_class": "compiler",
                    "selector": "cargo check --manifest-path packages/engine/Cargo.toml",
                    "origin": "agent_resolved",
                    "package_cwd": "packages/engine",
                    "environment": "mixed repository; Rust 1.95+",
                    "execution": {
                        "kind": "command",
                        "program": "cargo",
                        "args": ["check", "--message-format=json-diagnostic-rendered-ansi"],
                        "format": "cargo_json"
                    }
                }]
            }
        })),
        "nested closeout",
    );
    assert_eq!(result["evidence"][0]["status"], "passed");
    assert_eq!(
        result["rust_anchors"],
        serde_json::json!(["packages/engine/src/lib.rs"])
    );
    assert!(result["evidence"][0].get("raw_artifacts").is_none());
    assert!(result.get("units").is_none());
    assert!(result.get("assessments").is_none());
}

fn committed_fixture(name: &str) -> (Fixture, String, String) {
    let fixture = Fixture::new(name);
    fixture.write("README.md", "fixture\n");
    fixture.write(
        "tools/engine/Cargo.toml",
        "[package]\nname = \"engine\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("tools/engine/src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    let base = fixture.rev("HEAD");
    fixture.write("tools/engine/src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    fixture.commit();
    let head = fixture.rev("HEAD");
    (fixture, base, head)
}

fn committed_plan() -> Value {
    serde_json::json!({
        "applicable_rules": ["RUST-READ-001", "RUST-ERR-001"],
        "evidence_plan": {
            "applicable_classes": ["compiler"],
            "requests": [{
                "evidence_id": "committed-check",
                "evidence_class": "compiler",
                "selector": "git rev-parse HEAD",
                "origin": "agent_resolved",
                "package_cwd": "tools/engine",
                "environment": "fixture checkout at the committed range head",
                "execution": {
                    "kind": "command",
                    "program": "git",
                    "args": ["rev-parse", "HEAD"]
                }
            }]
        }
    })
}

#[test]
fn records_committed_range_identity_and_direct_surface() {
    let (fixture, base, head) = committed_fixture("committed-inspect");
    let record = assert_success(&fixture.inspect_committed(&base, &head), "committed inspect");
    assert_eq!(record["scope"], "committed");
    assert_eq!(record["committed_range"]["base_commit"], base.as_str());
    assert_eq!(record["committed_range"]["head_commit"], head.as_str());
    assert_eq!(record["committed_range"]["checkout_commit"], head.as_str());
    assert_eq!(
        record["committed_range"]["changed_files"],
        serde_json::json!([{"path": "tools/engine/src/lib.rs", "status": "M"}])
    );
    assert_eq!(
        record["rust_anchors"],
        serde_json::json!([{"path": "tools/engine/src/lib.rs", "kind": "rust_source"}])
    );
    assert_eq!(
        record["committed_range"]["direct_surface"],
        serde_json::json!({"packages": ["engine"], "workspaces": ["tools/engine"]})
    );
    assert_eq!(record["dirty_files"], serde_json::json!([]));

    let planned = fixture.plan(
        &record,
        &serde_json::json!({
            "audit_id": "committed-audit",
            "units": [{"unit_id": "core", "anchors": ["tools/engine/src/lib.rs"]}],
            "excluded_dirty_files": [],
            "repository_coverage": null
        }),
    );
    assert_lifecycle_error(&planned, "scope.committed_audit_unsupported");

    let identity = record["committed_range"]["identity_sha256"]
        .as_str()
        .expect("identity");
    assert_eq!(identity.len(), 64);

    // The same exact range resolves to the same identity, and a different
    // range to a different one.
    let again = assert_success(&fixture.inspect_committed(&base, &head), "repeat inspect");
    assert_eq!(again["snapshot_sha256"], record["snapshot_sha256"]);
    assert_eq!(
        again["committed_range"]["identity_sha256"],
        record["committed_range"]["identity_sha256"]
    );
}

#[test]
fn rejects_committed_ranges_that_do_not_bind_exact_bytes() {
    let (fixture, base, head) = committed_fixture("committed-errors");

    assert_lifecycle_error(
        &fixture.inspect_committed("no-such-revision", &head),
        "scope.base_invalid",
    );
    assert_lifecycle_error(
        &fixture.inspect_committed(&base, "no-such-revision"),
        "scope.head_invalid",
    );

    // A base outside the head's ancestry is an unbounded range.
    fixture.git(&["checkout", "--quiet", "-b", "side"]);
    fixture.write("tools/engine/src/lib.rs", "pub fn answer() -> u8 { 7 }\n");
    fixture.commit();
    let side = fixture.rev("HEAD");
    fixture.git(&["checkout", "--quiet", "-"]);
    assert_lifecycle_error(
        &fixture.inspect_committed(&side, &head),
        "scope.range_unbounded",
    );

    assert_lifecycle_error(&fixture.inspect_committed(&head, &head), "scope.range_empty");

    // A commit that changes no path is still an empty range.
    fixture.git(&["commit", "--quiet", "--allow-empty", "-m", "empty"]);
    let empty = fixture.rev("HEAD");
    assert_lifecycle_error(&fixture.inspect_committed(&head, &empty), "scope.range_empty");

    // A non-Rust tranche has no anchor to close out.
    fixture.write("NOTES.md", "notes\n");
    fixture.commit();
    let docs = fixture.rev("HEAD");
    assert_lifecycle_error(
        &fixture.inspect_committed(&empty, &docs),
        "scope.no_committed_anchor",
    );

    // The checkout must be the range head.
    assert_lifecycle_error(
        &fixture.inspect_committed(&base, &empty),
        "scope.checkout_mismatch",
    );

    // A committed path dirty in the worktree no longer holds the committed bytes.
    fixture.write("tools/engine/src/lib.rs", "pub fn answer() -> u8 { 11 }\n");
    fixture.commit();
    let rust = fixture.rev("HEAD");
    fixture.write("tools/engine/src/lib.rs", "pub fn answer() -> u8 { 12 }\n");
    assert_lifecycle_error(
        &fixture.inspect_committed(&docs, &rust),
        "scope.checkout_dirty_range",
    );

    let missing = fixture.engine()
        .args(["inspect", "--repo"])
        .arg(&fixture.root)
        .args(["--scope", "committed"])
        .output()
        .expect("run committed inspect");
    assert_lifecycle_error(&missing, "scope.range_required");

    let unexpected = fixture.engine()
        .args(["inspect", "--repo"])
        .arg(&fixture.root)
        .args(["--scope", "worktree", "--base", &base, "--head", &head])
        .output()
        .expect("run worktree inspect");
    assert_lifecycle_error(&unexpected, "scope.range_unexpected");
}

#[test]
fn committed_closeout_binds_the_range_and_preserves_dirty_state() {
    let (fixture, base, head) = committed_fixture("committed-closeout");
    fixture.write("staged.txt", "staged\n");
    fixture.git(&["add", "staged.txt"]);
    fixture.write("README.md", "unstaged change\n");
    fixture.write("notes.txt", "untracked\n");
    let before = fixture.status();
    assert!(before.contains("A  staged.txt"), "staged: {before}");
    assert!(before.contains(" M README.md"), "unstaged: {before}");
    assert!(before.contains("?? notes.txt"), "untracked: {before}");

    let result = assert_success(
        &fixture.closeout_committed(&committed_plan(), &base, &head),
        "committed closeout",
    );
    assert_eq!(result["committed_range"]["base_commit"], base.as_str());
    assert_eq!(result["committed_range"]["head_commit"], head.as_str());
    assert_eq!(result["committed_range"]["checkout_commit"], head.as_str());
    assert_eq!(
        result["changed_files"],
        serde_json::json!(["tools/engine/src/lib.rs"])
    );
    assert_eq!(
        result["rust_anchors"],
        serde_json::json!(["tools/engine/src/lib.rs"])
    );
    assert_eq!(
        result["committed_range"]["preserved_dirty_files"],
        serde_json::json!(["README.md", "notes.txt", "staged.txt"])
    );
    assert_eq!(result["evidence"][0]["status"], "passed");
    assert!(result.get("reused_evidence").is_none());
    assert_eq!(result["attempt"], 1);
    assert_eq!(
        result["source_identity"],
        serde_json::json!(format!("committed:{base}:{head}"))
    );
    assert!(
        result["artifact_root"]
            .as_str()
            .expect("artifact root")
            .contains("committed-"),
        "committed evidence is stored under its own identity: {}",
        result["artifact_root"]
    );

    // Dirty user state survives the operation untouched and outside the tranche.
    assert_eq!(fixture.status(), before);
    assert_eq!(
        fs::read_to_string(fixture.root.join("notes.txt")).expect("untracked file"),
        "untracked\n"
    );
    assert_eq!(
        fs::read_to_string(fixture.root.join("README.md")).expect("unstaged file"),
        "unstaged change\n"
    );
}

#[test]
fn reuses_captured_committed_evidence_without_rerunning() {
    let (fixture, base, head) = committed_fixture("committed-reuse");
    let marker = fixture.root.join(".git/evidence-runs");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["execution"] = serde_json::json!({
        "kind": "command",
        "program": "sh",
        "args": ["-c", "printf 'run\\n' >> \"$1\"", "sh", marker.to_string_lossy()]
    });
    let first = assert_success(
        &fixture.closeout_committed(&plan, &base, &head),
        "first committed closeout",
    );
    assert_eq!(
        fs::read_to_string(fixture.root.join(".git/evidence-runs")).expect("run marker"),
        "run\n"
    );

    let second = assert_success(
        &fixture.closeout_committed(&plan, &base, &head),
        "second committed closeout",
    );
    assert_eq!(
        fs::read_to_string(fixture.root.join(".git/evidence-runs")).expect("run marker"),
        "run\n",
        "compatible captured validation is reused, not rerun"
    );
    assert_eq!(
        second["reused_evidence"],
        serde_json::json!(["committed-check"])
    );
    assert_eq!(second["evidence"], first["evidence"]);
    assert_eq!(second["artifact_root"], first["artifact_root"]);

    // A different request for the same class is not the captured validation.
    let mut changed = plan.clone();
    changed["evidence_plan"]["requests"][0]["selector"] =
        serde_json::json!("git status --porcelain");
    assert_lifecycle_error(
        &fixture.closeout_committed(&changed, &base, &head),
        "evidence.request_mismatch",
    );
}

#[test]
fn repeated_mixed_plan_keeps_sealed_unrun_limitations() {
    let (fixture, base, head) = committed_fixture("committed-mixed");
    let marker = fixture.root.join(".git/evidence-runs");
    let mut plan = committed_plan();
    plan["evidence_plan"]["applicable_classes"] = serde_json::json!(["compiler", "lint"]);
    plan["evidence_plan"]["requests"][0]["execution"] = serde_json::json!({
        "kind": "command",
        "program": "sh",
        "args": ["-c", "printf 'run\\n' >> \"$1\"", "sh", marker.to_string_lossy()]
    });

    let first = assert_success(
        &fixture.closeout_committed(&plan, &base, &head),
        "first mixed closeout",
    );
    assert_eq!(
        first["evidence"][0]["evidence_id"],
        "committed-check",
        "named request"
    );
    assert_eq!(first["evidence"][0]["status"], "passed");
    assert_eq!(
        first["evidence"][1]["evidence_id"],
        "unrun-lint",
        "unrequested applicable class stays an explicit limitation"
    );
    assert_eq!(first["evidence"][1]["status"], "unrun");
    let limitation = serde_json::json!([{
        "key": "evidence:unrun-lint",
        "kind": "evidence_unrun",
        "evidence": ["no selector was declared or resolved for lint"]
    }]);
    assert_eq!(first["limitations"], limitation);
    assert_eq!(
        fs::read_to_string(&marker).expect("run marker"),
        "run\n"
    );

    // The identical repeat reuses both sealed records and reports the same
    // tranche evidence, including the class that was never requested.
    let second = assert_success(
        &fixture.closeout_committed(&plan, &base, &head),
        "second mixed closeout",
    );
    assert_eq!(second["evidence"], first["evidence"]);
    assert_eq!(second["limitations"], first["limitations"]);
    assert_eq!(
        second["reused_evidence"],
        serde_json::json!(["committed-check", "unrun-lint"])
    );
    assert_eq!(
        fs::read_to_string(&marker).expect("run marker"),
        "run\n",
        "reuse never reruns the captured request"
    );
}

#[test]
fn rejects_evidence_captured_for_another_committed_range() {
    let (fixture, base, head) = committed_fixture("committed-stale");
    let first = assert_success(
        &fixture.closeout_committed(&committed_plan(), &base, &head),
        "first committed closeout",
    );

    fixture.write("tools/engine/src/extra.rs", "pub fn extra() -> u8 { 1 }\n");
    fixture.commit();
    let later = fixture.rev("HEAD");
    let second_record = assert_success(
        &fixture.inspect_committed(&head, &later),
        "inspect second range",
    );
    let identity = second_record["committed_range"]["identity_sha256"]
        .as_str()
        .expect("identity");

    let first_root = PathBuf::from(first["artifact_root"].as_str().expect("artifact root"));
    let closeouts = first_root
        .parent()
        .and_then(Path::parent)
        .expect("closeouts root")
        .to_path_buf();
    let planted = closeouts
        .join(format!("committed-{identity}"))
        .join("attempt-1")
        .join("evidence");
    fs::create_dir_all(planted.join("committed-check")).expect("create planted evidence root");
    fs::copy(
        first_root.join("evidence/committed-check.json"),
        planted.join("committed-check.json"),
    )
    .expect("plant mismatched evidence");
    for artifact in ["stdout.bin", "stderr.bin"] {
        fs::copy(
            first_root.join("evidence/committed-check").join(artifact),
            planted.join("committed-check").join(artifact),
        )
        .expect("plant evidence artifact");
    }

    assert_lifecycle_error(
        &fixture.closeout_committed(&committed_plan(), &head, &later),
        "evidence.source_mismatch",
    );
}

#[test]
fn worktree_closeout_binds_source_bytes_and_reuses_one_attempt() {
    let fixture = Fixture::new("worktree-once");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"worktree-once\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let marker = fixture.root.join(".git/worktree-runs");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    plan["evidence_plan"]["requests"][0]["execution"] = serde_json::json!({
        "kind": "command",
        "program": "sh",
        "args": ["-c", "printf 'run\\n' >> \"$1\"", "sh", marker.to_string_lossy()]
    });
    let result = assert_success(&fixture.closeout(&plan), "worktree closeout");
    assert!(result.get("committed_range").is_none());
    assert_eq!(result["attempt"], 1);
    let source_identity = result["source_identity"]
        .as_str()
        .expect("source identity");
    assert!(
        source_identity.starts_with("worktree:sha256:"),
        "source identity names the bytes: {source_identity}"
    );

    let artifact_root = PathBuf::from(result["artifact_root"].as_str().expect("artifact root"));
    assert!(
        artifact_root.ends_with("attempt-1"),
        "evidence lives in an attempt: {}",
        artifact_root.display()
    );
    let source_root = artifact_root.parent().expect("source root");
    assert!(
        source_root
            .file_name()
            .expect("source directory")
            .to_string_lossy()
            .starts_with("worktree-"),
        "evidence is stored under its content identity: {}",
        source_root.display()
    );

    let record: Value = serde_json::from_slice(
        &fs::read(artifact_root.join("evidence/committed-check.json"))
            .expect("read worktree record"),
    )
    .expect("parse worktree record");
    assert_eq!(record["source_identity"], source_identity);
    let request_sha256 = record["request_sha256"].as_str().expect("request digest");
    assert_eq!(request_sha256.len(), 64);
    assert_eq!(fs::read_to_string(&marker).expect("run marker"), "run\n");

    // An unchanged source and plan reuse the sealed attempt instead of rewriting it.
    let repeat = assert_success(&fixture.closeout(&plan), "repeat worktree closeout");
    assert_eq!(repeat["attempt"], 1);
    assert_eq!(repeat["artifact_root"], result["artifact_root"]);
    assert_eq!(repeat["evidence"], result["evidence"]);
    assert_eq!(
        repeat["reused_evidence"],
        serde_json::json!(["committed-check"])
    );
    assert_eq!(
        fs::read_to_string(&marker).expect("run marker"),
        "run\n",
        "reuse never reruns the sealed capture"
    );
}

#[test]
fn content_only_change_produces_a_distinct_source_identity() {
    let fixture = Fixture::new("content-identity");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"content-identity\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    let first = assert_success(&fixture.closeout(&plan), "first content closeout");
    let first_discovery = fixture.inspect();
    assert_eq!(
        first_discovery["dirty_files"],
        serde_json::json!([{"path": "src/lib.rs", "status": " M"}])
    );

    // Same path, same status, different bytes: a different source, not a repeat.
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 43 }\n");
    let second_discovery = fixture.inspect();
    assert_eq!(second_discovery["dirty_files"], first_discovery["dirty_files"]);
    assert_ne!(
        second_discovery["source_identity"],
        first_discovery["source_identity"]
    );
    assert_ne!(
        second_discovery["snapshot_sha256"],
        first_discovery["snapshot_sha256"]
    );
    let second = assert_success(&fixture.closeout(&plan), "second content closeout");
    assert_eq!(
        second["attempt"], 1,
        "a content-only change starts its own attempt history"
    );
    assert_ne!(second["artifact_root"], first["artifact_root"]);
    assert_eq!(
        second["source_identity"],
        second_discovery["source_identity"]
    );
}

#[test]
fn staged_and_working_bytes_bind_the_source_identity() {
    let fixture = Fixture::new("staged-bytes");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"staged-bytes\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    fixture.git(&["add", "src/lib.rs"]);
    let staged = fixture.inspect();
    assert_eq!(
        staged["dirty_files"],
        serde_json::json!([{"path": "src/lib.rs", "status": "M "}])
    );

    // Working bytes change while the staged bytes stay as they were.
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 43 }\n");
    let mixed = fixture.inspect();
    assert_eq!(
        mixed["dirty_files"],
        serde_json::json!([{"path": "src/lib.rs", "status": "MM"}])
    );
    assert_ne!(mixed["source_identity"], staged["source_identity"]);

    // Only the index changes: identical path and status, different content.
    fixture.git(&["add", "src/lib.rs"]);
    let restaged = fixture.inspect();
    assert_eq!(restaged["dirty_files"], staged["dirty_files"]);
    assert_ne!(
        restaged["source_identity"], staged["source_identity"],
        "content under identical path and status must separate sources"
    );
    assert_ne!(
        restaged["source_identity"], mixed["source_identity"],
        "the staged index state is part of the tranche"
    );
}

#[test]
fn untracked_and_deleted_paths_bind_the_source_identity() {
    let fixture = Fixture::new("deleted-bytes");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"deleted-bytes\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.write("src/extra.rs", "pub fn extra() -> u8 { 1 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let modified = fixture.inspect();

    // A deleted Rust anchor is part of the source, and reading it is not an error.
    fs::remove_file(fixture.root.join("src/extra.rs")).expect("delete anchor");
    let deleted = fixture.inspect();
    assert_eq!(
        deleted["dirty_files"],
        serde_json::json!([
            {"path": "src/extra.rs", "status": " D"},
            {"path": "src/lib.rs", "status": " M"}
        ])
    );
    assert_ne!(deleted["source_identity"], modified["source_identity"]);

    // Untracked bytes bind too.
    fixture.write("src/untracked.rs", "pub fn untracked() -> u8 { 1 }\n");
    let untracked = fixture.inspect();
    assert_ne!(untracked["source_identity"], deleted["source_identity"]);
    fixture.write("src/untracked.rs", "pub fn untracked() -> u8 { 2 }\n");
    let changed_untracked = fixture.inspect();
    assert_ne!(
        changed_untracked["source_identity"],
        untracked["source_identity"]
    );

    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    let result = assert_success(&fixture.closeout(&plan), "closeout with a deletion");
    assert_eq!(
        result["changed_files"],
        serde_json::json!(["src/extra.rs", "src/lib.rs", "src/untracked.rs"])
    );
    assert_eq!(result["evidence"][0]["status"], "passed");
    assert_eq!(
        result["source_identity"],
        changed_untracked["source_identity"]
    );
}

#[test]
fn retries_a_failed_capture_in_a_new_attempt() {
    let fixture = Fixture::new("retry-failed");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"retry-failed\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    plan["evidence_plan"]["requests"][0]["execution"] = serde_json::json!({
        "kind": "command",
        "program": "sh",
        "args": ["-c", "exit 9"]
    });

    let first = assert_success(&fixture.closeout(&plan), "failing closeout");
    assert_eq!(first["attempt"], 1);
    assert_eq!(first["evidence"][0]["status"], "failed");
    let first_root = PathBuf::from(first["artifact_root"].as_str().expect("artifact root"));
    let first_record =
        fs::read(first_root.join("evidence/committed-check.json")).expect("first record");

    // The same failed request is retried as a fresh attempt, never an overwrite.
    let second = assert_success(&fixture.closeout(&plan), "retried failing closeout");
    assert_eq!(second["attempt"], 2);
    assert_ne!(second["artifact_root"], first["artifact_root"]);
    assert_eq!(second["evidence"][0]["status"], "failed");
    assert_eq!(
        fs::read(first_root.join("evidence/committed-check.json")).expect("first record"),
        first_record,
        "earlier failure evidence is immutable"
    );

    // A corrected selector replaces a failed capture in a fresh attempt.
    plan["evidence_plan"]["requests"][0]["execution"] = serde_json::json!({
        "kind": "command",
        "program": "sh",
        "args": ["-c", "exit 0"]
    });
    let corrected = assert_success(&fixture.closeout(&plan), "corrected closeout");
    assert_eq!(corrected["attempt"], 3);
    assert_eq!(corrected["evidence"][0]["status"], "passed");

    // The passing capture stays authoritative and is reused, not replaced.
    let repeat = assert_success(&fixture.closeout(&plan), "repeat corrected closeout");
    assert_eq!(repeat["attempt"], 3);
    assert_eq!(
        repeat["reused_evidence"],
        serde_json::json!(["committed-check"])
    );
}

#[test]
fn retries_a_startup_failure_after_the_collector_is_corrected() {
    let fixture = Fixture::new("retry-startup");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"retry-startup\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let collector = fixture.root.join(".git/collector.sh");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    plan["evidence_plan"]["requests"][0]["execution"] = serde_json::json!({
        "kind": "command",
        "program": collector.to_string_lossy(),
        "args": []
    });
    let status_before = fixture.status();

    let first = assert_success(&fixture.closeout(&plan), "startup failure closeout");
    assert_eq!(first["attempt"], 1);
    assert_eq!(first["evidence"][0]["status"], "unavailable");
    let first_root = PathBuf::from(first["artifact_root"].as_str().expect("artifact root"));
    let record: Value = serde_json::from_slice(
        &fs::read(first_root.join("evidence/committed-check.json")).expect("startup record"),
    )
    .expect("parse startup record");
    assert_eq!(record["failure_stage"], "startup");

    // Correct only the collector. Source bytes and Git status stay identical.
    fs::write(&collector, "#!/bin/sh\nexit 0\n").expect("write collector");
    command(
        &fixture.root,
        "chmod",
        &["+x", collector.to_str().expect("collector path")],
    );
    assert_eq!(fixture.status(), status_before);

    let second = assert_success(&fixture.closeout(&plan), "retried startup closeout");
    assert_eq!(second["attempt"], 2);
    assert_eq!(second["source_identity"], first["source_identity"]);
    assert_eq!(second["evidence"][0]["status"], "passed");
}

#[test]
fn rejects_evidence_captured_for_another_source() {
    let fixture = Fixture::new("foreign-source");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"foreign-source\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    let first = assert_success(&fixture.closeout(&plan), "first source closeout");

    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 43 }\n");
    let second = assert_success(&fixture.closeout(&plan), "second source closeout");
    assert_ne!(second["source_identity"], first["source_identity"]);

    // Evidence from the other source cannot be read as this source's capture.
    let first_root = PathBuf::from(first["artifact_root"].as_str().expect("artifact root"));
    let second_root = PathBuf::from(second["artifact_root"].as_str().expect("artifact root"));
    fs::copy(
        first_root.join("evidence/committed-check.json"),
        second_root.join("evidence/committed-check.json"),
    )
    .expect("plant foreign evidence");
    for artifact in ["stdout.bin", "stderr.bin"] {
        fs::copy(
            first_root.join("evidence/committed-check").join(artifact),
            second_root.join("evidence/committed-check").join(artifact),
        )
        .expect("plant foreign artifact");
    }
    assert_lifecycle_error(&fixture.closeout(&plan), "evidence.source_mismatch");
}

#[test]
fn retries_a_collector_failure_after_the_plan_is_corrected() {
    let fixture = Fixture::new("retry-collector");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"retry-collector\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!("missing-directory");
    let status_before = fixture.status();
    assert_lifecycle_error(
        &fixture.closeout(&plan),
        "evidence.package_cwd_missing",
    );

    // Correct only the plan; the source bytes and Git status are unchanged.
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    assert_eq!(fixture.status(), status_before);
    let corrected = assert_success(&fixture.closeout(&plan), "corrected collector closeout");
    assert_eq!(corrected["attempt"], 2);
    assert_eq!(corrected["evidence"][0]["status"], "passed");
}

#[test]
fn rejects_a_tampered_attempt_history() {
    let fixture = Fixture::new("attempt-history");
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"attempt-history\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    let mut plan = committed_plan();
    plan["evidence_plan"]["requests"][0]["package_cwd"] = serde_json::json!(".");
    let first = assert_success(&fixture.closeout(&plan), "attempt history closeout");
    let artifact_root = PathBuf::from(first["artifact_root"].as_str().expect("artifact root"));
    let source_root = artifact_root.parent().expect("source root").to_path_buf();

    // An unexpected entry is not history to ignore.
    fs::write(source_root.join("stray.json"), "{}\n").expect("stray entry");
    assert_lifecycle_error(&fixture.closeout(&plan), "evidence.attempt_invalid");
    fs::remove_file(source_root.join("stray.json")).expect("remove stray entry");

    // Renaming an attempt hides evidence only if a gap were tolerated.
    fs::rename(source_root.join("attempt-1"), source_root.join("attempt-2"))
        .expect("rename attempt");
    assert_lifecycle_error(&fixture.closeout(&plan), "evidence.attempt_gap");
}

#[test]
fn rejects_hidden_mutation_and_changed_exclusions() {
    let hidden = initialized_lifecycle_fixture("hidden-wave", false);
    assert_success(
        &hidden.audit_operation("assess", "hidden-wave", &complete_assessment()),
        "assess hidden",
    );
    hidden.write("src/lib.rs", "pub fn answer() -> u8 { 99 }\n");
    assert_lifecycle_error(
        &hidden.audit_operation(
            "complete",
            "hidden-wave",
            &serde_json::json!({"unit_id": "core", "repairs": [], "evidence_ids": []}),
        ),
        "lifecycle.hidden_or_false_mutation",
    );

    let excluded = initialized_lifecycle_fixture("excluded-wave", true);
    assert_success(
        &excluded.audit_operation("assess", "excluded-wave", &complete_assessment()),
        "assess excluded",
    );
    excluded.write("README.md", "changed during audit\n");
    assert_lifecycle_error(
        &excluded.audit_operation(
            "complete",
            "excluded-wave",
            &serde_json::json!({"unit_id": "core", "repairs": [], "evidence_ids": []}),
        ),
        "lifecycle.read-only_file_changed",
    );
}

#[test]
fn finalization_rejects_incomplete_changed_and_repeated_records() {
    let incomplete = initialized_lifecycle_fixture("incomplete-wave", false);
    assert_lifecycle_error(
        &incomplete.finalize("incomplete-wave"),
        "lifecycle.unit_not_assessed",
    );

    let post_complete = initialized_lifecycle_fixture("post-complete-wave", false);
    complete_unchanged_unit(&post_complete, "post-complete-wave");
    post_complete.write("src/lib.rs", "pub fn answer() -> u8 { 100 }\n");
    assert_lifecycle_error(
        &post_complete.finalize("post-complete-wave"),
        "lifecycle.hidden_or_false_mutation",
    );

    let changed_policy = initialized_lifecycle_fixture("policy-wave", false);
    complete_unchanged_unit(&changed_policy, "policy-wave");
    changed_policy.write(
        ".git/northstar/rust-quality/audits/policy-wave/strict-audit.json",
        "{}\n",
    );
    assert_lifecycle_error(
        &changed_policy.finalize("policy-wave"),
        "lifecycle.policy_changed",
    );

    let repeated = initialized_lifecycle_fixture("repeated-wave", false);
    complete_unchanged_unit(&repeated, "repeated-wave");
    assert_success(&repeated.finalize("repeated-wave"), "first finalize");
    assert_lifecycle_error(
        &repeated.finalize("repeated-wave"),
        "lifecycle.already_finalized",
    );
}

#[test]
fn rejects_unaccepted_deviation_disposition() {
    let fixture = initialized_lifecycle_fixture("deviation-wave", false);
    assert_lifecycle_error(
        &fixture.audit_operation(
            "assess",
            "deviation-wave",
            &assessment_with_unaccepted_deviation(),
        ),
        "lifecycle.deviation_unaccepted",
    );
}

fn complete_assessment() -> Value {
    let projection: Value = serde_json::from_slice(
        &fs::read(strict_projection_path()).expect("read strict projection"),
    )
    .expect("parse strict projection");
    let verdicts: Vec<_> = projection["rules"]
        .as_array()
        .expect("rules")
        .iter()
        .filter(|rule| rule["maturity"] == "approved" && rule["enforcement"] != "evaluation_only")
        .map(|rule| {
            serde_json::json!({
                "rule_id": rule["id"],
                "verdict": "pass",
                "inspected_surfaces": ["src/lib.rs"],
                "evidence": ["Reviewed against the rule contract"]
            })
        })
        .collect();
    serde_json::json!({
        "unit_id": "core",
        "verdicts": verdicts,
        "attestations": [
            {"dimension": "correctness_assurance", "inspected_surfaces": ["src/lib.rs"], "evidence": ["Behavior checked"]},
            {"dimension": "architecture", "inspected_surfaces": ["src/lib.rs"], "evidence": ["Boundary checked"]},
            {"dimension": "human_quality", "inspected_surfaces": ["src/lib.rs"], "evidence": ["Naming and flow checked"]}
        ],
        "findings": [],
        "repair_plans": [],
        "limitations": []
    })
}

fn assessment_with_readability_repair() -> Value {
    let mut assessment = complete_assessment();
    let index = assessment["verdicts"]
        .as_array()
        .expect("verdicts")
        .iter()
        .position(|verdict| verdict["rule_id"] == "RUST-READ-001")
        .expect("readability verdict");
    assessment["verdicts"][index]["verdict"] = serde_json::json!("finding");
    assessment["verdicts"][index]["finding_ids"] = serde_json::json!(["readability-1"]);
    assessment["findings"] = serde_json::json!([{
        "finding_id": "readability-1",
        "rule_id": "RUST-READ-001",
        "action": "flatten_control_flow",
        "file": "src/lib.rs",
        "evidence": "Control flow obscures the invariant",
        "disposition": "repair_planned"
    }]);
    assessment["repair_plans"] = serde_json::json!([{
        "plan_id": "readability-repair",
        "finding_ids": ["readability-1"],
        "owned_files": ["src/lib.rs"],
        "preserved_behavior": ["Public return contract remains stable"]
    }]);
    assessment
}

fn assessment_with_unaccepted_deviation() -> Value {
    let mut assessment = complete_assessment();
    let index = assessment["verdicts"]
        .as_array()
        .expect("verdicts")
        .iter()
        .position(|verdict| verdict["rule_id"] == "RUST-READ-001")
        .expect("readability verdict");
    assessment["verdicts"][index]["verdict"] = serde_json::json!("finding");
    assessment["verdicts"][index]["finding_ids"] = serde_json::json!(["deviation-1"]);
    assessment["findings"] = serde_json::json!([{
        "finding_id": "deviation-1",
        "rule_id": "RUST-READ-001",
        "action": "retain_complex_flow",
        "file": "src/lib.rs",
        "evidence": "Repository contract requires the state-machine shape",
        "disposition": "deviation"
    }]);
    assessment
}

fn initialized_multi_unit_fixture(audit_id: &str) -> Fixture {
    let fixture = Fixture::new(audit_id);
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"partial-collect\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.write("src/extra.rs", "pub fn extra() -> u8 { 1 }\n");
    fixture.write("README.md", "baseline\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    fixture.write("src/extra.rs", "pub fn extra() -> u8 { 2 }\n");
    let discovery = fixture.inspect();
    let plan = fixture.plan_value(
        &discovery,
        &serde_json::json!({
            "audit_id": audit_id,
            "units": [
                {"unit_id": "core", "anchors": ["src/lib.rs"], "context": []},
                {"unit_id": "extra", "anchors": ["src/extra.rs"], "context": []}
            ],
            "excluded_dirty_files": [],
            "repository_coverage": null
        }),
    );
    assert_success(
        &fixture.init_audit(&discovery, &plan),
        "init multi-unit fixture",
    );
    fixture
}

fn evidence_inventory(evidence_root: &Path) -> Vec<String> {
    let mut ids = fs::read_dir(evidence_root)
        .expect("read evidence root")
        .filter_map(|entry| {
            let entry = entry.ok()?;
            let name = entry.file_name().into_string().ok()?;
            name.strip_suffix(".json").map(str::to_owned)
        })
        .collect::<Vec<_>>();
    ids.sort();
    ids
}

fn initialized_lifecycle_fixture(audit_id: &str, exclude_readme: bool) -> Fixture {
    let fixture = Fixture::new(audit_id);
    fixture.write(
        "Cargo.toml",
        "[package]\nname = \"lifecycle-negative\"\nversion = \"0.1.0\"\nedition = \"2024\"\nrust-version = \"1.95\"\n",
    );
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 41 }\n");
    fixture.write("README.md", "baseline\n");
    fixture.commit();
    fixture.write("src/lib.rs", "pub fn answer() -> u8 { 42 }\n");
    if exclude_readme {
        fixture.write("README.md", "dirty before audit\n");
    }
    let discovery = fixture.inspect();
    let exclusions = if exclude_readme {
        serde_json::json!([{"path": "README.md", "reason": "outside Rust repair scope"}])
    } else {
        serde_json::json!([])
    };
    let plan = fixture.plan_value(
        &discovery,
        &serde_json::json!({
            "audit_id": audit_id,
            "units": [{"unit_id": "core", "anchors": ["src/lib.rs"], "context": []}],
            "excluded_dirty_files": exclusions,
            "repository_coverage": null
        }),
    );
    assert_success(
        &fixture.init_audit(&discovery, &plan),
        "init negative fixture",
    );
    fixture
}

fn complete_unchanged_unit(fixture: &Fixture, audit_id: &str) {
    assert_success(
        &fixture.audit_operation("assess", audit_id, &complete_assessment()),
        "assess unchanged",
    );
    assert_success(
        &fixture.audit_operation(
            "collect",
            audit_id,
            &serde_json::json!({"applicable_classes": ["test"], "requests": []}),
        ),
        "record unavailable selector",
    );
    assert_success(
        &fixture.audit_operation(
            "complete",
            audit_id,
            &serde_json::json!({"unit_id": "core", "repairs": [], "evidence_ids": ["unrun-test-core"]}),
        ),
        "complete unchanged",
    );
}

fn strict_projection_path() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .join("../../references/language-quality/rust/strict-audit.json")
}

fn assert_ledger_error(output: &std::process::Output, expected: &str) {
    assert_eq!(output.status.code(), Some(2));
    assert!(
        String::from_utf8_lossy(&output.stderr).contains(expected),
        "expected {expected}, got {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

fn assert_lifecycle_error(output: &std::process::Output, expected: &str) {
    assert_eq!(output.status.code(), Some(2));
    assert!(
        String::from_utf8_lossy(&output.stderr).contains(expected),
        "expected {expected}, got {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

fn assert_success(output: &std::process::Output, operation: &str) -> Value {
    assert!(
        output.status.success(),
        "{operation} failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    serde_json::from_slice(&output.stdout).expect("parse successful operation")
}

fn command(directory: &Path, program: &str, arguments: &[&str]) {
    let output = Command::new(program)
        .current_dir(directory)
        .args(arguments)
        .output()
        .expect("start fixture command");
    assert!(
        output.status.success(),
        "{program} failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}
