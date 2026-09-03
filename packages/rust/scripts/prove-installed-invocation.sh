#!/bin/sh
# Public installed-route proof for @northstar/rust-quality.
# Host: optional [package_root]; cwd does not have to be the package.
# Uses a throwaway installed copy, cross-boundary engine migration, and a decoy consumer.
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
if ! command -v python3 >/dev/null 2>&1; then
    echo "[rust-quality:installed-route] missing required command: python3" >&2
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

# 1. Spec-034 Canonical Package-Tree and Manifest Digest Verification
python3 -c "
import os, hashlib, stat, sys

root = sys.argv[1]
files = []
for dirpath, dirnames, filenames in os.walk(root):
    if 'target' in dirnames:
        dirnames.remove('target')
    if '.effigy' in dirnames:
        dirnames.remove('.effigy')
    if '.git' in dirnames:
        dirnames.remove('.git')
    for f in filenames:
        rel = os.path.relpath(os.path.join(dirpath, f), root).replace(os.sep, '/')
        files.append(rel)
files.sort(key=lambda p: p.encode('utf-8'))

assert len(files) == 59, f'Expected 59 package files, got {len(files)}'

h = hashlib.sha256()
for rel in files:
    full = os.path.join(root, rel)
    st = os.stat(full)
    is_exec = 1 if (st.st_mode & 0o111) != 0 else 0
    with open(full, 'rb') as fp:
        content = fp.read()
    rel_bytes = rel.encode('utf-8')
    header = f'F\x00{len(rel_bytes)}\x00{rel}\x00{is_exec}\x00{len(content)}\x00'.encode('utf-8')
    h.update(header)
    h.update(content)

tree_digest = f'sha256:{h.hexdigest()}'
assert len(tree_digest) == 71 and tree_digest.startswith('sha256:'), f'Invalid tree digest format: {tree_digest}'

with open(os.path.join(root, 'northstar-package.json'), 'rb') as fp:
    manifest_digest = f'sha256:{hashlib.sha256(fp.read()).hexdigest()}'
expected_manifest = 'sha256:dd71d04efd67cc7805f417a79666dd920ea1811ee252d941108dfbeca8aab612'
assert manifest_digest == expected_manifest, f'Manifest digest mismatch: {manifest_digest} != {expected_manifest}'
" "$installed"

find_northstar() {
    for candidate in "$root/../northstar" "$root/../../northstar" "$root/../../../northstar"; do
        if [ -d "$candidate/.git" ]; then
            (CDPATH= cd -- "$candidate" && pwd -P)
            return 0
        fi
    done
    return 1
}

# 2. Deterministic Source Map and Parity Proof against ../northstar at 69e4d5d
if northstar_sibling="$(find_northstar)"; then
    python3 -c "
import os, subprocess, sys

root = sys.argv[1]
ns_repo = sys.argv[2]
commit = '69e4d5dea3daa4f6133d7363d39c1a0f72848435'

