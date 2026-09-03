fn require(condition, message) {
    if !condition {
        throw(message);
    }
}

fn require_key(value, key, context) {
    require(type_of(value) == "map", context + " must be an object");
    require(value.contains(key), context + " missing " + key);
}

fn require_array(value, context) {
    require(type_of(value) == "array", context + " must be an array");
}

fn find_rule(catalogue, rule_id) {
    for rule in catalogue["rules"] {
        if rule["id"] == rule_id {
            return rule;
        }
    }
    throw("missing required rule: " + rule_id);
}

fn replace_rule(catalogue, replacement) {
    for index in 0..catalogue["rules"].len() {
        if catalogue["rules"][index]["id"] == replacement["id"] {
            catalogue["rules"][index] = replacement;
            return catalogue;
        }
    }
    throw("cannot replace unknown rule: " + replacement["id"]);
}

fn validate_provenance(rule_id, provenance) {
    require_array(provenance, rule_id + " provenance");
    require(provenance.len() > 0, rule_id + " requires provenance");
    for source in provenance {
        for key in ["authority", "maturity", "revision", "url", "upstream_rules"] {
            require_key(source, key, rule_id + " provenance");
        }
        require(source["authority"].len() > 0, rule_id + " has empty provenance authority");
        require(source["revision"].len() > 0, rule_id + " has unpinned provenance");
        require(str::starts_with(source["url"], "https://"), rule_id + " has non-HTTPS provenance");
        require_array(source["upstream_rules"], rule_id + " upstream rules");
    }
}

fn validate_rule(rule, expected_id, expected_overlay, expected_enforcement) {
    for key in [
        "id", "title", "category", "overlay", "maturity", "decidability",
        "dimensions", "applicability", "strict_enforcement", "requirement",
        "rationale", "provenance", "audit_procedure", "mechanical_enforcement",
        "remediation", "deviation", "completion_evidence",
    ] {
        require_key(rule, key, expected_id);
    }
    require(!rule.contains("authoring") && !rule.contains("authoring_projection") &&
        !rule.contains("enforcement_by_profile") && !rule.contains("modelled_profiles"),
        expected_id + " exposes an unavailable everyday or profile surface");
    require(rule["id"] == expected_id, "catalogue rule order or inventory drifted at " + expected_id);
    require(rule["overlay"] == expected_overlay, expected_id + " overlay drifted");
    require(rule["strict_enforcement"] == expected_enforcement, expected_id + " strict enforcement drifted");
    require(rule["title"].len() > 0 && rule["requirement"].len() > 0 &&
        rule["rationale"].len() > 0, expected_id + " has empty normative content");
    require_array(rule["dimensions"], expected_id + " dimensions");
    require(rule["dimensions"].len() > 0, expected_id + " requires dimensions");
    require_array(rule["audit_procedure"], expected_id + " audit procedure");
    require(rule["audit_procedure"].len() > 0, expected_id + " requires an audit procedure");
    require_array(rule["mechanical_enforcement"], expected_id + " mechanical enforcement");
    require_array(rule["completion_evidence"], expected_id + " completion evidence");
    require(rule["completion_evidence"].len() > 0, expected_id + " requires completion evidence");
    validate_provenance(expected_id, rule["provenance"]);

    let remediation = rule["remediation"];
    for key in ["default_authority", "action_overrides", "guidance"] {
        require_key(remediation, key, expected_id + " remediation");
    }
    require(remediation["default_authority"] == "review_required" ||
        remediation["default_authority"] == "report_only" ||
        remediation["default_authority"] == "operator_decision",
        expected_id + " has invalid remediation authority");
    require_array(remediation["action_overrides"], expected_id + " action overrides");
    for action_override in remediation["action_overrides"] {
        for key in ["action", "authority", "reason"] {
            require_key(action_override, key, expected_id + " action override");
        }
        require(action_override["authority"] == "review_required" ||
            action_override["authority"] == "report_only" ||
            action_override["authority"] == "operator_decision",
            expected_id + " has invalid action authority");
    }
}

