fn require(condition, message) {
    if !condition {
        throw("[northstar:rust-quality-setup] " + message);
    }
}

fn activation_marker_path(contracts_root) {
    path::join(contracts_root, "language-quality-activation.json")
}

fn read_activation_marker(marker_file) {
    // Only the boolean true opts a repository in; an absent, false, non-boolean
    // or unreadable value is off. Explicit audit never depends on this file, so
    // nothing here fails an audit setup. A present marker is returned unchanged
    // so setup only rewrites it when the repository opts in.
    if !fs::exists(marker_file) {
        return #{};
    }
    if !fs::is_file(marker_file) {
        return ();
    }
    let marker = ();
    try {
        marker = json::read_file(marker_file);
    } catch {
        return ();
    }
    if type_of(marker) != "map" {
        return ();
    }
    marker
}

fn marker_opts_in(marker) {
    type_of(marker) == "map" && marker.contains("everyday_authoring") &&
        marker["everyday_authoring"] == true
}

fn marker_setting_state(marker) {
    // "absent", "true", "false", "not_boolean", or "unreadable" (unit).
    if type_of(marker) != "map" {
        return "unreadable";
    }
    if !marker.contains("everyday_authoring") {
        return "absent";
    }
    if marker["everyday_authoring"] == true {
        return "true";
    }
    if marker["everyday_authoring"] == false {
        return "false";
    }
    "not_boolean"
}

fn enable_everyday_authoring(marker_file, marker) {
    // Opting in writes the marker. Refuse only when an existing marker cannot be
    // parsed: overwriting it would lose content this task does not own.
    require(type_of(marker) == "map",
        "activation marker is not valid JSON; repair " + marker_file + " before opting in");
    if marker_opts_in(marker) {
        return;
    }
    marker["everyday_authoring"] = true;
    json::write_file(marker_file, marker);
}

fn resolve_path(base_root, raw_path) {
    if str::starts_with(raw_path, "/") {
        raw_path
    } else {
        path::join(base_root, raw_path)
    }
}

fn relative_path(root, file) {
    let prefix = root;
    if !str::ends_with(prefix, "/") {
        prefix += "/";
    }
    require(str::starts_with(file, prefix), "discovered file escaped target root: " + file);
    str::replace(file, prefix, "")
}

fn ignored_path(relative) {
    str::starts_with(relative, ".git/") ||
        str::starts_with(relative, ".effigy/") ||
        str::starts_with(relative, "target/") ||
        str::starts_with(relative, "vendor/") ||
        relative.contains("/.git/") ||
        relative.contains("/.effigy/") ||
        relative.contains("/target/") ||
        relative.contains("/vendor/")
}

fn matches_name(relative, name) {
    if relative == name {
        return true;
    }
    str::ends_with(relative, "/" + name)
}

fn discover_named_file(target_root, name) {
    let found = [];
    for file in fs::list_recursive(target_root) {
        let relative = relative_path(target_root, file);
        if !ignored_path(relative) && matches_name(relative, name) {
            found.push(relative);
        }
    }
    found.sort();
    found
}

fn strip_trailing_slashes(value) {
    regex::replace("/+$", value, "")
}

fn normalize_scope_directory(target_root, scope) {
    require(type_of(scope) == "string" && scope != "",
        "scope directory must be repository-relative (. or crates/foo)");
    require(!scope.contains(".."),
        "scope directory cannot contain '..'; use repository-relative form (. or crates/foo): " + scope);

    if str::starts_with(scope, "/") {
        let root = strip_trailing_slashes(target_root);
        let absolute = strip_trailing_slashes(scope);
        require(root != "" && absolute != "",
            "scope directory must be repository-relative (. or crates/foo): " + scope);
        if absolute == root {
            return ".";
        }
        let prefix = root + "/";
        require(str::starts_with(absolute, prefix),
            "scope directory must be under the target root; use repository-relative form (. or crates/foo): " + scope);
        let relative = regex::replace("^" + regex::escape(prefix), absolute, "");
        require(relative != "" && regex::is_match("^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$", relative),
            "scope directory must be repository-relative (. or crates/foo): " + scope);
        return relative;
    }

    require(scope == "." || regex::is_match("^[A-Za-z0-9._-]+(/[A-Za-z0-9._-]+)*$", scope),
        "scope directory must be repository-relative (. or crates/foo): " + scope);
    scope
}