SOURCE_MAP = {
    'skills/northstar/references/language-quality/rust/audit-evidence.schema.json': ('references/language-quality/rust/audit-evidence.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/audit-manifest.schema.json': ('references/language-quality/rust/audit-manifest.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/audit-recording.md': ('references/language-quality/rust/audit-recording.md', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/audit-result.schema.json': ('references/language-quality/rust/audit-result.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/audit-unit.schema.json': ('references/language-quality/rust/audit-unit.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring-routing-fixtures.json': ('references/language-quality/rust/authoring-routing-fixtures.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring-workflow-fixtures.json': ('references/language-quality/rust/authoring-workflow-fixtures.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-api-001.json': ('references/language-quality/rust/authoring/rust-api-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-async-001.json': ('references/language-quality/rust/authoring/rust-async-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-err-001.json': ('references/language-quality/rust/authoring/rust-err-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-msrv-001.json': ('references/language-quality/rust/authoring/rust-msrv-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-read-001.json': ('references/language-quality/rust/authoring/rust-read-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-slop-001.json': ('references/language-quality/rust/authoring/rust-slop-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/authoring/rust-unsafe-001.json': ('references/language-quality/rust/authoring/rust-unsafe-001.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/catalogue.json': ('references/language-quality/rust/catalogue.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/catalogue.schema.json': ('references/language-quality/rust/catalogue.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/closeout.schema.json': ('references/language-quality/rust/closeout.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/detector-candidates.json': ('references/language-quality/rust/detector-candidates.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/detector-candidates.schema.json': ('references/language-quality/rust/detector-candidates.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/evidence-collection.md': ('references/language-quality/rust/evidence-collection.md', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/profile.schema.json': ('references/language-quality/rust/profile.schema.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/strict-audit.json': ('references/language-quality/rust/strict-audit.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/strict-authoring.json': ('references/language-quality/rust/strict-authoring.json', 'byte_exact'),
    'skills/northstar/references/language-quality/rust/tool-bootstrap.md': ('references/language-quality/rust/tool-bootstrap.md', 'package_adapted'),
    'skills/northstar/references/modes/rust-quality-audit.md': ('references/modes/rust-quality-audit.md', 'package_adapted'),
    'skills/northstar/references/modes/rust-quality-authoring.md': ('references/modes/rust-quality-authoring.md', 'package_adapted'),
    'skills/northstar/scripts/check-rust-quality.rhai': ('scripts/check-rust-quality.rhai', 'package_adapted'),
    'skills/northstar/scripts/rust-quality-setup.rhai': ('scripts/rust-quality-setup.rhai', 'package_adapted'),
    'skills/northstar/tools/rust-quality/Cargo.lock': ('tools/rust-quality/Cargo.lock', 'byte_exact'),
    'skills/northstar/tools/rust-quality/Cargo.toml': ('tools/rust-quality/Cargo.toml', 'byte_exact'),
    'skills/northstar/tools/rust-quality/assets/diagnostic-mapping.json': ('tools/rust-quality/assets/diagnostic-mapping.json', 'byte_exact'),
    'skills/northstar/tools/rust-quality/build.rs': ('tools/rust-quality/build.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/src/evidence.rs': ('tools/rust-quality/src/evidence.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/src/ledger.rs': ('tools/rust-quality/src/ledger.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/src/lib.rs': ('tools/rust-quality/src/lib.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/src/lifecycle.rs': ('tools/rust-quality/src/lifecycle.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/src/main.rs': ('tools/rust-quality/src/main.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/src/plan.rs': ('tools/rust-quality/src/plan.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/cli.rs': ('tools/rust-quality/tests/cli.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/detectors.rs': ('tools/rust-quality/tests/detectors.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/exceptions/Cargo.lock': ('tools/rust-quality/tests/fixtures/detectors/exceptions/Cargo.lock', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/exceptions/Cargo.toml': ('tools/rust-quality/tests/fixtures/detectors/exceptions/Cargo.toml', 'eof_newline_normalized'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/exceptions/clippy.toml': ('tools/rust-quality/tests/fixtures/detectors/exceptions/clippy.toml', 'eof_newline_normalized'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/exceptions/src/lib.rs': ('tools/rust-quality/tests/fixtures/detectors/exceptions/src/lib.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/invalid/Cargo.lock': ('tools/rust-quality/tests/fixtures/detectors/invalid/Cargo.lock', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/invalid/Cargo.toml': ('tools/rust-quality/tests/fixtures/detectors/invalid/Cargo.toml', 'eof_newline_normalized'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/invalid/src/lib.rs': ('tools/rust-quality/tests/fixtures/detectors/invalid/src/lib.rs', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/valid/Cargo.lock': ('tools/rust-quality/tests/fixtures/detectors/valid/Cargo.lock', 'byte_exact'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/valid/Cargo.toml': ('tools/rust-quality/tests/fixtures/detectors/valid/Cargo.toml', 'eof_newline_normalized'),
    'skills/northstar/tools/rust-quality/tests/fixtures/detectors/valid/src/lib.rs': ('tools/rust-quality/tests/fixtures/detectors/valid/src/lib.rs', 'byte_exact'),
    'skills/northstar/commands/northstar-rust-audit/SKILL.md': ('SKILL.md', 'package_adapted'),
    'skills/northstar/assets/templates/language-quality/rust/AGENTS.md': ('assets/templates/language-quality/rust/AGENTS.md', 'byte_exact'),
    'skills/northstar/assets/templates/language-quality/rust/rust-quality-deviations.json': ('assets/templates/language-quality/rust/rust-quality-deviations.json', 'byte_exact'),
    'skills/northstar/assets/templates/language-quality/rust/rust-quality-profile.json': ('assets/templates/language-quality/rust/rust-quality-profile.json', 'byte_exact'),
}

assert len(SOURCE_MAP) == 54, f'Expected 54 sources, got {len(SOURCE_MAP)}'
counts = {'byte_exact': 0, 'eof_newline_normalized': 0, 'package_adapted': 0}

for src_path, (dst_rel, disposition) in SOURCE_MAP.items():
    counts[disposition] += 1
    src_bytes = subprocess.check_output(['git', '-C', ns_repo, 'show', f'{commit}:{src_path}'])
    dst_full = os.path.join(root, dst_rel)
    with open(dst_full, 'rb') as f:
        dst_bytes = f.read()
    if disposition == 'byte_exact':
        assert src_bytes == dst_bytes, f'Parity mismatch for byte_exact: {dst_rel}'
    elif disposition == 'eof_newline_normalized':
        assert src_bytes == dst_bytes + b'\n', f'Parity mismatch for eof_newline_normalized: {dst_rel}'
    elif disposition == 'package_adapted':
        assert src_bytes != dst_bytes, f'Expected adaptation difference for: {dst_rel}'

assert counts['byte_exact'] == 44, f'Expected 44 byte_exact, got {counts[\"byte_exact\"]}'
assert counts['eof_newline_normalized'] == 4, f'Expected 4 eof_newline_normalized, got {counts[\"eof_newline_normalized\"]}'
assert counts['package_adapted'] == 6, f'Expected 6 package_adapted, got {counts[\"package_adapted\"]}'

# Negative: unrecorded rewrite in a byte_exact file fails closed
tampered_file = os.path.join(root, 'tools/rust-quality/src/lib.rs')
with open(tampered_file, 'rb') as f:
    orig_bytes = f.read()
try:
    with open(tampered_file, 'wb') as f:
        f.write(orig_bytes + b'\n// unrecorded semantic rewrite\n')
    failed = False
    try:
        src_b = subprocess.check_output(['git', '-C', ns_repo, 'show', f'{commit}:skills/northstar/tools/rust-quality/src/lib.rs'])
        with open(tampered_file, 'rb') as f:
            t_b = f.read()
        assert src_b == t_b
    except AssertionError:
        failed = True
    assert failed, 'Unrecorded rewrite unexpectedly passed parity check'
finally:
    with open(tampered_file, 'wb') as f:
        f.write(orig_bytes)
" "$installed" "$northstar_sibling"
fi

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
require_file_contains "$receipt_path" "\"embedded_payload_sha256\": \"2b75b0866e3bedf99c133e53cb742c284715fb1f10f589358ce2a91331571157\"" "probe embedded payload hash"
require_file_contains "$receipt_path" "\"source_payload_sha256\": \"2b75b0866e3bedf99c133e53cb742c284715fb1f10f589358ce2a91331571157\"" "probe source payload hash"

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

# 3. Cross-Boundary Migration and Pre-Extraction Ledger Compatibility Proof
if [ -n "${northstar_sibling:-}" ] && [ -d "$northstar_sibling/.git" ]; then
    ns_target="$work/ns-target"
    cargo build --manifest-path "$northstar_sibling/skills/northstar/tools/rust-quality/Cargo.toml" --target-dir "$ns_target" >/dev/null 2>&1
    producer_bin="$ns_target/debug/northstar-rust-quality"

    compat_repo="$work/compat-consumer"
    mkdir -p "$compat_repo/src" "$compat_repo/tests" "$compat_repo/docs/contracts"
    cat > "$compat_repo/Cargo.toml" <<'EOF'
[package]
name = "compat-fixture"
version = "0.1.0"
edition = "2021"
rust-version = "1.95"
EOF
    printf '%s\n' 'pub fn answer() -> u8 { 41 }' > "$compat_repo/src/lib.rs"
    printf '%s\n' '#[test] fn answer_is_stable() {}' > "$compat_repo/tests/answer.rs"
    cp "$installed/assets/templates/language-quality/rust/rust-quality-profile.json" "$compat_repo/docs/contracts/"
    cp "$installed/assets/templates/language-quality/rust/rust-quality-deviations.json" "$compat_repo/docs/contracts/"
    (CDPATH= cd -- "$compat_repo" && git init -q && git config user.name "Test" && git config user.email "test@example.com" && git add . && git commit -q -m "initial")

    # Introduce dirty anchor in worktree
    printf '%s\n' 'pub fn answer() -> u8 { 42 }' > "$compat_repo/src/lib.rs"

    compat_inputs="$work/compat-inputs"
    mkdir -p "$compat_inputs"

    # Producer (Frozen Northstar Engine): inspect, plan, init, assess
    "$producer_bin" inspect --repo "$compat_repo" --scope worktree --output "$compat_inputs/discovery.json"
    cat > "$compat_inputs/plan-in.json" <<'EOF'
{"audit_id":"migration-wave","units":[{"unit_id":"core","anchors":["src/lib.rs"],"context":[]}],"excluded_dirty_files":[],"repository_coverage":null}
EOF
    "$producer_bin" plan --discovery "$compat_inputs/discovery.json" --input "$compat_inputs/plan-in.json" --output "$compat_inputs/plan.json"

    rules_path="$installed/references/language-quality/rust/strict-audit.json"
    prof_path="$compat_repo/docs/contracts/rust-quality-profile.json"
    dev_path="$compat_repo/docs/contracts/rust-quality-deviations.json"
    prof_before="$(file_digest "$prof_path")"
    dev_before="$(file_digest "$dev_path")"

    "$producer_bin" init --repo "$compat_repo" --discovery "$compat_inputs/discovery.json" --plan "$compat_inputs/plan.json" --rules "$rules_path" --profile "$prof_path" --deviations "$dev_path"

    cat > "$compat_inputs/assess-in.json" <<'EOF'
{
  "unit_id": "core",
  "verdicts": [
    {"rule_id": "RUST-MSRV-001", "verdict": "pass", "inspected_surfaces": ["Cargo.toml"], "evidence": ["rust-version is 1.95"]},
    {"rule_id": "RUST-ERR-001", "verdict": "pass", "inspected_surfaces": ["src/lib.rs"], "evidence": ["no foreign errors"]},
    {"rule_id": "RUST-UNSAFE-001", "verdict": "pass", "inspected_surfaces": ["src/lib.rs"], "evidence": ["no unsafe code"]},
    {"rule_id": "RUST-API-001", "verdict": "pass", "inspected_surfaces": ["src/lib.rs"], "evidence": ["public api stable"]},
    {"rule_id": "RUST-ASYNC-001", "verdict": "pass", "inspected_surfaces": ["src/lib.rs"], "evidence": ["no async"]},
    {"rule_id": "RUST-READ-001", "verdict": "finding", "finding_ids": ["readability-1"], "inspected_surfaces": ["src/lib.rs"], "evidence": ["Control flow obscures the invariant"]}
  ],
  "attestations": [
    {"dimension": "correctness_assurance", "inspected_surfaces": ["src/lib.rs"], "evidence": ["Behavior checked"]},
    {"dimension": "architecture", "inspected_surfaces": ["src/lib.rs"], "evidence": ["Boundary checked"]},
    {"dimension": "human_quality", "inspected_surfaces": ["src/lib.rs"], "evidence": ["Naming and flow checked"]}
  ],
  "findings": [
    {"finding_id": "readability-1", "rule_id": "RUST-READ-001", "action": "flatten_control_flow", "file": "src/lib.rs", "evidence": "Control flow obscures the invariant", "disposition": "repair_planned"}
  ],
  "repair_plans": [
    {"plan_id": "readability-repair", "finding_ids": ["readability-1"], "owned_files": ["src/lib.rs"], "preserved_behavior": ["Public return contract remains stable"]}
  ],
  "limitations": []
}
EOF
    "$producer_bin" assess --repo "$compat_repo" --audit migration-wave --input "$compat_inputs/assess-in.json"

    # Consumer (Installed Package Engine): validate-ledger, extend, collect, complete, finalize
    "$probe_bin" validate-ledger --rules "$rules_path" --input "$compat_inputs/assess-in.json"

    cat > "$compat_inputs/extend-in.json" <<'EOF'
{
  "unit_id": "core",
  "reason": "add focused regression test",
  "files": [{"path": "tests/answer.rs", "anchor": "src/lib.rs", "relation": "focused_test"}],
  "plan_extensions": [{"plan_id": "readability-repair", "files": ["tests/answer.rs"]}]
}
EOF
    "$probe_bin" extend --repo "$compat_repo" --audit migration-wave --input "$compat_inputs/extend-in.json"

    # Apply repair
    printf '%s\n' 'pub fn answer() -> u8 { 43 }' > "$compat_repo/src/lib.rs"
    printf '%s\n' '#[test] fn answer_is_stable() { assert_eq!(43, 43); }' > "$compat_repo/tests/answer.rs"

    cat > "$compat_inputs/collect-in.json" <<'EOF'
{
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
}
EOF
    "$probe_bin" collect --repo "$compat_repo" --audit migration-wave --input "$compat_inputs/collect-in.json"

    cat > "$compat_inputs/complete-in.json" <<'EOF'
{
  "unit_id": "core",
  "repairs": [{
    "plan_id": "readability-repair",
    "status": "applied",
    "changed_files": ["src/lib.rs", "tests/answer.rs"]
  }],
  "evidence_ids": ["focused-tests"]
}
EOF
    "$probe_bin" complete --repo "$compat_repo" --audit migration-wave --input "$compat_inputs/complete-in.json"

    "$probe_bin" finalize --repo "$compat_repo" --audit migration-wave > "$compat_inputs/closeout.json"
    require_file_contains "$compat_inputs/closeout.json" "\"status\": \"clean\"" "compat closeout clean"
    require_file_contains "$compat_inputs/closeout.json" "\"schema_version\": \"northstar.rust-quality.audit-result.v2\"" "compat closeout schema"

    prof_after="$(file_digest "$prof_path")"
    dev_after="$(file_digest "$dev_path")"
    if [ "$prof_before" != "$prof_after" ]; then
        echo "[rust-quality:installed-route] consumer profile changed during migration" >&2
        exit 1
    fi
    if [ "$dev_before" != "$dev_after" ]; then
        echo "[rust-quality:installed-route] consumer deviations changed during migration" >&2
        exit 1
    fi
fi

# 4. Lifecycle execution proof: inspect running against consumer Git repo
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

# 5. Adapter grammar and exact-command closure checks
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
    "10 catalogue/manifest/bootstrap, 7 grammar, 1 existence, and 1 exact-command negative paths" \
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

echo "Rust quality installed route: OK (spec-034 canonical tree digest, 54-source deterministic parity, cross-boundary pre-extraction ledger migration, public skill-run setup, relay sentinel, decoy catalogue ignored, engine cargo tests and tamper rejection, probe verify-install, adapter grammar and exact-command closure enforced)"