fn validate_catalogue(catalogue) {
    for key in ["schema_version", "language", "workflow", "production_profiles", "supported_overlays", "rules"] {
        require_key(catalogue, key, "catalogue");
    }
    require(!catalogue.contains("modelled_profiles") && !catalogue.contains("authoring"),
        "catalogue exposes an unavailable everyday surface");
    require(catalogue["schema_version"] == "1.0.0", "unsupported catalogue schema version");
    require(catalogue["language"] == "typescript", "catalogue language must be typescript");
    require(catalogue["workflow"] == "explicit_audit_repair", "catalogue must remain explicit-audit-only");
    require(catalogue["production_profiles"] == ["strict"], "strict must be the only production profile");
    require(catalogue["supported_overlays"] == ["base", "svelte", "sveltekit"], "supported overlays drifted");
    require_array(catalogue["rules"], "catalogue rules");
    require(catalogue["rules"].len() == 10, "catalogue must contain exactly ten rules");

    let expected_ids = [
        "TS-READ-001", "TS-EVIDENCE-001", "TS-BOUNDARY-001", "TS-ASYNC-001",
        "TS-ERR-001", "TS-ARCH-001", "SVELTE-REACT-001", "SVELTE-A11Y-001",
        "SVELTE-SSR-001", "TS-SLOP-001",
    ];
    let expected_overlays = [
        "base", "base", "base", "base", "base", "base", "svelte", "svelte",
        "sveltekit", "base",
    ];
    let expected_enforcement = [
        "required", "mandatory", "mandatory", "mandatory", "required", "required",
        "required", "mandatory", "mandatory", "evaluation_only",
    ];
    for index in 0..expected_ids.len() {
        validate_rule(
            catalogue["rules"][index],
            expected_ids[index],
            expected_overlays[index],
            expected_enforcement[index],
        );
    }

    for deferred_id in ["TS-TOOLCHAIN-001", "TS-TEST-001", "SVELTE-TEST-001"] {
        for rule in catalogue["rules"] {
            require(rule["id"] != deferred_id, "deferred rule entered production: " + deferred_id);
        }
    }

    let normative = 0;
    for rule in catalogue["rules"] {
        if rule["strict_enforcement"] != "evaluation_only" {
            normative += 1;
            require(rule["maturity"] == "approved", "normative rule is not approved: " + rule["id"]);
            require(rule["remediation"]["default_authority"] == "review_required",
                "normative repair must remain review-required: " + rule["id"]);
        }
    }
    require(normative == 9, "catalogue must contain exactly nine normative rules");

    let slop = find_rule(catalogue, "TS-SLOP-001");
    require(slop["maturity"] == "experimental", "slop signal must remain experimental");
    require(slop["strict_enforcement"] == "evaluation_only", "slop signal must remain evaluation-only");
    require(slop["remediation"]["default_authority"] == "report_only", "slop signal must remain report-only");
    require(slop["audit_procedure"].len() >= 4 &&
        slop["audit_procedure"][2].contains("independently under a named normative rule") &&
        slop["audit_procedure"][3].contains("Never fail the audit"),
        "slop signal lacks independent-rule and non-failing boundaries");

    let error_rule = find_rule(catalogue, "TS-ERR-001");
    require(error_rule["remediation"]["action_overrides"].len() == 1 &&
        error_rule["remediation"]["action_overrides"][0]["action"] == "change_error_contract" &&
        error_rule["remediation"]["action_overrides"][0]["authority"] == "operator_decision",
        "public error-contract mutation must require operator decision");
    let architecture_rule = find_rule(catalogue, "TS-ARCH-001");
    require(architecture_rule["remediation"]["action_overrides"].len() == 1 &&
        architecture_rule["remediation"]["action_overrides"][0]["authority"] == "operator_decision",
        "public package-contract mutation must require operator decision");
    let ssr_rule = find_rule(catalogue, "SVELTE-SSR-001");
    require(ssr_rule["remediation"]["action_overrides"].len() == 1 &&
        ssr_rule["remediation"]["action_overrides"][0]["authority"] == "operator_decision",
        "request or serialization contract mutation must require operator decision");
}