fn validate_profile(profile) {
    require(type_of(profile) == "map", "existing Rust quality profile must be an object");
    require(profile.contains("schema_version") && profile["schema_version"] == "1.0.0",
        "existing Rust quality profile uses an unsupported schema");
    require(profile.contains("language") && profile["language"] == "rust",
        "existing Rust quality profile must select rust");
    require(profile.contains("profile") && profile["profile"] == "strict",
        "existing Rust quality profile must select strict");
    require(profile.contains("msrv") && type_of(profile["msrv"]) == "map",
        "existing Rust quality profile lacks MSRV policy");
    require(profile["msrv"].contains("when_unresolved") &&
        profile["msrv"]["when_unresolved"] == "stop",
        "existing Rust quality profile must stop on unresolved MSRV policy");
    require(profile.contains("deviations_file") &&
        profile["deviations_file"] == "docs/knowledge/contracts/rust-quality-deviations.json",
        "existing Rust quality profile has an unsupported deviations path");
}

fn validate_deviations(deviations) {
    require(type_of(deviations) == "map", "existing Rust deviations file must be an object");
    require(deviations.contains("schema_version") && deviations["schema_version"] == "1.0.0",
        "existing Rust deviations file uses an unsupported schema");
    require(deviations.contains("language") && deviations["language"] == "rust",
        "existing Rust deviations file must select rust");
    require(deviations.contains("deviations") && type_of(deviations["deviations"]) == "array",
        "existing Rust deviations file lacks deviations array");
}

fn agent_instruction_state(agent_file, activation) {
    let start_marker = "<!-- northstar:rust-quality:start -->";
    let end_marker = "<!-- northstar:rust-quality:end -->";
    if !fs::exists(agent_file) {
        return "missing";
    }
    require(fs::is_file(agent_file), "AGENTS target is not a file: " + agent_file);
    let current = fs::read_file(agent_file);
    let has_start = current.contains(start_marker);
    let has_end = current.contains(end_marker);
    require(has_start == has_end, "existing AGENTS.md has an incomplete Rust activation block");
    if has_start {
        require(current.contains(activation),
            "existing Rust activation differs from the installed Northstar template; inspect before replacing it");
        "current"
    } else {
        "append"
    }
}

fn install_agent_instructions(agent_file, activation, state) {
    if state == "missing" {
        fs::write_file(agent_file, activation);
    } else if state == "append" {
        let current = fs::read_file(agent_file);
        let separator = "\n";
        if str::ends_with(current, "\n") {
            separator = "";
        }
        fs::write_file(agent_file, current + separator + "\n" + activation);
    }
}

fn repository_declares_msrv(target_root, manifests, toolchain_paths) {
    for relative in manifests {
        if fs::read_file(path::join(target_root, relative)).contains("rust-version") {
            return true;
        }
    }
    toolchain_paths.len() > 0
}

