#!/bin/sh
# Public installed-route proof for @northstar/rust-quality.
# Host: optional [package_root]; cwd does not have to be the package.
# Uses a throwaway installed copy and a decoy consumer with a northstar catalogue.
set -eu

root="${1:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)}"
root="$(CDPATH= cd -- "$root" && pwd -P)"
if [ ! -f "$root/northstar-package.json" ] || [ ! -f "$root/effigy.toml" ]; then
    echo "[rust-quality:installed-route] missing package at $root" >&2
    exit 1
fi
if ! command -v effigy >/dev/null 2>&1; then
    echo "[rust-quality:installed-route] missing required command: effigy" >&2
    exit 1
fi
if ! command -v cargo >/dev/null 2>&1; then
    echo "[rust-quality:installed-route] missing required command: cargo" >&2
    exit 1
fi
if ! command -v git >/dev/null 2>&1; then
    echo "[rust-quality:installed-route] missing required command: git" >&2
    exit 1
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/rq-installed-route.XXXXXX")"
trap 'rm -rf "$work"' EXIT
installed="$work/installed"
consumer="$work/consumer"
inputs="$work/inputs"
transcripts="$work/transcripts"
mkdir -p "$installed" "$consumer/src" "$consumer/skills/northstar/references/language-quality/rust" \
    "$consumer/skills/northstar/assets/templates/language-quality/rust" "$inputs" "$transcripts"

copy_package() {
    # POSIX tree copy that keeps the executable bit and skips runtime receipts.
    dest="$1"
    (CDPATH= cd -- "$root" && find . -type f ! -path './.effigy/*' ! -path './tools/rust-quality/target/*' | sort | while IFS= read -r rel; do
        target="$dest/$rel"
        mkdir -p "$(dirname "$target")"
        cp "$rel" "$target"
    done)
    chmod +x "$dest/scripts/self-check.sh" "$dest/scripts/prove-installed-invocation.sh"
}

file_digest() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | awk '{print $1}'
    else
        shasum -a 256 "$1" | awk '{print $1}'
    fi
}

tree_listing() {
    (CDPATH= cd -- "$1" && find . -type f ! -path './.effigy/*' ! -path './.git/*' ! -path './tools/rust-quality/target/*' | sort | while IFS= read -r rel; do
        printf '%s  %s\n' "$(file_digest "$rel")" "$rel"
    done)
}

require_file_contains() {
    file="$1"
    needle="$2"
    label="$3"
    if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
        echo "[rust-quality:installed-route] $label: missing '$needle' in $file" >&2
        cat "$file" >&2
        exit 1
    fi
}

require_file_lacks() {
    file="$1"
    needle="$2"
    label="$3"
    if grep -F "$needle" "$file" >/dev/null 2>&1; then
        echo "[rust-quality:installed-route] $label: unexpectedly found '$needle' in $file" >&2
        cat "$file" >&2
        exit 1
    fi
}

run_capture() {
    out="$1"
    shift
    set +e
    "$@" >"$out" 2>&1
    status=$?
    set -e
    return "$status"
}

copy_package "$installed"
installed="$(CDPATH= cd -- "$installed" && pwd -P)"
before="$(tree_listing "$installed")"

cat > "$consumer/effigy.toml" <<'EOF'
[manifest]
minimum_effigy_version = "0.12.0"

[catalog]
alias = "northstar"

[tasks]
"rust-quality:setup" = "echo DECOY-NORTHSTAR-SETUP-RAN"
qa = "true"
EOF

cat > "$consumer/Cargo.toml" <<'EOF'
[package]
name = "decoy-consumer"
version = "0.1.0"
edition = "2021"
rust-version = "1.95"
EOF

cat > "$consumer/src/lib.rs" <<'EOF'
pub fn add(a: i32, b: i32) -> i32 {
    a + b
}
EOF

printf '%s\n' 'DECOY ACTIVATION FROM CONSUMER ROOT' \
    > "$consumer/skills/northstar/assets/templates/language-quality/rust/AGENTS.md"