fn project_rule(rule) {
    let projected = #{};
    for key in [
        "id", "title", "overlay", "maturity", "dimensions", "applicability",
        "requirement", "rationale", "audit_procedure", "mechanical_enforcement",
        "remediation", "deviation", "completion_evidence",
    ] {
        projected[key] = rule[key];
    }
    projected["enforcement"] = rule["strict_enforcement"];
    projected
}

fn project_catalogue(catalogue) {
    let rules = [];
    for rule in catalogue["rules"] {
        rules.push(project_rule(rule));
    }
    let projection = #{};
    projection["schema_version"] = catalogue["schema_version"];
    projection["language"] = catalogue["language"];
    projection["workflow"] = catalogue["workflow"];
    projection["profile"] = "strict";
    projection["catalogue_schema_version"] = catalogue["schema_version"];
    projection["supported_overlays"] = catalogue["supported_overlays"];
    projection["rules"] = rules;
    projection
}

fn validate_projection(catalogue, payload_root) {
    let projection = json::read_file(path::join(payload_root, "strict-audit.json"));
    require(projection == project_catalogue(catalogue), "strict audit projection drifted from catalogue");
    require(!projection.contains("authoring") && !projection.contains("authoring_projection"),
        "strict audit projection exposes unavailable everyday guidance");
}

fn validate_schema(payload_root, filename) {
    let schema = json::read_file(path::join(payload_root, filename));
    require(schema["$schema"] == "https://json-schema.org/draft/2020-12/schema", filename + " uses wrong JSON Schema dialect");
    require(schema["$id"].contains("typescript-quality"), filename + " has wrong schema identity");
    require(schema["type"] == "object", filename + " root must be an object");
    require_array(schema["required"], filename + " required fields");
    require(schema["required"].len() > 0, filename + " requires no fields");
}

fn validate_profile(profile, context) {
    for key in [
        "schema_version", "language", "workflow", "profile", "packages",
        "unregistered_candidates", "evidence_selectors", "exclusions",
        "deviations_file", "when_unresolved",
    ] {
        require_key(profile, key, context);
    }
    require(profile["schema_version"] == "1.0.0", context + " uses unsupported schema");
    require(profile["language"] == "typescript", context + " language must be typescript");
    require(profile["workflow"] == "explicit_audit_repair", context + " workflow must remain explicit-audit-only");
    require(profile["profile"] == "strict", context + " must activate strict");
    require_array(profile["packages"], context + " packages");
    require_array(profile["unregistered_candidates"], context + " unregistered candidates");
    for evidence_class in ["compiler", "framework", "lint", "test"] {
        require_key(profile["evidence_selectors"], evidence_class, context + " evidence selectors");
        require_array(profile["evidence_selectors"][evidence_class], context + " " + evidence_class + " selectors");
    }
    for exclusion_class in ["generated", "vendored", "fixtures", "documentation", "build_output"] {
        require_key(profile["exclusions"], exclusion_class, context + " exclusions");
        require_array(profile["exclusions"][exclusion_class], context + " " + exclusion_class + " exclusions");
    }
    require(profile["deviations_file"] == "docs/contracts/typescript-quality-deviations.json",
        context + " deviations path drifted");
    require(profile["when_unresolved"] == "stop", context + " must stop when ownership or overlay is unresolved");
}

fn validate_templates(northstar_skill_root) {
    let template_root = path::join(northstar_skill_root, "assets/templates/language-quality/typescript");
    let profile = json::read_file(path::join(template_root, "typescript-quality-profile.json"));
    let deviations = json::read_file(path::join(template_root, "typescript-quality-deviations.json"));
    validate_profile(profile, "TypeScript profile template");
    require(deviations["schema_version"] == "1.0.0", "TypeScript deviations use unsupported schema");
    require(deviations["language"] == "typescript", "TypeScript deviations language drifted");
    require_array(deviations["deviations"], "TypeScript deviations");
}

fn require_command(commands, name) {
    require(commands.contains(name), "runtime capabilities omit required command: " + name);
}