fn apply_setup(northstar_skill_root, target_root, scope, opt_in) {
    require(fs::is_dir(target_root), "target root is not a directory: " + target_root);
    let scope = normalize_scope_directory(target_root, scope);
    let scope_root = target_root;
    if scope != "." {
        scope_root = path::join(target_root, scope);
    }
    require(fs::is_dir(scope_root), "Rust instruction scope is not a directory: " + scope);

    let manifests = discover_named_file(target_root, "Cargo.toml");
    require(manifests.len() > 0, "no Cargo.toml found under target root");
    let toolchain_paths = discover_named_file(target_root, "rust-toolchain.toml");
    for relative in discover_named_file(target_root, "rust-toolchain") {
        toolchain_paths.push(relative);
    }
    toolchain_paths.sort();

    let asset_root = path::join(northstar_skill_root, "assets/templates/language-quality/rust");
    let activation = fs::read_file(path::join(asset_root, "AGENTS.md"));
    let agent_file = path::join(scope_root, "AGENTS.md");
    let agent_state = agent_instruction_state(agent_file, activation);

    let contracts_root = path::join(target_root, "docs/knowledge/contracts");
    let profile_file = path::join(contracts_root, "rust-quality-profile.json");
    let deviations_file = path::join(contracts_root, "rust-quality-deviations.json");
    let marker_file = activation_marker_path(contracts_root);
    let marker = read_activation_marker(marker_file);
    // Everyday authoring is a repository choice, off by default. The flag opts
    // this repository in; a marker that already says so keeps it on.
    let everyday = opt_in || marker_opts_in(marker);
    if fs::exists(profile_file) {
        require(fs::is_file(profile_file), "Rust quality profile target is not a file");
        validate_profile(json::read_file(profile_file));
    }
    if fs::exists(deviations_file) {
        require(fs::is_file(deviations_file), "Rust deviations target is not a file");
        validate_deviations(json::read_file(deviations_file));
    }

    // The activation block is the everyday-authoring boilerplate a brief reads.
    // Without the opt-in it is not installed, and setup never removes one that
    // already exists.
    if everyday {
        install_agent_instructions(agent_file, activation, agent_state);
    }
    if !fs::exists(profile_file) || !fs::exists(deviations_file) || everyday {
        fs::create_dir(contracts_root);
    }
    if !fs::exists(profile_file) {
        let profile = json::read_file(path::join(asset_root, "rust-quality-profile.json"));
        profile["msrv"]["cargo_manifests"] = manifests;
        profile["msrv"]["toolchain_policy_paths"] = toolchain_paths;
        json::write_file(profile_file, profile);
    }
    if !fs::exists(deviations_file) {
        let deviations = json::read_file(path::join(asset_root, "rust-quality-deviations.json"));
        json::write_file(deviations_file, deviations);
    }
    if everyday {
        enable_everyday_authoring(marker_file, marker);
    }

    if !repository_declares_msrv(target_root, manifests, toolchain_paths) {
        log_warn("[northstar:rust-quality-setup] activation installed, but repository MSRV is unresolved; obtain repository policy before version-sensitive work");
    }
    let everyday_state = "off";
    if everyday {
        everyday_state = "on";
    }
    if !everyday && agent_state == "current" {
        log_warn("[northstar:rust-quality-setup] everyday authoring is off for this repository: the existing Rust activation block stays, and the route reports unavailable until everyday_authoring is true in " + marker_file);
    }
    if !everyday && marker_setting_state(marker) == "not_boolean" {
        log_warn("[northstar:rust-quality-setup] ignored " + marker_file + ": only the boolean true opts in to everyday authoring");
    }
    if !everyday && marker_setting_state(marker) == "unreadable" {
        log_warn("[northstar:rust-quality-setup] ignored " + marker_file + ": it is not valid JSON, so this repository has not opted in to everyday authoring");
    }
    log("Northstar Rust quality activation: OK (scope=" + scope +
        ", manifests=" + manifests.len() + ", toolchain_paths=" + toolchain_paths.len() +
        ", everyday_authoring=" + everyday_state + ")");
}

fn expect_error(label, action, expected) {
    let rejected = false;
    try {
        call(action);
    } catch (error) {
        rejected = true;
        require(error.to_string().contains(expected),
            label + " rejected for wrong reason: " + error.to_string());
    }
    require(rejected, label + " unexpectedly passed");
}

