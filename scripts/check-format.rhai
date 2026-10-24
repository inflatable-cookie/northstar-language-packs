// Repository format check for the maintained package sources.
//
// Shell: mvdan/sh `shfmt` (v3) with this repository's declared style,
// `--indent 4 --language-dialect posix`, run in `--diff` mode. It reports and
// exits non-zero; it never rewrites a file. The inventory below is the whole
// maintained shell surface, and a maintained `.sh` file under a `scripts/`
// directory that is missing from it fails the check instead of escaping it.
//
// Rhai: no maintained Rhai formatter exists. The Rhai project ships none and
// this repository has no maintained third-party formatter to call, so the check
// declares that limitation and checks nothing there rather than inventing
// formatting semantics. `rhai_sources()` is the exact set it does not check.
//
// Usage: `effigy format:check`, or `effigy format:check self-test` for the
// fixture proof that a malformed source fails, a formatted control passes, and
// neither file is rewritten.

fn label() {
    "[northstar-language-packs:format] "
}

fn shell_style() {
    "--indent 4 --language-dialect posix (shfmt --diff)"
}

fn fail(message) {
    throw(label() + message);
}

// The whole maintained shell surface. Adding a shell source means adding it
// here; the coverage guard below fails closed otherwise.
fn shell_sources() {
    [
        "scripts/verify-package-identities.sh",
        "packages/rust/scripts/prove-installed-invocation.sh",
        "packages/rust/scripts/self-check.sh",
        "packages/typescript/scripts/prove-installed-invocation.sh",
        "packages/typescript/scripts/self-check.sh",
    ]
}

// The maintained Rhai surface this check cannot cover, declared so nobody reads
// the shell result as whole-repository format coverage.
fn rhai_sources() {
    [
        "packages/rust/scripts/check-rust-quality.rhai",
        "packages/rust/scripts/rust-quality-setup.rhai",
        "packages/typescript/scripts/check-typescript-quality.rhai",
        "packages/typescript/scripts/typescript-quality-recorder.rhai",
        "packages/typescript/scripts/typescript-quality-setup.rhai",
        "scripts/check-format.rhai",
    ]
}

fn package_catalogs() {
    [
        "packages/rust",
        "packages/typescript",
    ]
}

fn relative(repo_root, path) {
    str::replace(path, repo_root + "/", "")
}

fn discover(repo_root, files) {
    let found = [];
    for entry in files {
        if fs::is_file(entry) {
            found.push(relative(repo_root, entry));
        }
    }
    found
}

fn maintained_scripts(repo_root) {
    // Every maintained source lives in a `scripts/` directory: the repository
    // one and one per package. Frozen Rust fixtures, templates and generated
    // payloads are not maintained shell or Rhai sources and stay out of scope.
    let dirs = [path::join(repo_root, "scripts")];
    let packages_root = path::join(repo_root, "packages");
    if fs::is_dir(packages_root) {
        let package_dirs = fs::list(packages_root);
        for package_dir in package_dirs {
            if fs::is_dir(package_dir) {
                let scripts_dir = path::join(package_dir, "scripts");
                if fs::is_dir(scripts_dir) {
                    dirs.push(scripts_dir);
                }
            }
        }
    }
    dirs.sort();
    dirs
}

fn sources_with_suffix(repo_root, suffix) {
    let found = [];
    for dir in maintained_scripts(repo_root) {
        let files = [];
        for entry in fs::list(dir) {
            if str::ends_with(entry, suffix) {
                files.push(entry);
            }
        }
        found += discover(repo_root, files);
    }
    found.sort();
    found
}

fn same_set(declared, discovered) {
    if declared.len() != discovered.len() {
        return false;
    }
    for path in declared {
        if !discovered.contains(path) {
            return false;
        }
    }
    true
}

fn verify_coverage(repo_root, shell, rhai) {
    let discovered_shell = sources_with_suffix(repo_root, ".sh");
    let discovered_rhai = sources_with_suffix(repo_root, ".rhai");
    if !same_set(shell, discovered_shell) {
        for path in discovered_shell {
            if !shell.contains(path) {
                fail("maintained shell source is not declared in this check: " + path);
            }
        }
        for path in shell {
            if !discovered_shell.contains(path) {
                fail("declared shell source does not exist: " + path);
            }
        }
        fail("declared shell inventory does not match the maintained shell sources");
    }
    if !same_set(rhai, discovered_rhai) {
        for path in discovered_rhai {
            if !rhai.contains(path) {
                fail("maintained Rhai source is not declared in this check: " + path);
            }
        }
        for path in rhai {
            if !discovered_rhai.contains(path) {
                fail("declared Rhai source does not exist: " + path);
            }
        }
        fail("declared Rhai inventory does not match the maintained Rhai sources");
    }
}

