use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::collections::{BTreeMap, BTreeSet};
use std::ffi::OsStr;
use std::fs;
use std::io::Read;
use std::path::{Path, PathBuf};
use std::process::Command;

mod evidence;
mod ledger;
mod lifecycle;
mod plan;

pub use evidence::{
    Closeout, CollectionReceipt, EvidenceBinding, EvidencePlan, closeout, closeout_committed,
    collect,
};

pub use ledger::{Assessment, AssessmentInput, StrictProjection, validate_assessment};
pub use lifecycle::{
    CompletionInput, ExtensionInput, assess_unit, collect_audit_evidence, complete_unit,
    extend_unit, finalize_audit, initialize_audit,
};
pub use plan::{ScopePlan, ScopePlanInput, build_scope_plan};

pub const SCHEMA_VERSION: &str = "northstar.rust-quality.discovery.v1";
pub const PAYLOAD_SHA256: &str = env!("NORTHSTAR_RUST_QUALITY_PAYLOAD_SHA256");

#[derive(Clone, Copy, Debug, Deserialize, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Scope {
    Worktree,
    Repository,
    /// An explicit committed range, resolved by `--base` and `--head`.
    Committed,
}

impl Scope {
    /// Parses a supported audit scope.
    ///
    /// # Errors
    ///
    /// Returns an error when `value` is not a supported scope name.
    pub fn parse(value: &str) -> Result<Self, String> {
        match value {
            "worktree" => Ok(Self::Worktree),
            "repository" => Ok(Self::Repository),
            "committed" => Ok(Self::Committed),
            _ => Err(format!("unsupported scope `{value}`")),
        }
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct DiscoveryRecord {
    pub schema_version: String,
    pub tool_version: String,
    pub repository_root: String,
    pub scope: Scope,
    pub cargo_version: String,
    /// Worktree files that are dirty and stay outside the assessed tranche.
    pub dirty_files: Vec<DirtyFile>,
    /// For committed scope the anchors of the committed range, never the
    /// worktree's dirty files.
    pub rust_anchors: Vec<RustAnchor>,
    pub workspaces: Vec<CargoWorkspace>,
    /// Digest of this discovery record's metadata, never of the source bytes.
    pub snapshot_sha256: String,
    /// Identity of the source bytes this discovery assessed: the content of
    /// every worktree dirty path, or the exact committed range. Absent for
    /// repository scope, whose audit manifest binds its own baseline.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub source_identity: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub committed_range: Option<CommittedRange>,
}

/// Exact committed tranche identity for an explicit `base..head` range.
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CommittedRange {
    pub base_commit: String,
    pub head_commit: String,
    pub checkout_commit: String,
    pub identity_sha256: String,
    pub changed_files: Vec<DirtyFile>,
    pub direct_surface: DirectSurface,
}

impl CommittedRange {
    /// Stable evidence binding for this exact range.
    #[must_use]
    pub fn source_identity(&self) -> String {
        format!("committed:{}:{}", self.base_commit, self.head_commit)
    }

    /// Paths of the committed tranche, excluding preserved dirty worktree state.
    #[must_use]
    pub fn changed_paths(&self) -> Vec<String> {
        self.changed_files
            .iter()
            .map(|file| file.path.clone())
            .collect()
    }
}

/// Rust packages and workspaces a committed tranche directly corrects.
#[derive(Clone, Debug, Default, Deserialize, Serialize)]
pub struct DirectSurface {
    pub packages: Vec<String>,
    pub workspaces: Vec<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct DirtyFile {
    pub path: String,
    pub status: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct RustAnchor {
    pub path: String,
    pub kind: String,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CargoWorkspace {
    pub root: String,
    pub manifest_path: String,
    pub packages: Vec<CargoPackage>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CargoPackage {
    pub name: String,
    pub manifest_path: String,
    pub rust_version: Option<String>,
    pub features: Vec<String>,
    pub targets: Vec<CargoTarget>,
}

#[derive(Debug, Deserialize, Serialize)]
pub struct CargoTarget {
    pub name: String,
    pub kinds: Vec<String>,
    pub source_path: String,
}

#[derive(Debug, Serialize)]
pub struct InstallReceipt {
    pub schema_version: &'static str,
    pub tool_version: &'static str,
    pub embedded_payload_sha256: &'static str,
    pub source_payload_sha256: String,
    pub source_root: String,
    pub binary_path: String,
    pub current: bool,
}

#[derive(Debug, Deserialize)]
struct Metadata {
    packages: Vec<MetadataPackage>,
    workspace_members: Vec<String>,
    workspace_root: String,
}

#[derive(Debug, Deserialize)]
struct MetadataPackage {
    id: String,
    name: String,
    manifest_path: String,
    rust_version: Option<String>,
    features: BTreeMap<String, Vec<String>>,
    targets: Vec<MetadataTarget>,
}

#[derive(Debug, Deserialize)]
struct MetadataTarget {
    name: String,
    kind: Vec<String>,
    src_path: String,
}

/// Discovers Git scope and Cargo workspaces beneath a repository root.
///
/// # Errors
///
/// Returns a structured error string when Git or Cargo cannot be inspected, a
/// worktree has no dirty Rust anchor, or no Cargo manifest is present.
pub fn inspect(repository: &Path, scope: Scope) -> Result<DiscoveryRecord, String> {
    let repository_root = git_root(repository)?;
    let dirty_files = git_status(&repository_root)?;
    let rust_anchors = anchors(&dirty_files);
    if scope == Scope::Worktree && rust_anchors.is_empty() {
        return Err("scope.no_worktree_anchor: no dirty Rust anchor found".to_owned());
    }

    let manifests = discover_manifests(&repository_root)?;
    if manifests.is_empty() {
        return Err("cargo.no_manifest: no Cargo.toml found beneath repository root".to_owned());
    }
    let workspaces = inspect_workspaces(&repository_root, &manifests)?;
    let cargo_version = command_text(Command::new(cargo()).arg("--version"), "cargo.version")?;
    let source_identity = if scope == Scope::Repository {
        None
    } else {
        Some(worktree_source_identity(&repository_root, &dirty_files)?)
    };

    let mut record = DiscoveryRecord {
        schema_version: SCHEMA_VERSION.to_owned(),
        tool_version: env!("CARGO_PKG_VERSION").to_owned(),
        repository_root: slash(&repository_root),
        scope,
        cargo_version,
        dirty_files,
        rust_anchors,
        workspaces,
        snapshot_sha256: String::new(),
        source_identity,
        committed_range: None,
    };
    let canonical = serde_json::to_vec(&record).map_err(|error| error.to_string())?;
    record.snapshot_sha256 = format!("{:x}", Sha256::digest(canonical));
    Ok(record)
}

/// Discovers an explicit committed range on a checkout of its exact head.
///
/// The checked-out commit must equal `head`, no committed path may be dirty,
/// and the range must be non-empty, bounded by an ancestor `base`, and carry
/// at least one Rust anchor. Dirty worktree state outside the range is
/// preserved and recorded, never absorbed into the tranche.
///
/// # Errors
///
/// Returns a structured `scope.*` or `cargo.*` error for an invalid revision,
/// an unbounded or empty range, a missing Rust anchor, a mismatched checkout,
/// a dirty range path, or a discovery failure.
pub fn inspect_range(
    repository: &Path,
    base: &str,
    head: &str,
) -> Result<DiscoveryRecord, String> {
    let repository_root = git_root(repository)?;
    let base_commit = resolve_commit(&repository_root, base, "scope.base_invalid")?;
    let head_commit = resolve_commit(&repository_root, head, "scope.head_invalid")?;
    if !is_ancestor(&repository_root, &base_commit, &head_commit)? {
        return Err(format!(
            "scope.range_unbounded: {base_commit} is not an ancestor of {head_commit}"
        ));
    }
    let checkout_commit = resolve_commit(&repository_root, "HEAD", "scope.checkout_missing")?;
    if checkout_commit != head_commit {
        return Err(format!(
            "scope.checkout_mismatch: checked out {checkout_commit}, range head is {head_commit}"
        ));
    }
    let changed_files = changed_files(&repository_root, &base_commit, &head_commit)?;
    if changed_files.is_empty() {
        return Err(format!(
            "scope.range_empty: {base_commit}..{head_commit} changes no path"
        ));
    }
    let rust_anchors = anchors(&changed_files);
    if rust_anchors.is_empty() {
        return Err(format!(
            "scope.no_committed_anchor: {base_commit}..{head_commit} changes no Rust anchor"
        ));
    }

    let dirty_files = git_status(&repository_root)?;
    let committed_paths: BTreeSet<&str> = changed_files
        .iter()
        .map(|file| file.path.as_str())
        .collect();
    let dirty_range: Vec<&str> = dirty_files
        .iter()
        .filter(|file| committed_paths.contains(file.path.as_str()))
        .map(|file| file.path.as_str())
        .collect();
    if !dirty_range.is_empty() {
        return Err(format!(
            "scope.checkout_dirty_range: committed paths are dirty in the worktree: {}",
            dirty_range.join(", ")
        ));
    }

    let manifests = discover_manifests(&repository_root)?;
    if manifests.is_empty() {
        return Err("cargo.no_manifest: no Cargo.toml found beneath repository root".to_owned());
    }
    let workspaces = inspect_workspaces(&repository_root, &manifests)?;
    let cargo_version = command_text(Command::new(cargo()).arg("--version"), "cargo.version")?;
    let direct_surface = direct_surface(&workspaces, &changed_files);
    let identity_sha256 = range_identity(&base_commit, &head_commit);
    let source_identity = format!("committed:{base_commit}:{head_commit}");

    let mut record = DiscoveryRecord {
        schema_version: SCHEMA_VERSION.to_owned(),
        tool_version: env!("CARGO_PKG_VERSION").to_owned(),
        repository_root: slash(&repository_root),
        scope: Scope::Committed,
        cargo_version,
        dirty_files,
        rust_anchors,
        workspaces,
        snapshot_sha256: String::new(),
        source_identity: Some(source_identity),
        committed_range: Some(CommittedRange {
            base_commit,
            head_commit,
            checkout_commit,
            identity_sha256,
            changed_files,
            direct_surface,
        }),
    };
    let canonical = serde_json::to_vec(&record).map_err(|error| error.to_string())?;
    record.snapshot_sha256 = format!("{:x}", Sha256::digest(canonical));
    Ok(record)
}

fn resolve_commit(
    repository_root: &Path,
    revision: &str,
    code: &str,
) -> Result<String, String> {
    let output = Command::new("git")
        .arg("-C")
        .arg(repository_root)
        .args(["rev-parse", "--verify", "--quiet"])
        .arg(format!("{revision}^{{commit}}"))
        .output()
        .map_err(|error| format!("{code}.startup: {error}"))?;
    if !output.status.success() {
        return Err(format!("{code}: `{revision}` is not a commit"));
    }
    let commit = String::from_utf8_lossy(&output.stdout).trim().to_owned();
    if commit.len() != 40 || !commit.bytes().all(|byte| byte.is_ascii_hexdigit()) {
        return Err(format!(
            "{code}: `{revision}` did not resolve to an exact commit"
        ));
    }
    Ok(commit)
}

fn is_ancestor(
    repository_root: &Path,
    ancestor: &str,
    descendant: &str,
) -> Result<bool, String> {
    let status = Command::new("git")
        .arg("-C")
        .arg(repository_root)
        .args(["merge-base", "--is-ancestor"])
        .arg(ancestor)
        .arg(descendant)
        .status()
        .map_err(|error| format!("scope.range_check.startup: {error}"))?;
    match status.code() {
        Some(0) => Ok(true),
        Some(1) => Ok(false),
        _ => Err("scope.range_check_failed: git merge-base did not answer".to_owned()),
    }
}

fn changed_files(
    repository_root: &Path,
    base_commit: &str,
    head_commit: &str,
) -> Result<Vec<DirtyFile>, String> {
    let output = Command::new("git")
        .arg("-C")
        .arg(repository_root)
        .args(["diff", "--name-status", "--no-renames", "-z"])
        .arg(base_commit)
        .arg(head_commit)
        .output()
        .map_err(|error| format!("scope.range_diff.startup: {error}"))?;
    if !output.status.success() {
        return Err(format!(
            "scope.range_diff.failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }
    let fields: Vec<&[u8]> = output
        .stdout
        .split(|byte| *byte == 0)
        .filter(|field| !field.is_empty())
        .collect();
    let mut changed = Vec::new();
    for pair in fields.chunks(2) {
        let [status, path] = pair else {
            return Err("scope.range_diff.parse: truncated record".to_owned());
        };
        changed.push(DirtyFile {
            path: String::from_utf8_lossy(path).into_owned(),
            status: String::from_utf8_lossy(status).into_owned(),
        });
    }
    changed.sort_by(|left, right| left.path.cmp(&right.path));
    Ok(changed)
}

/// Content identity of a dirty worktree tranche.
///
/// The identity covers every dirty path exactly as Git reports it (deleted,
/// staged and untracked included) together with the bytes a collector reads
/// from the worktree. Two tranches with identical paths and statuses but
/// different content therefore never share an identity, and neither do a
/// staged byte set and the working bytes that replaced it.
fn worktree_source_identity(
    repository_root: &Path,
    dirty_files: &[DirtyFile],
) -> Result<String, String> {
    let mut digest = Sha256::new();
    digest.update(b"northstar.rust-quality.worktree-source.v1\n");
    for file in dirty_files {
        frame(&mut digest, file.path.as_bytes());
        frame(&mut digest, file.status.as_bytes());
        frame(
            &mut digest,
            worktree_content_digest(repository_root, &file.path)?.as_bytes(),
        );
    }
    Ok(format!("worktree:sha256:{:x}", digest.finalize()))
}

/// Digests the bytes a collector reads for one dirty path.
///
/// A path absent from the worktree is a deletion, not a read failure. A
/// directory is a submodule or similar Git-carried entry. Everything else is
/// the working file content, symlink target included.
fn worktree_content_digest(repository_root: &Path, path: &str) -> Result<String, String> {
    let full = repository_root.join(path);
    let metadata = match fs::symlink_metadata(&full) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {
            return Ok("deleted".to_owned());
        }
        Err(error) => return Err(format!("scope.source_content {path}: {error}")),
    };
    if metadata.file_type().is_symlink() {
        let target = fs::read_link(&full)
            .map_err(|error| format!("scope.source_content {path}: {error}"))?;
        return Ok(format!("symlink:{:x}", Sha256::digest(slash(&target).as_bytes())));
    }
    if metadata.is_dir() {
        return Ok("directory".to_owned());
    }
    let mut file =
        fs::File::open(&full).map_err(|error| format!("scope.source_content {path}: {error}"))?;
    let mut content = Sha256::new();
    let mut buffer = vec![0_u8; 64 * 1024];
    loop {
        let read = file
            .read(&mut buffer)
            .map_err(|error| format!("scope.source_content {path}: {error}"))?;
        if read == 0 {
            break;
        }
        content.update(&buffer[..read]);
    }
    Ok(format!("file:{:x}", content.finalize()))
}

fn frame(digest: &mut Sha256, bytes: &[u8]) {
    digest.update((bytes.len() as u64).to_le_bytes());
    digest.update(bytes);
}

fn range_identity(base_commit: &str, head_commit: &str) -> String {
    format!(
        "{:x}",
        Sha256::digest(format!(
            "northstar.rust-quality.committed-range.v1\n{base_commit}\n{head_commit}"
        ))
    )
}

fn direct_surface(workspaces: &[CargoWorkspace], changed: &[DirtyFile]) -> DirectSurface {
    let paths: BTreeSet<&str> = changed.iter().map(|file| file.path.as_str()).collect();
    let mut packages = BTreeSet::new();
    let mut roots = BTreeSet::new();
    for workspace in workspaces {
        if paths.contains(workspace.manifest_path.as_str()) {
            roots.insert(workspace.root.clone());
        }
        for package in &workspace.packages {
            let mut affected = paths.contains(package.manifest_path.as_str());
            for target in &package.targets {
                if paths.contains(target.source_path.as_str()) {
                    affected = true;
                }
                if let Some(directory) = Path::new(&target.source_path).parent() {
                    let prefix = format!("{}/", slash(directory));
                    affected |= paths.iter().any(|path| path.starts_with(&prefix));
                }
            }
            if affected {
                packages.insert(package.name.clone());
                roots.insert(workspace.root.clone());
            }
        }
    }
    DirectSurface {
        packages: packages.into_iter().collect(),
        workspaces: roots.into_iter().collect(),
    }
}

/// Compares the binary's embedded payload hash with a skill source tree.
///
/// # Errors
///
/// Returns an error when the payload cannot be enumerated or read.
pub fn install_receipt(source_root: &Path) -> Result<InstallReceipt, String> {
    let source_root =
        fs::canonicalize(source_root).map_err(|error| format!("install.source_root: {error}"))?;
    let source_payload_sha256 = source_payload_digest(&source_root)?;
    let binary_path =
        std::env::current_exe().map_err(|error| format!("install.binary: {error}"))?;
    Ok(InstallReceipt {
        schema_version: "northstar.rust-quality.install.v1",
        tool_version: env!("CARGO_PKG_VERSION"),
        embedded_payload_sha256: PAYLOAD_SHA256,
        current: source_payload_sha256 == PAYLOAD_SHA256,
        source_payload_sha256,
        source_root: slash(&source_root),
        binary_path: slash(&binary_path),
    })
}

fn cargo() -> String {
    std::env::var("CARGO").unwrap_or_else(|_| "cargo".to_owned())
}

fn git_root(repository: &Path) -> Result<PathBuf, String> {
    let output = command_text(
        Command::new("git")
            .arg("-C")
            .arg(repository)
            .args(["rev-parse", "--show-toplevel"]),
        "git.root",
    )?;
    fs::canonicalize(output).map_err(|error| format!("git.root: {error}"))
}

fn git_status(repository_root: &Path) -> Result<Vec<DirtyFile>, String> {
    let output = Command::new("git")
        .arg("-C")
        .arg(repository_root)
        .args(["status", "--porcelain=v1", "-z", "--untracked-files=all"])
        .output()
        .map_err(|error| format!("git.status.startup: {error}"))?;
    if !output.status.success() {
        return Err(format!(
            "git.status.failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }

    let fields = output
        .stdout
        .split(|byte| *byte == 0)
        .filter(|field| !field.is_empty());
    let mut dirty = Vec::new();
    let mut skip_rename_source = false;
    for field in fields {
        if skip_rename_source {
            skip_rename_source = false;
            continue;
        }
        if field.len() < 4 || field[2] != b' ' {
            return Err("git.status.parse: invalid porcelain record".to_owned());
        }
        let status = String::from_utf8_lossy(&field[..2]).into_owned();
        let path = String::from_utf8_lossy(&field[3..]).into_owned();
        skip_rename_source = status.contains('R') || status.contains('C');
        dirty.push(DirtyFile { path, status });
    }
    dirty.sort_by(|left, right| left.path.cmp(&right.path));
    Ok(dirty)
}

fn anchors(dirty_files: &[DirtyFile]) -> Vec<RustAnchor> {
    dirty_files
        .iter()
        .filter_map(|file| {
            anchor_kind(Path::new(&file.path)).map(|kind| RustAnchor {
                path: file.path.clone(),
                kind: kind.to_owned(),
            })
        })
        .collect()
}

fn anchor_kind(path: &Path) -> Option<&'static str> {
    let name = path.file_name()?.to_str()?;
    if path.extension() == Some(OsStr::new("rs")) {
        return Some("rust_source");
    }
    match name {
        "Cargo.toml" => Some("cargo_manifest"),
        "Cargo.lock" => Some("cargo_lock"),
        "rust-toolchain" | "rust-toolchain.toml" => Some("rust_toolchain"),
        "rustfmt.toml" | ".rustfmt.toml" => Some("rustfmt_configuration"),
        "clippy.toml" | ".clippy.toml" => Some("clippy_configuration"),
        "config" | "config.toml"
            if path.parent().and_then(Path::file_name) == Some(OsStr::new(".cargo")) =>
        {
            Some("cargo_configuration")
        }
        _ => None,
    }
}

fn discover_manifests(repository_root: &Path) -> Result<Vec<PathBuf>, String> {
    let mut manifests = Vec::new();
    let mut pending = vec![repository_root.to_path_buf()];
    while let Some(directory) = pending.pop() {
        let mut entries = fs::read_dir(&directory)
            .map_err(|error| format!("cargo.scan {}: {error}", directory.display()))?
            .collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("cargo.scan {}: {error}", directory.display()))?;
        entries.sort_by_key(std::fs::DirEntry::file_name);
        for entry in entries.into_iter().rev() {
            let path = entry.path();
            let file_type = entry
                .file_type()
                .map_err(|error| format!("cargo.scan {}: {error}", path.display()))?;
            if file_type.is_symlink() {
                continue;
            }
            if file_type.is_dir() {
                if !ignored_directory(&entry.file_name()) {
                    pending.push(path);
                }
            } else if entry.file_name() == OsStr::new("Cargo.toml") {
                manifests.push(path);
            }
        }
    }
    manifests.sort();
    Ok(manifests)
}

fn source_payload_digest(root: &Path) -> Result<String, String> {
    let mut files = vec![
        root.join("Cargo.lock"),
        root.join("Cargo.toml"),
        root.join("build.rs"),
        root.join("assets/diagnostic-mapping.json"),
    ];
    collect_rust_sources(&root.join("src"), &mut files)?;
    files.sort();

    let mut digest = Sha256::new();
    for file in files {
        let relative = file
            .strip_prefix(root)
            .map_err(|error| format!("install.payload_path: {error}"))?;
        let relative = slash(relative);
        let contents = fs::read(&file)
            .map_err(|error| format!("install.payload_read {}: {error}", file.display()))?;
        digest.update(relative.len().to_le_bytes());
        digest.update(relative.as_bytes());
        digest.update(contents.len().to_le_bytes());
        digest.update(contents);
    }
    Ok(format!("{:x}", digest.finalize()))
}

fn collect_rust_sources(directory: &Path, files: &mut Vec<PathBuf>) -> Result<(), String> {
    let mut entries = fs::read_dir(directory)
        .map_err(|error| format!("install.payload_scan {}: {error}", directory.display()))?
        .collect::<Result<Vec<_>, _>>()
        .map_err(|error| format!("install.payload_scan {}: {error}", directory.display()))?;
    entries.sort_by_key(std::fs::DirEntry::file_name);
    for entry in entries {
        let path = entry.path();
        let file_type = entry
            .file_type()
            .map_err(|error| format!("install.payload_scan {}: {error}", path.display()))?;
        if file_type.is_dir() {
            collect_rust_sources(&path, files)?;
        } else if path.extension() == Some(OsStr::new("rs")) {
            files.push(path);
        }
    }
    Ok(())
}

fn ignored_directory(name: &OsStr) -> bool {
    matches!(
        name.to_str(),
        Some(".git" | ".effigy" | "node_modules" | "target")
    )
}

/// Recognizes Cargo's own no-workspace-root inheritance failure.
///
/// A manifest that inherits `version`, `edition`, `lints`, dependencies or
/// another field from a workspace root, while Cargo finds no workspace root for
/// it, is not an independently buildable workspace. That is the shape of an
/// unowned template (built only after being copied into a generated workspace)
/// and of a tree the consumer excluded from its workspace. Both stay out of
/// discovery instead of failing it.
///
/// Real workspace damage keeps failing discovery: a member whose inheritance
/// names a field the root does not define reports that field as undefined, and
/// a member Cargo cannot load reports a manifest or member error. Neither
/// carries the "failed to find a workspace root" cause matched here, so only
/// this exact class is skipped.
fn inherits_without_workspace_root(stderr: &str) -> bool {
    stderr.contains("error inheriting ")
        && stderr.contains("from workspace root manifest's `workspace.")
        && stderr.contains("failed to find a workspace root")
}

/// Recognizes Cargo refusing a manifest that its enclosing workspace does not
/// own, when that enclosing workspace did resolve.
///
/// Cargo's membership answer is the evidence: the resolved workspace's member
/// list is complete, and the failing manifest is neither a member nor
/// excluded, so it is not independently buildable in place. Adding it to the
/// workspace changes resolved features and is not a discovery repair, so it
/// stays out of the inventory. This is the shape of a template that the
/// consumer rebuilds inside a generated private workspace (Longhorn's
/// `examples/greenfield-compositions` does exactly that) and of any other
/// unowned tree beneath a workspace root.
///
/// A real member's damage still fails: the enclosing workspace's own
/// `cargo metadata` call fails and reports it, independently of this manifest.
fn unowned_by_resolved_workspace(manifest: &Path, stderr: &str, roots: &[PathBuf]) -> bool {
    if !stderr.contains("current package believes it's in a workspace when it's not") {
        return false;
    }
    roots.iter().any(|root| manifest.starts_with(root))
}

fn inspect_workspaces(
    repository_root: &Path,
    manifests: &[PathBuf],
) -> Result<Vec<CargoWorkspace>, String> {
    let mut by_root = BTreeMap::new();
    let mut failures = Vec::new();
    for manifest in manifests {
        let output = Command::new(cargo())
            .current_dir(repository_root)
            .args([
                "metadata",
                "--format-version",
                "1",
                "--no-deps",
                "--manifest-path",
            ])
            .arg(manifest)
            .output()
            .map_err(|error| format!("cargo.metadata.startup {}: {error}", manifest.display()))?;
        if !output.status.success() {
            failures.push((
                manifest.clone(),
                String::from_utf8_lossy(&output.stderr).into_owned(),
            ));
            continue;
        }
        let metadata: Metadata = serde_json::from_slice(&output.stdout)
            .map_err(|error| format!("cargo.metadata.parse {}: {error}", manifest.display()))?;
        by_root
            .entry(metadata.workspace_root.clone())
            .or_insert(metadata);
    }

    let roots: Vec<PathBuf> = by_root.keys().map(PathBuf::from).collect();
    for (manifest, stderr) in failures {
        if inherits_without_workspace_root(&stderr)
            || unowned_by_resolved_workspace(&manifest, &stderr, &roots)
        {
            continue;
        }
        return Err(format!(
            "cargo.metadata.failed {}: {}",
            manifest.display(),
            stderr.trim()
        ));
    }

    by_root
        .into_values()
        .map(|metadata| workspace_from_metadata(repository_root, metadata))
        .collect()
}

fn workspace_from_metadata(
    repository_root: &Path,
    metadata: Metadata,
) -> Result<CargoWorkspace, String> {
    let members: BTreeSet<_> = metadata.workspace_members.into_iter().collect();
    let mut packages = metadata
        .packages
        .into_iter()
        .filter(|package| members.contains(&package.id))
        .map(|package| {
            Ok(CargoPackage {
                name: package.name,
                manifest_path: repository_relative(
                    repository_root,
                    Path::new(&package.manifest_path),
                )?,
                rust_version: package.rust_version,
                features: package.features.into_keys().collect(),
                targets: package
                    .targets
                    .into_iter()
                    .map(|target| {
                        Ok(CargoTarget {
                            name: target.name,
                            kinds: target.kind,
                            source_path: repository_relative(
                                repository_root,
                                Path::new(&target.src_path),
                            )?,
                        })
                    })
                    .collect::<Result<Vec<_>, String>>()?,
            })
        })
        .collect::<Result<Vec<_>, String>>()?;
    packages.sort_by(|left, right| left.manifest_path.cmp(&right.manifest_path));
    let root = PathBuf::from(metadata.workspace_root);
    Ok(CargoWorkspace {
        manifest_path: repository_relative(repository_root, &root.join("Cargo.toml"))?,
        root: repository_relative(repository_root, &root)?,
        packages,
    })
}

fn command_text(command: &mut Command, code: &str) -> Result<String, String> {
    let output = command
        .output()
        .map_err(|error| format!("{code}.startup: {error}"))?;
    if !output.status.success() {
        return Err(format!(
            "{code}.failed: {}",
            String::from_utf8_lossy(&output.stderr).trim()
        ));
    }
    Ok(String::from_utf8_lossy(&output.stdout).trim().to_owned())
}

fn slash(path: &Path) -> String {
    path.to_string_lossy().replace('\\', "/")
}

fn repository_relative(repository_root: &Path, path: &Path) -> Result<String, String> {
    let relative = path.strip_prefix(repository_root).map_err(|_| {
        format!(
            "cargo.path_outside_repository: {} is outside {}",
            path.display(),
            repository_root.display()
        )
    })?;
    let value = slash(relative);
    Ok(if value.is_empty() {
        ".".to_owned()
    } else {
        value
    })
}