fn self_test(northstar_skill_root) {
    let target = fs::make_temp_dir("northstar-rust-quality-setup-positive");
    fs::create_dir(path::join(target, "crates/app/src"));
    fs::write_file(path::join(target, "Cargo.toml"),
        "[workspace]\nmembers = [\"crates/app\"]\n[workspace.package]\nrust-version = \"1.95\"\n");
    fs::write_file(path::join(target, "crates/app/Cargo.toml"),
        "[package]\nname = \"app\"\nversion = \"0.1.0\"\nrust-version.workspace = true\n");
    fs::write_file(path::join(target, "AGENTS.md"), "# Existing instructions\n");
    // Off by default: setup writes the repository's contracts but neither the
    // everyday-authoring block nor an opt-in marker.
    apply_setup(northstar_skill_root, target, ".", false);

    let contracts_root = path::join(target, "docs/knowledge/contracts");
    let profile_file = path::join(contracts_root, "rust-quality-profile.json");
    let deviations_file = path::join(contracts_root, "rust-quality-deviations.json");
    let marker_file = activation_marker_path(contracts_root);
    let agent_file = path::join(target, "AGENTS.md");
    let profile = json::read_file(profile_file);
    require(profile["msrv"]["cargo_manifests"] == ["Cargo.toml", "crates/app/Cargo.toml"],
        "setup did not discover Cargo manifests deterministically");
    require(profile["msrv"]["toolchain_policy_paths"] == [],
        "setup invented a toolchain policy path");
    require(fs::read_file(agent_file).contains("# Existing instructions"),
        "setup overwrote existing AGENTS instructions");
    require(!fs::read_file(agent_file).contains("<!-- northstar:rust-quality:start -->"),
        "setup installed everyday-authoring activation without the repository opt-in");
    require(!fs::exists(marker_file),
        "setup wrote an activation marker without the repository opt-in");

    let profile_hash = fs::sha256(profile_file);
    let deviations_hash = fs::sha256(deviations_file);
    let agent_hash = fs::sha256(agent_file);
    apply_setup(northstar_skill_root, target, ".", false);
    require(fs::sha256(profile_file) == profile_hash &&
        fs::sha256(deviations_file) == deviations_hash &&
        fs::sha256(agent_file) == agent_hash,
        "repeat setup was not idempotent");
    require(!fs::exists(marker_file), "repeat setup wrote an activation marker");

    // Only the explicit opt-in installs the everyday-authoring boilerplate and
    // records the repository setting.
    apply_setup(northstar_skill_root, target, ".", true);
    require(fs::read_file(agent_file).contains("# Existing instructions") &&
        fs::read_file(agent_file).contains("<!-- northstar:rust-quality:start -->"),
        "opt-in setup did not install scoped activation");
    require(marker_opts_in(json::read_file(marker_file)),
        "opt-in setup did not record everyday_authoring");
    let opted_agent_hash = fs::sha256(agent_file);
    let opted_marker_hash = fs::sha256(marker_file);
    apply_setup(northstar_skill_root, target, ".", true);
    require(fs::sha256(agent_file) == opted_agent_hash && fs::sha256(marker_file) == opted_marker_hash,
        "repeat opt-in setup was not idempotent");

    // A recorded opt-in survives a later run without the flag.
    apply_setup(northstar_skill_root, target, ".", false);
    require(fs::sha256(agent_file) == opted_agent_hash && fs::sha256(marker_file) == opted_marker_hash,
        "setup without the flag dropped a recorded repository opt-in");

    let no_cargo = fs::make_temp_dir("northstar-rust-quality-setup-no-cargo");
    expect_error("missing Cargo manifest", || apply_setup(northstar_skill_root, no_cargo, ".", false), "no Cargo.toml");

    let broken = fs::make_temp_dir("northstar-rust-quality-setup-broken-agents");
    fs::write_file(path::join(broken, "Cargo.toml"),
        "[package]\nname = \"broken\"\nversion = \"0.1.0\"\nrust-version = \"1.95\"\n");
    fs::write_file(path::join(broken, "AGENTS.md"),
        "<!-- northstar:rust-quality:start -->\n");
    expect_error("partial activation", || apply_setup(northstar_skill_root, broken, ".", true), "incomplete Rust activation");

    // Only the boolean true opts in. Any other value is off, so plain
    // explicit-audit setup writes the contracts and leaves the marker alone.
    let odd_marker = fs::make_temp_dir("northstar-rust-quality-setup-non-boolean-marker");
    let odd_contracts = path::join(odd_marker, "docs/knowledge/contracts");
    fs::create_dir(odd_contracts);
    fs::write_file(path::join(odd_marker, "Cargo.toml"),
        "[package]\nname = \"odd-marker\"\nversion = \"0.1.0\"\nrust-version = \"1.95\"\n");
    fs::write_file(activation_marker_path(odd_contracts), "{\"everyday_authoring\": \"yes\"}\n");
    apply_setup(northstar_skill_root, odd_marker, ".", false);
    require(fs::is_file(path::join(odd_contracts, "rust-quality-profile.json")),
        "a non-boolean everyday_authoring value stopped explicit-audit setup");
    require(!fs::exists(path::join(odd_marker, "AGENTS.md")),
        "a non-boolean everyday_authoring value installed everyday activation");
    require(json::read_file(activation_marker_path(odd_contracts))["everyday_authoring"] == "yes",
        "setup rewrote a marker it did not opt in");
    fs::write_file(activation_marker_path(odd_contracts), "{\"everyday_authoring\": false}\n");
    apply_setup(northstar_skill_root, odd_marker, ".", false);
    require(!fs::exists(path::join(odd_marker, "AGENTS.md")),
        "an explicit false installed everyday activation");
    require(json::read_file(activation_marker_path(odd_contracts))["everyday_authoring"] == false,
        "setup rewrote an explicit false");

    // An unreadable marker is off for audit, and opting in refuses to overwrite
    // content it cannot parse.
    let bad_marker = fs::make_temp_dir("northstar-rust-quality-setup-bad-marker");
    let bad_contracts = path::join(bad_marker, "docs/knowledge/contracts");
    fs::create_dir(bad_contracts);
    fs::write_file(path::join(bad_marker, "Cargo.toml"),
        "[package]\nname = \"bad-marker\"\nversion = \"0.1.0\"\nrust-version = \"1.95\"\n");
    fs::write_file(activation_marker_path(bad_contracts), "not json\n");
    apply_setup(northstar_skill_root, bad_marker, ".", false);
    require(fs::is_file(path::join(bad_contracts, "rust-quality-profile.json")),
        "an unreadable marker stopped explicit-audit setup");
    require(fs::read_file(activation_marker_path(bad_contracts)) == "not json\n",
        "setup rewrote an unreadable marker");
    expect_error("unreadable marker opt-in",
        || apply_setup(northstar_skill_root, bad_marker, ".", true),
        "activation marker is not valid JSON");

    let absolute_root = fs::make_temp_dir("northstar-rust-quality-setup-absolute-root");
    fs::create_dir(path::join(absolute_root, "crates/app"));
    fs::write_file(path::join(absolute_root, "Cargo.toml"),
        "[package]\nname = \"absolute-root\"\nversion = \"0.1.0\"\nrust-version = \"1.95\"\n");
    require(normalize_scope_directory(absolute_root, absolute_root) == ".",
        "absolute target-root scope did not canonicalize to '.'");
    require(normalize_scope_directory(absolute_root, path::join(absolute_root, "crates/app")) == "crates/app",
        "absolute under-target scope did not canonicalize to relative form");
    apply_setup(northstar_skill_root, absolute_root, absolute_root, true);
    require(fs::read_file(path::join(absolute_root, "AGENTS.md")).contains("<!-- northstar:rust-quality:start -->"),
        "absolute target-root scope did not install activation");

    expect_error("escaped absolute scope",
        || normalize_scope_directory(absolute_root, "/tmp/northstar-rust-quality-setup-outside-scope"),
        "repository-relative form (. or crates/foo)");
    expect_error("parent scope segment",
        || normalize_scope_directory(absolute_root, ".."),
        "repository-relative form (. or crates/foo)");

    let relayed = strip_relay_boundary(["--", "apply", "/tmp/northstar-rust-quality-setup-target", "."]);
    require(relayed.len() == 3 && relayed[0] == "apply" && relayed[1] == "/tmp/northstar-rust-quality-setup-target" &&
        relayed[2] == ".",
        "setup does not skip a single leading relay boundary");
    let direct = strip_relay_boundary(["apply", "/tmp/northstar-rust-quality-setup-target", "."]);
    require(direct.len() == 3 && direct[0] == "apply",
        "setup strips arguments that are not a relay boundary");
    require(strip_relay_boundary(["--"]).len() == 0,
        "setup leaves the empty relay boundary in place");
}