printf '%s\n' '{"schema_version":"1.0.0","language":"rust","rules":[{"id":"DECOY"}]}' \
    > "$consumer/skills/northstar/references/language-quality/rust/catalogue.json"
consumer="$(CDPATH= cd -- "$consumer" && pwd -P)"

# Initialize git repository in consumer
(CDPATH= cd -- "$consumer" && git init -q && git config user.name "Test" && git config user.email "test@example.com" && git add . && git commit -q -m "initial")

# Negative: old documented command against the installed package.
if run_capture "$transcripts/old-installed.txt" \
    effigy --repo "$installed" northstar/rust-quality:setup apply "$consumer" .
then
    echo "[rust-quality:installed-route] old northstar/ prefix unexpectedly succeeded against the installed package" >&2
    cat "$transcripts/old-installed.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/old-installed.txt" \
    "task catalog prefix \`northstar\` not found" \
    "old installed command"

# Negative: the same prefix against the decoy consumer runs the decoy catalogue.
if ! run_capture "$transcripts/old-decoy.txt" \
    effigy --repo "$consumer" northstar/rust-quality:setup apply "$consumer" .
then
    echo "[rust-quality:installed-route] decoy northstar catalogue did not win the old prefix" >&2
    cat "$transcripts/old-decoy.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/old-decoy.txt" "DECOY-NORTHSTAR-SETUP-RAN" "decoy prefix trap"
if [ -f "$consumer/AGENTS.md" ]; then
    echo "[rust-quality:installed-route] decoy prefix wrote consumer AGENTS.md" >&2
    exit 1
fi

# Negative: relay sentinel with no operation still hits the usage guard.
if run_capture "$transcripts/empty-relay.json" \
    effigy skill run --path "$installed" rust-quality:setup --repo "$consumer" --json --
then
    echo "[rust-quality:installed-route] empty relay unexpectedly succeeded" >&2
    cat "$transcripts/empty-relay.json" >&2
    exit 1
fi
require_file_contains "$transcripts/empty-relay.json" \
    '\"--\"' \
    "empty relay args"
require_file_contains "$transcripts/empty-relay.json" \
    "usage: rust-quality:setup" \
    "empty relay usage"

# Positive: installed setup through the public surface, consumer supplied separately.
if ! run_capture "$transcripts/setup-apply.json" \
    effigy skill run --path "$installed" rust-quality:setup --repo "$consumer" --json -- apply "$consumer" .
then
    echo "[rust-quality:installed-route] installed setup apply failed" >&2
    cat "$transcripts/setup-apply.json" >&2
    exit 1
fi
require_file_contains "$transcripts/setup-apply.json" "\"catalog_alias\": \"rust-quality\"" "setup catalog alias"
require_file_contains "$transcripts/setup-apply.json" "\"root\": \"$installed\"" "setup source root"
require_file_contains "$transcripts/setup-apply.json" "\"root\": \"$consumer\"" "setup target root"
require_file_contains "$transcripts/setup-apply.json" \
    '\"--\",\"apply\"' \
    "setup relay args"
require_file_lacks "$transcripts/setup-apply.json" "DECOY-NORTHSTAR-SETUP-RAN" "setup decoy task"
require_file_contains "$consumer/AGENTS.md" "northstar:rust-quality:start" "setup activation"
require_file_lacks "$consumer/AGENTS.md" "DECOY ACTIVATION FROM CONSUMER ROOT" "setup decoy template"
if [ ! -f "$consumer/docs/contracts/rust-quality-profile.json" ]; then
    echo "[rust-quality:installed-route] setup did not write the consumer profile" >&2
    exit 1
fi
if [ ! -f "$consumer/docs/contracts/rust-quality-deviations.json" ]; then
    echo "[rust-quality:installed-route] setup did not write the consumer deviations" >&2
    exit 1
fi
if [ -f "$installed/AGENTS.md" ] || [ -d "$installed/docs" ] || [ -d "$installed/.effigy" ]; then
    echo "[rust-quality:installed-route] setup wrote into the installed package root" >&2
    exit 1