fn validate_manifest(manifest) {
    require(manifest["schema_version"] == "1.0.0", "unsupported package schema version");
    require(manifest["package_id"] == "@northstar/typescript-quality", "package id drifted");
    require(manifest["version"] == "0.1.0", "package version drifted");
    require(manifest["kind"] == "language-quality", "package kind drifted");
    require(manifest["compatible_core_range"] == ">=0.2.0 <1.0.0", "core range drifted");
    require(manifest["supported_languages"] == ["typescript"], "supported languages drifted");
    require(manifest["supported_overlays"] == ["base", "svelte", "sveltekit"], "supported overlays drifted");
    require(!manifest["available_workflows"].contains("everyday_authoring"),
        "everyday authoring must not be routable");
    require(manifest["available_workflows"] == ["explicit_audit_repair"],
        "package must remain explicit-audit-only");
    require(manifest["entrypoints"]["explicit_audit_repair"] == "references/modes/typescript-quality-audit.md",
        "explicit audit entrypoint drifted");
    require(!manifest["entrypoints"].contains("everyday_authoring"),
        "everyday authoring entrypoint must not be routable");
    require_command(manifest["runtime_capabilities"]["required_commands"], "effigy");
    require_command(manifest["runtime_capabilities"]["required_commands"], "sh");
    require(manifest["self_check"]["entrypoint"] == "scripts/self-check.sh", "self-check entrypoint drifted");
    require(manifest["self_check"]["invocation"]["type"] == "direct", "self-check must use direct invocation");
    require(manifest["self_check"]["validated_profile_versions"] == ["1.0.0"],
        "validated profile versions drifted");
    require(manifest["self_check"]["validated_schema_versions"] == ["1.0.0"],
        "validated schema versions drifted");
}

fn expected_package_files() {
    [
        "SKILL.md",
        "agents/openai.yaml",
        "assets/templates/language-quality/typescript/AGENTS.md",
        "assets/templates/language-quality/typescript/typescript-quality-deviations.json",
        "assets/templates/language-quality/typescript/typescript-quality-profile.json",
        "effigy.toml",
        "northstar-package.json",
        "references/language-quality/typescript/audit-manifest.schema.json",
        "references/language-quality/typescript/audit-recording.md",
        "references/language-quality/typescript/audit-result.schema.json",
        "references/language-quality/typescript/audit-unit.schema.json",
        "references/language-quality/typescript/catalogue.json",
        "references/language-quality/typescript/catalogue.schema.json",
        "references/language-quality/typescript/profile.schema.json",
        "references/language-quality/typescript/strict-audit.json",
        "references/modes/typescript-quality-audit.md",
        "scripts/check-typescript-quality.rhai",
        "scripts/prove-installed-invocation.sh",
        "scripts/self-check.sh",
        "scripts/typescript-quality-recorder.rhai",
        "scripts/typescript-quality-setup.rhai",
    ]
}

fn validate_inventory(package_root) {
    let prefix = package_root;
    if !str::ends_with(prefix, "/") { prefix += "/"; }
    let files = [];
    for file in fs::list_recursive(package_root) {
        let relative = str::replace(file, prefix, "");
        if !str::starts_with(relative, ".effigy/") {
            files.push(relative);
        }
    }
    let expected = expected_package_files();
    for relative in files {
        require(expected.contains(relative), "unexpected package file: " + relative);
    }
    for relative in expected {
        require(files.contains(relative), "missing package file: " + relative);
    }
    require(files.len() == 21, "package must contain exactly 21 files");
}