fn strip_relay_boundary(arguments) {
    // Effigy hands Rhai steps the literal `--` boundary between the relay
    // selector and the forwarded operation (Effigy planner, 2026-10-22; the
    // boundary papercut is Effigy's). Skip one leading boundary when present so
    // the usage check sees the real operation; a fixed Effigy that omits it
    // keeps working.
    if arguments.len() > 0 && arguments[0] == "--" {
        let forwarded = [];
        for index in 1..arguments.len() {
            forwarded.push(arguments[index]);
        }
        return forwarded;
    }
    arguments
}

fn test_consumer_decoy_ignored(package_root) {
    let consumer = fs::make_temp_dir("northstar-rust-setup-decoy");
    fs::write_file(path::join(consumer, "Cargo.toml"),
        "[package]\nname = \"decoy\"\nversion = \"0.1.0\"\nrust-version = \"1.95\"\n");
    let decoy_root = path::join(consumer, "skills/northstar/assets/templates/language-quality/rust");
    fs::create_dir(decoy_root);
    fs::write_file(path::join(decoy_root, "AGENTS.md"), "DECOY ACTIVATION FROM CONSUMER ROOT\n");
    fs::write_file(path::join(decoy_root, "rust-quality-profile.json"), "{}\n");
    apply_setup(package_root, consumer, ".", true);
    let written = fs::read_file(path::join(consumer, "AGENTS.md"));
    require(!written.contains("DECOY ACTIVATION FROM CONSUMER ROOT"),
        "setup loaded assets from consumer repo_root");
    require(written.contains("northstar:rust-quality:start"),
        "setup did not copy package-owned activation");
}