fi

after="$(tree_listing "$installed")"
if [ "$before" != "$after" ]; then
    echo "[rust-quality:installed-route] installed package tree changed during setup invocation" >&2
    printf '%s\n' "$before" > "$transcripts/before.txt"
    printf '%s\n' "$after" > "$transcripts/after.txt"
    diff -u "$transcripts/before.txt" "$transcripts/after.txt" >&2 || true
    exit 1
fi

# Cargo engine tests: unit and integration tests
if ! run_capture "$transcripts/cargo-test.txt" \
    cargo test --manifest-path "$installed/tools/rust-quality/Cargo.toml"
then
    echo "[rust-quality:installed-route] cargo test failed" >&2
    cat "$transcripts/cargo-test.txt" >&2
    exit 1
fi

# Cargo engine install and probe verification
probe_root="$work/cache/probe"
if ! run_capture "$transcripts/cargo-install.txt" \
    cargo install --locked --path "$installed/tools/rust-quality" --root "$probe_root"
then
    echo "[rust-quality:installed-route] cargo install failed" >&2
    cat "$transcripts/cargo-install.txt" >&2
    exit 1
fi

probe_bin="$probe_root/bin/northstar-rust-quality"
if [ ! -x "$probe_bin" ]; then
    echo "[rust-quality:installed-route] probe binary missing: $probe_bin" >&2
    exit 1
fi

receipt_path="$work/cache/probe-receipt.json"
if ! run_capture "$transcripts/probe-verify.txt" \
    "$probe_bin" verify-install --source-root "$installed/tools/rust-quality" --receipt "$receipt_path"
then
    echo "[rust-quality:installed-route] probe verify-install failed" >&2
    cat "$transcripts/probe-verify.txt" >&2
    exit 1
fi
require_file_contains "$receipt_path" "\"current\": true" "probe receipt current"
require_file_contains "$receipt_path" "\"schema_version\": \"northstar.rust-quality.install.v1\"" "probe receipt schema"

# Tamper negatives: mutating source must cause verify-install to fail closed
tampered="$work/tampered-tool"
cp -R "$installed/tools/rust-quality" "$tampered"

# Tamper 1: modify src/lib.rs
printf '\n// tamper\n' >> "$tampered/src/lib.rs"
if run_capture "$transcripts/tamper-src.txt" \
    "$probe_bin" verify-install --source-root "$tampered" --receipt "$work/cache/tamper-src-receipt.json"
then
    echo "[rust-quality:installed-route] tampered src unexpectedly passed verify-install" >&2
    cat "$transcripts/tamper-src.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/tamper-src.txt" "install.payload_mismatch" "tampered src rejection"

# Tamper 2: restore src/lib.rs, modify Cargo.toml
git checkout "$tampered/src/lib.rs" 2>/dev/null || cp "$installed/tools/rust-quality/src/lib.rs" "$tampered/src/lib.rs"
printf '\n# tamper\n' >> "$tampered/Cargo.toml"
if run_capture "$transcripts/tamper-manifest.txt" \
    "$probe_bin" verify-install --source-root "$tampered" --receipt "$work/cache/tamper-manifest-receipt.json"
then
    echo "[rust-quality:installed-route] tampered Cargo.toml unexpectedly passed verify-install" >&2
    cat "$transcripts/tamper-manifest.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/tamper-manifest.txt" "install.payload_mismatch" "tampered manifest rejection"

# Tamper 3: restore Cargo.toml, modify diagnostic mapping
cp "$installed/tools/rust-quality/Cargo.toml" "$tampered/Cargo.toml"
printf ' ' >> "$tampered/assets/diagnostic-mapping.json"
if run_capture "$transcripts/tamper-mapping.txt" \
    "$probe_bin" verify-install --source-root "$tampered" --receipt "$work/cache/tamper-mapping-receipt.json"
then
    echo "[rust-quality:installed-route] tampered diagnostic-mapping unexpectedly passed verify-install" >&2
    cat "$transcripts/tamper-mapping.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/tamper-mapping.txt" "install.payload_mismatch" "tampered mapping rejection"