fn validate_runtime_surface(package_root) {
    let mode_path = path::join(package_root, "references/modes/typescript-quality-audit.md");
    let recording_path = path::join(package_root, "references/language-quality/typescript/audit-recording.md");
    let setup_path = path::join(package_root, "scripts/typescript-quality-setup.rhai");
    let recorder_path = path::join(package_root, "scripts/typescript-quality-recorder.rhai");
    let adapter_path = path::join(package_root, "SKILL.md");
    let policy_path = path::join(package_root, "agents/openai.yaml");
    let mode = fs::read_file(mode_path);
    let recording = fs::read_file(recording_path);
    let setup = fs::read_file(setup_path);
    let recorder = fs::read_file(recorder_path);
    let adapter = fs::read_file(adapter_path);
    let policy = fs::read_file(policy_path);
    let catalog = fs::read_file(path::join(package_root, "effigy.toml"));
    require(mode.contains("coding never selects this mode"),
        "TypeScript audit mode permits implicit activation");
    require(mode.contains("Do not load or invent an") && mode.contains("everyday authoring projection"),
        "TypeScript audit mode permits unavailable everyday guidance");
    require(mode.contains("`extend` before editing") && mode.contains("dirty-state loss"),
        "TypeScript audit mode lacks mutation and preservation boundaries");
    require(recording.contains("compiler|framework|lint|test") && recording.contains("failure_stage"),
        "recording contract lacks typed tool evidence");
    require(!mode.contains("northstar/typescript-quality:") &&
        !recording.contains("northstar/typescript-quality:"),
        "installed invocation still names the embedded Northstar catalogue");
    require(mode.contains("effigy skill run --path") && mode.contains("typescript-quality:setup") &&
        mode.contains("--repo <consumer-root>"),
        "TypeScript audit mode lacks installed package setup invocation");
    require(recording.contains("effigy skill run --path") && recording.contains("typescript-quality:record") &&
        recording.contains("--repo <consumer-root>"),
        "recording contract lacks installed package recorder invocation");
    require(setup.contains("task_args[0] == \"--\"") && recorder.contains("task_args[0] == \"--\""),
        "package scripts do not normalize the Effigy relay sentinel");
    require(adapter.contains("Thin explicit entrypoint") && !adapter.contains("## Procedure"),
        "TypeScript audit adapter is not thin");
    require(adapter.contains("Do not activate from ordinary coding"),
        "TypeScript audit adapter permits ordinary-coding activation");
    require(policy.contains("allow_implicit_invocation: false"),
        "TypeScript audit adapter allows implicit invocation");
    require(catalog.contains("check:typescript-quality") && catalog.contains("typescript-quality:setup") &&
        catalog.contains("typescript-quality:record") && catalog.contains("test:typescript-quality-setup") &&
        catalog.contains("test:typescript-quality-recorder") &&
        catalog.contains("test:typescript-quality-installed-route"), "skill-local TypeScript selectors are incomplete");
    require(!setup.contains("process::") && !setup.contains("command::"),
        "TypeScript setup can launch a subprocess");
    require(!recorder.contains("process::") && !recorder.contains("command::"),
        "TypeScript recorder can launch a subprocess");
    require(setup.contains("catalog_root") && recorder.contains("catalog_root"),
        "package scripts still resolve assets from consumer repo_root");
    require(!setup.contains("path::join(repo_root, \"skills/northstar/") &&
        !recorder.contains("path::join(repo_root, \"skills/northstar/"),
        "package scripts still infer assets from an embedded Northstar checkout");
    require(fs::file_size(mode_path) <= 12288, "TypeScript audit mode exceeds context budget");
    require(fs::file_size(recording_path) <= 12288, "TypeScript recording contract exceeds context budget");
    require(fs::file_size(adapter_path) <= 1200, "TypeScript adapter exceeds thin-adapter budget");
}

fn adapter_path_references(adapter) {
    let references = [];
    let parts = adapter.split("`");
    for index in 0..parts.len() {
        if index % 2 == 1 &&
            parts[index].contains("/") &&
            regex::is_match("^(\\./|\\.\\./|/)?([A-Za-z0-9._-]+/)*[A-Za-z0-9._-]+\\.[A-Za-z0-9]+$", parts[index]) {
            references.push(parts[index]);
        }
    }
    references
}

fn validate_adapter_closure(package_root, adapter, manifest) {
    let references = adapter_path_references(adapter);
    require(references.len() > 0, "adapter loads no package-local path reference");
    for reference in references {
        require(!str::starts_with(reference, "/"),
            "adapter reference is absolute: " + reference);
        require(!reference.contains(".."),
            "adapter reference escapes the package root: " + reference);
        require(fs::is_file(path::join(package_root, reference)),
            "adapter reference is missing from the installed package: " + reference);
    }
    let entrypoint = manifest["entrypoints"]["explicit_audit_repair"];
    require(references.contains(entrypoint),
        "adapter does not load the manifest explicit_audit_repair entrypoint: " + entrypoint);
}