require(type_of(catalog_root) == "string" && catalog_root.len() > 0,
    "Effigy catalog_root is required for package assets");
require(fs::is_file(path::join(catalog_root, "northstar-package.json")),
    "package assets must resolve from catalog_root, not consumer repo_root");
let northstar_skill_root = catalog_root;
let task_args = strip_relay_boundary(args);

if task_args.len() == 1 && task_args[0] == "self-test" {
    self_test(northstar_skill_root);
    test_consumer_decoy_ignored(northstar_skill_root);
    log("Northstar Rust quality setup self-test: OK (opt-in off by default, opt-in install, preserve, idempotency, non-boolean and false off, unreadable marker off for audit and refused on opt-in, absolute-under-target, decoy ignored)");
} else if task_args.len() >= 2 && task_args.len() <= 4 && task_args[0] == "apply" {
    let positional = [];
    let opt_in = false;
    for index in 1..task_args.len() {
        if task_args[index] == "--everyday-authoring" {
            opt_in = true;
        } else {
            positional.push(task_args[index]);
        }
    }
    if positional.len() < 1 || positional.len() > 2 {
        throw("usage: rust-quality:setup self-test | apply <target-root> [scope-directory (. or crates/foo)] [--everyday-authoring]");
    }
    let target_root = resolve_path(repo_root, positional[0]);
    let scope = ".";
    if positional.len() == 2 {
        scope = positional[1];
    }
    apply_setup(northstar_skill_root, target_root, scope, opt_in);
} else {
    throw("usage: rust-quality:setup self-test | apply <target-root> [scope-directory (. or crates/foo)] [--everyday-authoring]");
}