fn verify_catalogues(repo_root, shell) {
    // The package catalogues carry the same check as an explicit file list, so
    // their selector covers exactly their own maintained shell sources.
    for package_dir in package_catalogs() {
        let catalogue_path = path::join(repo_root, path::join(package_dir, "effigy.toml"));
        if !fs::is_file(catalogue_path) {
            fail("package catalogue is missing: " + package_dir + "/effigy.toml");
        }
        let catalogue = toml::read_file(catalogue_path);
        let tasks = catalogue["tasks"];
        if type_of(tasks) != "map" || !tasks.contains("format:check") {
            fail(package_dir + "/effigy.toml does not declare `format:check`");
        }
        let command = tasks["format:check"];
        if type_of(command) != "string" {
            fail(package_dir + "/effigy.toml `format:check` must stay a shell command");
        }
        if !command.contains("shfmt") || !command.contains("--diff") {
            fail(package_dir + "/effigy.toml `format:check` does not run shfmt in --diff mode");
        }
        if !command.contains("--indent 4") || !command.contains("--language-dialect posix") {
            fail(package_dir + "/effigy.toml `format:check` does not declare the repository style");
        }
        if command.contains(".rhai") {
            fail(package_dir + "/effigy.toml `format:check` claims Rhai format coverage");
        }
        for path in shell {
            if !str::starts_with(path, package_dir + "/") {
                continue;
            }
            let local = str::replace(path, package_dir + "/", "");
            if !command.contains(local) {
                fail(package_dir + "/effigy.toml `format:check` does not cover " + local);
            }
        }
    }
}

fn shfmt_version() {
    let result = ();
    try {
        result = process::run("shfmt", ["--version"]);
    } catch (error) {
        fail("missing required command `shfmt` (mvdan/sh v3), so shell format coverage cannot run: " + error);
    }
    if !result["success"] {
        fail("`shfmt --version` failed: " + str::trim(result["stderr"]));
    }
    let version = str::trim(result["stdout"]);
    if !str::starts_with(version, "v3.") {
        fail("unsupported shfmt version `" + version + "`: this check declares the mvdan/sh v3 output it was formatted against");
    }
    version
}

fn shfmt_diff(repo_root, files) {
    let process_args = ["--diff", "--indent", "4", "--language-dialect", "posix"];
    for file in files {
        process_args.push(file);
    }
    process::run("shfmt", process_args, #{ cwd: repo_root })
}

fn check_shell(repo_root, shell, version) {
    let result = shfmt_diff(repo_root, shell);
    if result["success"] {
        log(label() + "shell: " + shell.len().to_string() + " file(s) clean (" + version + ", " + shell_style() + ")");
        return;
    }
    let report = str::trim(result["stdout"]);
    if report == "" {
        report = str::trim(result["stderr"]);
    }
    fail("shell sources need formatting under " + shell_style() + "; this check never rewrites a file.\n" + report +
        "\nApply the declared style yourself with: shfmt --write --indent 4 --language-dialect posix <path>...");
}

fn self_test() {
    let version = shfmt_version();
    let fixtures = fs::make_temp_dir("northstar-language-packs-format");
    let malformed = path::join(fixtures, "malformed.sh");
    let control = path::join(fixtures, "control.sh");
    let malformed_body = "#!/bin/sh\nif [ \"$1\" = x ];then\n  echo   hi\nfi\n";
    let control_body = "#!/bin/sh\nif [ \"$1\" = x ]; then\n    echo hi\nfi\n";
    fs::write_file(malformed, malformed_body);
    fs::write_file(control, control_body);

    let control_result = shfmt_diff(fixtures, [control]);
    if !control_result["success"] {
        fs::remove(fixtures);
        fail("self-test: the formatted control fixture did not pass: " + str::trim(control_result["stdout"]) +
            str::trim(control_result["stderr"]));
    }
    let malformed_result = shfmt_diff(fixtures, [malformed]);
    if malformed_result["success"] {
        fs::remove(fixtures);
        fail("self-test: the malformed fixture did not fail the check");
    }
    if !str::contains(malformed_result["stdout"], "malformed.sh") {
        fs::remove(fixtures);
        fail("self-test: the failure did not report the malformed fixture");
    }
    if fs::read_file(malformed) != malformed_body || fs::read_file(control) != control_body {
        fs::remove(fixtures);
        fail("self-test: the check rewrote a fixture file");
    }
    fs::remove(fixtures);
    log(label() + "self-test: OK (" + version + "; malformed source fails, formatted control passes, neither file rewritten)");
}

let shell = shell_sources();
let rhai = rhai_sources();

if args.len() == 1 && args[0] == "self-test" {
    self_test();
} else if args.len() != 0 {
    fail("usage: format:check | format:check self-test");
} else {
    verify_coverage(repo_root, shell, rhai);
    verify_catalogues(repo_root, shell);
    let version = shfmt_version();
    check_shell(repo_root, shell, version);
    log(label() + "rhai: unsupported, no maintained Rhai formatter exists; " + rhai.len().to_string() +
        " maintained Rhai source(s) are declared and not checked");
}