fn expect_closure_rejection(package_root, label, adapter, manifest, expected) {
    let rejected = false;
    try {
        validate_adapter_closure(package_root, adapter, manifest);
    } catch (error) {
        rejected = true;
        require(error.to_string().contains(expected), label + " rejected for wrong reason: " + error);
    }
    require(rejected, label + " unexpectedly passed");
}

fn adapter_closure_self_test(package_root, manifest) {
    let adapter = fs::read_file(path::join(package_root, "SKILL.md"));
    validate_adapter_closure(package_root, adapter, manifest);

    let entrypoint = "`references/modes/typescript-quality-audit.md`";
    let missing = str::replace(adapter, entrypoint, "`references/router.md`");
    expect_closure_rejection(package_root, "missing adapter path", missing, manifest,
        "missing from the installed package");

    let absolute = str::replace(adapter, entrypoint,
        "`/usr/local/share/northstar/references/modes/typescript-quality-audit.md`");
    expect_closure_rejection(package_root, "absolute adapter path", absolute, manifest, "absolute");

    let escaping = str::replace(adapter, entrypoint,
        "`references/../../outside/typescript-quality-audit.md`");
    expect_closure_rejection(package_root, "escaping adapter path", escaping, manifest,
        "escapes the package root");

    let disagreement = str::replace(adapter, entrypoint,
        "`references/language-quality/typescript/audit-recording.md`");
    expect_closure_rejection(package_root, "manifest/adapter disagreement", disagreement, manifest,
        "does not load the manifest explicit_audit_repair entrypoint");
}

fn expect_rejection(label, catalogue, expected) {
    let rejected = false;
    try {
        validate_catalogue(catalogue);
    } catch (error) {
        rejected = true;
        require(error.to_string().contains(expected), label + " rejected for wrong reason: " + error);
    }
    require(rejected, label + " unexpectedly passed");
}

fn expect_manifest_rejection(label, manifest, expected) {
    let rejected = false;
    try {
        validate_manifest(manifest);
    } catch (error) {
        rejected = true;
        require(error.to_string().contains(expected), label + " rejected for wrong reason: " + error);
    }
    require(rejected, label + " unexpectedly passed");
}

fn self_test(catalogue_path, manifest_path) {
    let everyday = json::read_file(catalogue_path);
    everyday["rules"][0]["authoring_projection"] = ["write code"];
    expect_rejection("everyday surface", everyday, "unavailable everyday");

    let deferred = json::read_file(catalogue_path);
    deferred["rules"][0]["id"] = "TS-TOOLCHAIN-001";
    expect_rejection("deferred rule", deferred, "inventory drifted");

    let slop_enforced = json::read_file(catalogue_path);
    let slop_rule = find_rule(slop_enforced, "TS-SLOP-001");
    slop_rule["strict_enforcement"] = "required";
    slop_enforced = replace_rule(slop_enforced, slop_rule);
    expect_rejection("slop enforcement", slop_enforced, "strict enforcement drifted");

    let slop_repair = json::read_file(catalogue_path);
    let repair_rule = find_rule(slop_repair, "TS-SLOP-001");
    repair_rule["remediation"]["default_authority"] = "review_required";
    slop_repair = replace_rule(slop_repair, repair_rule);
    expect_rejection("slop authority", slop_repair, "report-only");

    let overlay = json::read_file(catalogue_path);
    let overlay_rule = find_rule(overlay, "SVELTE-SSR-001");
    overlay_rule["overlay"] = "svelte";
    overlay = replace_rule(overlay, overlay_rule);
    expect_rejection("overlay drift", overlay, "overlay drifted");

    let unpinned = json::read_file(catalogue_path);
    let source_rule = find_rule(unpinned, "TS-BOUNDARY-001");
    source_rule["provenance"][0]["revision"] = "";
    unpinned = replace_rule(unpinned, source_rule);
    expect_rejection("unpinned provenance", unpinned, "unpinned provenance");

    let broadened = json::read_file(catalogue_path);
    let architecture_rule = find_rule(broadened, "TS-ARCH-001");
    architecture_rule["remediation"]["action_overrides"][0]["authority"] = "review_required";
    broadened = replace_rule(broadened, architecture_rule);
    expect_rejection("architecture authority", broadened, "operator decision");

    let everyday_workflow = json::read_file(manifest_path);
    everyday_workflow["available_workflows"] = ["everyday_authoring", "explicit_audit_repair"];
    expect_manifest_rejection("everyday workflow", everyday_workflow, "everyday authoring must not be routable");
}