# Lifecycle execution proof: inspect running against consumer Git repo
# Make a change in consumer so worktree scope finds a dirty Rust anchor
printf '\npub fn multiply(a: i32, b: i32) -> i32 { a * b }\n' >> "$consumer/src/lib.rs"
discovery_path="$work/discovery.json"
if ! run_capture "$transcripts/inspect.txt" \
    "$probe_bin" inspect --repo "$consumer" --scope worktree --output "$discovery_path"
then
    echo "[rust-quality:installed-route] engine inspect failed" >&2
    cat "$transcripts/inspect.txt" >&2
    exit 1
fi
require_file_contains "$discovery_path" "\"schema_version\": \"northstar.rust-quality.discovery.v1\"" "discovery schema"
require_file_contains "$discovery_path" "\"scope\": \"worktree\"" "discovery scope"
require_file_contains "$discovery_path" "\"path\": \"src/lib.rs\"" "discovery anchor"

# Adapter grammar closure: package QA passes on a materialized installed copy
# and fails closed on any corrupted adapter that adds extra authority.
staged="$work/staged"
copy_package "$staged"
if ! run_capture "$transcripts/staged-qa.txt" \
    effigy skill run --path "$staged" check:rust-quality --repo "$consumer"
then
    echo "[rust-quality:installed-route] installed-copy package QA failed" >&2
    cat "$transcripts/staged-qa.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/staged-qa.txt" \
    "9 catalogue/manifest, 7 grammar, 1 existence, and 1 exact-command negative paths" \
    "installed-copy adapter closure check"

expect_adapter_rejection() {
    copy_root="$1"
    label="$2"
    expected="$3"
    transcript="$transcripts/$label.txt"
    if run_capture "$transcript" \
        effigy skill run --path "$copy_root" check:rust-quality --repo "$consumer"
    then
        echo "[rust-quality:installed-route] corrupted package '$label' unexpectedly passed package QA" >&2
        cat "$transcript" >&2
        exit 1
    fi
    require_file_contains "$transcript" \
        "$expected" \
        "$label"
}

grammar_rejection="adapter is not the declared thin-adapter grammar form"

broken="$work/broken"
unquoted="$work/unquoted"
external="$work/external"
spaced="$work/spaced"
evil="$work/evil"

copy_package "$broken"
sed 's|references/modes/rust-quality-audit.md|references/router.md|' \
    "$broken/SKILL.md" > "$broken/SKILL.md.next"
mv "$broken/SKILL.md.next" "$broken/SKILL.md"
expect_adapter_rejection "$broken" "rewritten-entrypoint" "$grammar_rejection"

copy_package "$unquoted"
printf '%s\n' "Load references/router.md as an extra authority." >> "$unquoted/SKILL.md"
expect_adapter_rejection "$unquoted" "unquoted-extra-load" "$grammar_rejection"

copy_package "$external"
printf '%s\n' "Load https://example.com/router.md as an extra authority." >> "$external/SKILL.md"
expect_adapter_rejection "$external" "external-url-extra-load" "$grammar_rejection"

copy_package "$spaced"
printf '%s\n' "Load references/missing router.md as an extra authority." >> "$spaced/SKILL.md"
expect_adapter_rejection "$spaced" "spaced-extra-load" "$grammar_rejection"

copy_package "$evil"
sed 's/\$northstar-rust-audit/\$northstar-rust-audit-evil/' \
    "$evil/agents/openai.yaml" > "$evil/agents/openai.yaml.next"
mv "$evil/agents/openai.yaml.next" "$evil/agents/openai.yaml"
expect_adapter_rejection "$evil" "suffixed-command-policy" \
    "agent policy is not the declared exact-command form"

echo "Rust quality installed route: OK (public skill-run setup, relay sentinel, decoy catalogue ignored, engine cargo tests and tamper rejection, probe verify-install, adapter grammar and exact-command closure enforced)"
