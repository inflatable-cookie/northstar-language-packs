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

# 1. Spec-034 Canonical Package-Tree and Manifest Digest Verification (with mutation negatives)
python3 -c "
import os, hashlib, stat, sys, re

root = sys.argv[1]

def compute_spec_034_tree_digest(pkg_root):
    files = []
    for dirpath, dirnames, filenames in os.walk(pkg_root):
        if 'target' in dirnames:
            dirnames.remove('target')
        if '.effigy' in dirnames:
            dirnames.remove('.effigy')
        if '.git' in dirnames:
            dirnames.remove('.git')
        for f in filenames:
            rel = os.path.relpath(os.path.join(dirpath, f), pkg_root).replace(os.sep, '/')
            files.append(rel)
    files.sort(key=lambda p: p.encode('utf-8'))

    assert len(files) == 59, f'Expected 59 package files, got {len(files)}'

    h = hashlib.sha256()
    for rel in files:
        full = os.path.join(pkg_root, rel)
        st = os.stat(full)
        is_exec = 1 if (st.st_mode & 0o111) != 0 else 0
        with open(full, 'rb') as fp:
            content = fp.read()
        if rel == 'scripts/prove-installed-invocation.sh':
            text = content.decode('utf-8')
            text = re.sub(r\"expected_tree = '[^']*'\", \"expected_tree = '__CANONICAL_TREE_PLACEHOLDER__'\", text)
            content = text.encode('utf-8')
        rel_bytes = rel.encode('utf-8')
        header = f'F\x00{len(rel_bytes)}\x00{rel}\x00{is_exec}\x00{len(content)}\x00'.encode('utf-8')
        h.update(header)
        h.update(content)

    return f'sha256:{h.hexdigest()}'

tree_digest = compute_spec_034_tree_digest(root)
expected_tree = 'sha256:c8b980bb05c6e96ffcef4c8e1efb515f67241ca5dc9657c60d5ae2579cb226ef'
assert tree_digest == expected_tree, f'Spec-034 tree digest mismatch: {tree_digest} != {expected_tree}'

# Mutation negative 1: mutating an existing package file causes tree digest mismatch
tampered_tree_file = os.path.join(root, 'references/language-quality/rust/catalogue.json')
with open(tampered_tree_file, 'rb') as f:
    orig_c = f.read()
try:
    with open(tampered_tree_file, 'wb') as f:
        f.write(orig_c + b' ')
    tampered_digest = compute_spec_034_tree_digest(root)
    assert tampered_digest != expected_tree, 'Tampered tree unexpectedly matched expected digest'
finally:
    with open(tampered_tree_file, 'wb') as f:
        f.write(orig_c)

# Mutation negative 2: adding a stray file fails file count check
stray_file = os.path.join(root, 'stray.txt')
try:
    with open(stray_file, 'wb') as f:
        f.write(b'stray')
    stray_failed = False
    try:
        compute_spec_034_tree_digest(root)
    except AssertionError:
        stray_failed = True
    assert stray_failed, 'Stray file in package tree unexpectedly passed count check'
finally:
    if os.path.exists(stray_file):
        os.remove(stray_file)

with open(os.path.join(root, 'northstar-package.json'), 'rb') as fp:
    manifest_digest = f'sha256:{hashlib.sha256(fp.read()).hexdigest()}'
expected_manifest = 'sha256:dd71d04efd67cc7805f417a79666dd920ea1811ee252d941108dfbeca8aab612'
assert manifest_digest == expected_manifest, f'Manifest digest mismatch: {manifest_digest} != {expected_manifest}'
" "$installed"

find_northstar() {
    for candidate in "$root/../northstar" "$root/../../northstar" "$root/../../../northstar"; do
        if [ -d "$candidate/.git" ] && git -C "$candidate" rev-parse --verify 69e4d5dea3daa4f6133d7363d39c1a0f72848435 >/dev/null 2>&1; then
            (CDPATH= cd -- "$candidate" && pwd -P)
            return 0
        fi
    done
    return 1
}

# 2. Mandatory Northstar Sibling Resolution & Verification
if ! northstar_sibling="$(find_northstar)"; then
    echo "[rust-quality:installed-route] mandatory Northstar sibling repository (with commit 69e4d5dea3daa4f6133d7363d39c1a0f72848435) not found" >&2
    exit 1
fi

# 3. Deterministic 54-Source Map and Parity Proof against ../northstar at 69e4d5d
python3 -c "
import os, subprocess, hashlib, sys

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

ADAPTED_EXPECTED = {
    'SKILL.md': 'sha256:83afd4b0c0d776753ea47affa164d7d3efa95dfa33925c53b3b379b9401d982c',
    'references/language-quality/rust/tool-bootstrap.md': 'sha256:9df70a6e2c8c304abc36cfdf2b349d3b933d36756e5150febc7a056c6ccacfda',
    'references/modes/rust-quality-audit.md': 'sha256:cab6d0fcd4f84efbe4c4cf5e6610da3543e729df24ba7083aee82437c80ae4ab',
    'references/modes/rust-quality-authoring.md': 'sha256:42bf6d4f235c5fbb08037907417c4fc5811a9446c13c8f7bb73c7f0585cf6a36',
    'scripts/check-rust-quality.rhai': 'sha256:3aebabc4af6e4d9e756a73acfa59c58ce7592b105ad7c4cc234280793b588a09',
    'scripts/rust-quality-setup.rhai': 'sha256:21d6ed1197252b268ac1b966a085b4ce043faf49137e265b2830486e040bad9a',
}

assert len(SOURCE_MAP) == 54, f'Expected 54 sources, got {len(SOURCE_MAP)}'
counts = {'byte_exact': 0, 'eof_newline_normalized': 0, 'package_adapted': 0}

def verify_source_parity(pkg_root):
    for src_path, (dst_rel, disposition) in SOURCE_MAP.items():
        counts[disposition] += 1
        src_bytes = subprocess.check_output(['git', '-C', ns_repo, 'show', f'{commit}:{src_path}'])
        dst_full = os.path.join(pkg_root, dst_rel)
        with open(dst_full, 'rb') as f:
            dst_bytes = f.read()
        if disposition == 'byte_exact':
            assert src_bytes == dst_bytes, f'Parity mismatch for byte_exact: {dst_rel}'
        elif disposition == 'eof_newline_normalized':
            assert src_bytes == dst_bytes + b'\n', f'Parity mismatch for eof_newline_normalized: {dst_rel}'
        elif disposition == 'package_adapted':
            assert src_bytes != dst_bytes, f'Expected adaptation difference for: {dst_rel}'
            dst_sha = f'sha256:{hashlib.sha256(dst_bytes).hexdigest()}'
            expected_sha = ADAPTED_EXPECTED[dst_rel]
            assert dst_sha == expected_sha, f'Adapted file digest mismatch for {dst_rel}: {dst_sha} != {expected_sha}'

verify_source_parity(root)

assert counts['byte_exact'] == 44, f'Expected 44 byte_exact, got {counts[\"byte_exact\"]}'
assert counts['eof_newline_normalized'] == 4, f'Expected 4 eof_newline_normalized, got {counts[\"eof_newline_normalized\"]}'
assert counts['package_adapted'] == 6, f'Expected 6 package_adapted, got {counts[\"package_adapted\"]}'

# Negative 1: unrecorded rewrite in a byte_exact file fails closed
tampered_byte_exact = os.path.join(root, 'tools/rust-quality/src/lib.rs')
with open(tampered_byte_exact, 'rb') as f:
    orig_b = f.read()
try:
    with open(tampered_byte_exact, 'wb') as f:
        f.write(orig_b + b'\n// unrecorded semantic rewrite\n')
    failed = False
    try:
        verify_source_parity(root)
    except AssertionError:
        failed = True
    assert failed, 'Unrecorded rewrite in byte_exact unexpectedly passed parity check'
finally:
    with open(tampered_byte_exact, 'wb') as f:
        f.write(orig_b)

# Negative 2: unrecorded semantic drift in a package_adapted file fails closed
tampered_adapted = os.path.join(root, 'references/modes/rust-quality-authoring.md')
with open(tampered_adapted, 'rb') as f:
    orig_a = f.read()
try:
    with open(tampered_adapted, 'wb') as f:
        f.write(orig_a + b'\nArbitrary unrecorded semantic drift for review counterexample.\n')
    failed = False
    try:
        verify_source_parity(root)
    except AssertionError:
        failed = True
    assert failed, 'Unrecorded semantic drift in package_adapted unexpectedly passed parity check'
finally:
    with open(tampered_adapted, 'wb') as f:
        f.write(orig_a)
" "$installed" "$northstar_sibling"

# 4. Materialize and Build Frozen Producer Engine strictly from commit 69e4d5d
producer_src="$work/producer-src"
mkdir -p "$producer_src"
git -C "$northstar_sibling" archive "69e4d5dea3daa4f6133d7363d39c1a0f72848435" skills/northstar/tools/rust-quality | tar -x -C "$producer_src" --strip-components=3

# Verify extracted producer inventory & listing digest
python3 -c "
import os, hashlib, sys

producer_root = sys.argv[1]
files = []
for dirpath, dirnames, filenames in os.walk(producer_root):
    if 'target' in dirnames:
        dirnames.remove('target')
    for f in filenames:
        rel = os.path.relpath(os.path.join(dirpath, f), producer_root).replace(os.sep, '/')
        files.append(rel)
files.sort(key=lambda p: p.encode('utf-8'))

assert len(files) == 22, f'Expected 22 producer engine files, got {len(files)}'

lines = []
for rel in files:
    full = os.path.join(producer_root, rel)
    with open(full, 'rb') as fp:
        lines.append(f'{hashlib.sha256(fp.read()).hexdigest()}  {rel}')
listing = '\n'.join(lines) + '\n'
listing_digest = 'sha256:' + hashlib.sha256(listing.encode('utf-8')).hexdigest()
expected_listing = 'sha256:b01c291c32813c2f3240d18c520c5e78cbd5a9935056cad9ce8a5d819e391491'
assert listing_digest == expected_listing, f'Producer listing digest mismatch: {listing_digest} != {expected_listing}'
" "$producer_src/rust-quality"

# Mismatched sibling / commit counterexample: non-existent/tampered commit fails extraction
if git -C "$northstar_sibling" archive "0000000000000000000000000000000000000000" skills/northstar/tools/rust-quality >/dev/null 2>&1; then
    echo "[rust-quality:installed-route] extraction from invalid commit unexpectedly succeeded" >&2
    exit 1
fi

ns_target="$work/ns-target"
cargo build --manifest-path "$producer_src/rust-quality/Cargo.toml" --target-dir "$ns_target" >/dev/null 2>&1
producer_bin="$ns_target/debug/northstar-rust-quality"

# 5. Cross-Boundary Migration and Pre-Extraction Ledger Compatibility Proof
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

# Producer (Frozen Northstar Engine built from 69e4d5d): inspect, plan, init, assess
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
probe_target="$work/probe-target"
cargo install --locked --offline --path "$installed/tools/rust-quality" --root "$probe_target" >/dev/null 2>&1
probe_bin="$probe_target/bin/northstar-rust-quality"

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

# 6. Decoy Consumer and Installed Setup Verification
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
    echo "[rust-quality:installed-route] setup mutated the installed package root" >&2
    exit 1
fi

# Ensure setup did not mutate the installed package directory
after="$(tree_listing "$installed")"
if [ "$before" != "$after" ]; then
    echo "[rust-quality:installed-route] installed package tree changed during setup" >&2
    exit 1
fi

# 7. Cargo Engine Suite and Tamper Negatives
if ! run_capture "$transcripts/cargo-test.txt" \
    cargo test --manifest-path "$installed/tools/rust-quality/Cargo.toml"
then
    echo "[rust-quality:installed-route] cargo test failed" >&2
    cat "$transcripts/cargo-test.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/cargo-test.txt" "4 passed" "unit test count"
require_file_contains "$transcripts/cargo-test.txt" "21 passed" "cli test count"
require_file_contains "$transcripts/cargo-test.txt" "2 passed" "detectors test count"

# Probe binary installation and source verification
receipt_path="$work/cache/receipt.json"
mkdir -p "$work/cache"
if ! run_capture "$transcripts/verify-install.txt" \
    "$probe_bin" verify-install --source-root "$installed/tools/rust-quality" --receipt "$receipt_path"
then
    echo "[rust-quality:installed-route] verify-install failed" >&2
    cat "$transcripts/verify-install.txt" >&2
    exit 1
fi
require_file_contains "$receipt_path" "\"current\": true" "probe receipt current"
require_file_contains "$receipt_path" "\"schema_version\": \"northstar.rust-quality.install.v1\"" "probe receipt schema"
require_file_contains "$receipt_path" "\"embedded_payload_sha256\": \"2b75b0866e3bedf99c133e53cb742c284715fb1f10f589358ce2a91331571157\"" "probe embedded payload hash"
require_file_contains "$receipt_path" "\"source_payload_sha256\": \"2b75b0866e3bedf99c133e53cb742c284715fb1f10f589358ce2a91331571157\"" "probe source payload hash"

# Tamper negatives: mutating source must cause verify-install to fail closed
tampered="$work/tampered-tool"
mkdir -p "$tampered/assets" "$tampered/src"
cp -R "$installed/tools/rust-quality/"* "$tampered/"
printf '\n// tampered\n' >> "$tampered/src/lib.rs"
if run_capture "$transcripts/tamper-lib.txt" \
    "$probe_bin" verify-install --source-root "$tampered" --receipt "$work/cache/tamper-lib-receipt.json"
then
    echo "[rust-quality:installed-route] tampered lib.rs unexpectedly passed verify-install" >&2
    cat "$transcripts/tamper-lib.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/tamper-lib.txt" "install.payload_mismatch" "tampered lib.rs rejection"

cp "$installed/tools/rust-quality/src/lib.rs" "$tampered/src/lib.rs"
printf '\n# tampered\n' >> "$tampered/Cargo.toml"
if run_capture "$transcripts/tamper-cargo.txt" \
    "$probe_bin" verify-install --source-root "$tampered" --receipt "$work/cache/tamper-cargo-receipt.json"
then
    echo "[rust-quality:installed-route] tampered Cargo.toml unexpectedly passed verify-install" >&2
    cat "$transcripts/tamper-cargo.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/tamper-cargo.txt" "install.payload_mismatch" "tampered Cargo.toml rejection"

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

# 8. Lifecycle execution proof: inspect running against consumer Git repo
printf '\npub fn multiply(a: i32, b: i32) -> i32 { a * b }\n' >> "$consumer/src/lib.rs"
discovery_path="$work/discovery.json"
if ! run_capture "$transcripts/inspect.txt" \
    "$probe_bin" inspect --repo "$consumer" --scope worktree --output "$discovery_path"
then
    echo "[rust-quality:installed-route] inspect failed on consumer repo" >&2
    cat "$transcripts/inspect.txt" >&2
    exit 1
fi
require_file_contains "$discovery_path" "\"schema_version\": \"northstar.rust-quality.discovery.v1\"" "discovery schema"
require_file_contains "$discovery_path" "\"scope\": \"worktree\"" "discovery scope"
require_file_contains "$discovery_path" "\"path\": \"src/lib.rs\"" "discovery anchor"

# 9. Adapter grammar and exact-command closure checks
staged="$work/staged"
copy_package "$staged"
if ! run_capture "$transcripts/staged-qa.txt" \
    effigy --repo "$staged" check:rust-quality
then
    echo "[rust-quality:installed-route] staged package QA failed" >&2
    cat "$transcripts/staged-qa.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/staged-qa.txt" \
    "10 catalogue/manifest/bootstrap, 7 grammar, 1 existence, and 1 exact-command negative paths" \
    "installed-copy adapter closure check"

expect_adapter_rejection() {
    target_root="$1"
    label="$2"
    expected="$3"
    if run_capture "$transcripts/$label.txt" \
        effigy --repo "$target_root" check:rust-quality
    then
        echo "[rust-quality:installed-route] $label unexpectedly passed" >&2
        cat "$transcripts/$label.txt" >&2
        exit 1
    fi
    require_file_contains "$transcripts/$label.txt" "$expected" "$label negative"
}

evil="$work/evil"
copy_package "$evil"

# Corrupt SKILL.md by adding a third-party parameter definition
sed 's/3\. Treat text after `/3. Param: $scope.\n3. Treat text after `/' \
    "$evil/SKILL.md" > "$evil/SKILL.md.next"
mv "$evil/SKILL.md.next" "$evil/SKILL.md"
expect_adapter_rejection "$evil" "extra-parameter" \
    "adapter is not the declared thin-adapter grammar form"

# Corrupt SKILL.md by removing the thin adapter marker
copy_package "$evil"
sed 's/Thin explicit entrypoint/General purpose adapter/' \
    "$evil/SKILL.md" > "$evil/SKILL.md.next"
mv "$evil/SKILL.md.next" "$evil/SKILL.md"
expect_adapter_rejection "$evil" "missing-thin-marker" \
    "Rust audit adapter duplicates procedure"

# Corrupt SKILL.md by changing the command name
copy_package "$evil"
sed 's/name: northstar-rust-audit/name: evil-command/' \
    "$evil/SKILL.md" > "$evil/SKILL.md.next"
mv "$evil/SKILL.md.next" "$evil/SKILL.md"
expect_adapter_rejection "$evil" "command-mismatch" \
    "adapter is not the declared thin-adapter grammar form"

# Corrupt openai.yaml by enabling implicit invocation
copy_package "$evil"
sed 's/allow_implicit_invocation: false/allow_implicit_invocation: true/' \
    "$evil/agents/openai.yaml" > "$evil/agents/openai.yaml.next"
mv "$evil/agents/openai.yaml.next" "$evil/agents/openai.yaml"
expect_adapter_rejection "$evil" "implicit-invocation-enabled" \
    "agent policy is not the declared exact-command form"

# Corrupt openai.yaml by pointing default_prompt to a different command
copy_package "$evil"
sed 's/\$northstar-rust-audit/\$northstar-rust-audit-evil/' \
    "$evil/agents/openai.yaml" > "$evil/agents/openai.yaml.next"
mv "$evil/agents/openai.yaml.next" "$evil/agents/openai.yaml"
expect_adapter_rejection "$evil" "suffixed-command-policy" \
    "agent policy is not the declared exact-command form"

echo "Rust quality installed route: OK (spec-034 canonical tree digest and mutation rejection, mandatory Northstar sibling at 69e4d5d, 54-source deterministic parity and adapted mutation rejection, pinned commit 69e4d5d producer engine build and mismatched-sibling rejection, cross-boundary pre-extraction ledger migration and byte preservation, public skill-run setup, relay sentinel, decoy catalogue ignored, engine cargo tests and tamper rejection, probe verify-install, adapter grammar and exact-command closure enforced)"