fn test_self_check_wrapper(package_root) {
    let wrapper = path::join(package_root, "scripts/self-check.sh");
    require(fs::is_file(wrapper), "self-check wrapper is missing");
    let executable = process::run("/bin/test", ["-x", wrapper]);
    require(executable["success"], "self-check wrapper is not executable");
    let text = fs::read_file(wrapper);
    require(text.contains("command -v sh") && text.contains("command -v effigy"),
        "self-check wrapper does not enforce declared commands");
    require(text.contains("effigy check:typescript-quality"),
        "self-check wrapper does not run the package-owned Effigy check");

    let proof = path::join(package_root, "scripts/prove-installed-invocation.sh");
    require(fs::is_file(proof), "installed-invocation proof is missing");
    let proof_executable = process::run("/bin/test", ["-x", proof]);
    require(proof_executable["success"], "installed-invocation proof is not executable");
    let proof_text = fs::read_file(proof);
    require(proof_text.contains("effigy skill run --path") &&
        proof_text.contains("northstar/typescript-quality:setup") &&
        proof_text.contains("DECOY-NORTHSTAR-SETUP-RAN"),
        "installed-invocation proof does not exercise the public skill-run surface and negative fixtures");

    let missing_effigy = process::run(wrapper, [package_root], #{
        cwd: package_root,
        env: #{ PATH: "/usr/bin:/bin" },
    });
    require(!missing_effigy["success"], "self-check succeeded without effigy");
    require(missing_effigy["stderr"].contains("missing required command: effigy"),
        "self-check hid the missing-effigy failure: " + missing_effigy["stderr"]);

    let staged = fs::make_temp_dir("typescript-quality-self-check-nonexec");
    let locked = path::join(staged, "self-check.sh");
    fs::copy(wrapper, locked);
    process::run("/bin/chmod", ["644", locked]);
    let nonexec_rejected = false;
    try {
        let nonexec = process::run(locked, [package_root], #{ cwd: package_root });
        require(!nonexec["success"], "non-executable self-check wrapper ran");
        nonexec_rejected = true;
    } catch (error) {
        nonexec_rejected = true;
        require(error.to_string().contains("Permission denied") ||
            error.to_string().contains("permission denied") ||
            error.to_string().contains("not found") ||
            error.to_string().contains("os error 13"),
            "non-executable wrapper failed for the wrong reason: " + error);
    }
    require(nonexec_rejected, "non-executable self-check wrapper unexpectedly passed");
}

require(type_of(catalog_root) == "string" && catalog_root.len() > 0,
    "Effigy catalog_root is required for package assets");
require(fs::is_file(path::join(catalog_root, "northstar-package.json")),
    "package assets must resolve from catalog_root, not consumer repo_root");
let package_root = catalog_root;
let payload_root = path::join(package_root, "references/language-quality/typescript");
let catalogue_path = path::join(payload_root, "catalogue.json");
let manifest_path = path::join(package_root, "northstar-package.json");
let catalogue = json::read_file(catalogue_path);
let manifest = json::read_file(manifest_path);
validate_inventory(package_root);
validate_manifest(manifest);
validate_catalogue(catalogue);
validate_projection(catalogue, payload_root);
validate_schema(payload_root, "catalogue.schema.json");
validate_schema(payload_root, "profile.schema.json");
validate_templates(package_root);
validate_runtime_surface(package_root);
adapter_closure_self_test(package_root, manifest);
self_test(catalogue_path, manifest_path);
test_self_check_wrapper(package_root);
for filename in ["audit-manifest.schema.json", "audit-unit.schema.json", "audit-result.schema.json"] {
    validate_schema(payload_root, filename);
}
log("Northstar TypeScript quality package: OK (9 normative rules, 1 evaluation signal, 3 overlays, 21-file inventory, 8 catalogue/manifest and 4 adapter path-closure negative paths, explicit audit only)");
