#!/bin/sh
# Authoritative repository-level release and source identity oracle.
# Validates exact raw Spec-034 package-tree identities, listings, manifests, and engine payloads
# from outside the addressed package trees, enforcing raw-framing mutation negatives and wiring
# the expected tree digest into package proofs.
set -eu

root="${1:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)}"
root="$(CDPATH= cd -- "$root" && pwd -P)"

if [ ! -f "$root/effigy.toml" ] || [ ! -d "$root/packages" ]; then
    echo "[package-identities:oracle] missing repository root at $root" >&2
    exit 1
fi

python3 -c "
import os, hashlib, stat, sys, subprocess

repo_root = sys.argv[1]

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

    h = hashlib.sha256()
    for rel in files:
        full = os.path.join(pkg_root, rel)
        st = os.stat(full)
        is_exec = 1 if (st.st_mode & 0o111) != 0 else 0
        with open(full, 'rb') as fp:
            content = fp.read()
        rel_bytes = rel.encode('utf-8')
        header = f'F\x00{len(rel_bytes)}\x00{rel}\x00{is_exec}\x00{len(content)}\x00'.encode('utf-8')
        h.update(header)
        h.update(content)

    return len(files), f'sha256:{h.hexdigest()}'

def compute_listing_digest(pkg_root):
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
    lines = []
    for rel in files:
        full = os.path.join(pkg_root, rel)
        with open(full, 'rb') as fp:
            lines.append(f'{hashlib.sha256(fp.read()).hexdigest()}  {rel}')
    listing = '\n'.join(lines) + '\n'
    return 'sha256:' + hashlib.sha256(listing.encode('utf-8')).hexdigest()

def file_sha256(path):
    with open(path, 'rb') as f:
        return f'sha256:{hashlib.sha256(f.read()).hexdigest()}'

# 1. Validate @northstar/rust-quality release identities
rust_pkg = os.path.join(repo_root, 'packages/rust')
rust_count, rust_tree_digest = compute_spec_034_tree_digest(rust_pkg)
assert rust_count == 59, f'Expected 59 Rust package files, got {rust_count}'

expected_rust_tree = 'sha256:59f05e9be6868fb77b7a47e093120648ea68edb8d970f1c0838c62fc506ddf21'
assert rust_tree_digest == expected_rust_tree, f'Rust Spec-034 tree digest mismatch: {rust_tree_digest} != {expected_rust_tree}'

expected_rust_listing = 'sha256:5ac0b051c5476b1416b1d42eab73f29cfcec31832367df75de51079340c97b08'
rust_listing = compute_listing_digest(rust_pkg)
assert rust_listing == expected_rust_listing, f'Rust listing digest mismatch: {rust_listing} != {expected_rust_listing}'

expected_rust_manifest = 'sha256:8773ceb2be1aeb170d568b2fee3eebdf50b8b399e213b0a3e505262b39606ecd'
rust_manifest = file_sha256(os.path.join(rust_pkg, 'northstar-package.json'))
assert rust_manifest == expected_rust_manifest, f'Rust manifest mismatch: {rust_manifest} != {expected_rust_manifest}'

rust_cargo_toml = file_sha256(os.path.join(rust_pkg, 'tools/rust-quality/Cargo.toml'))
assert rust_cargo_toml == 'sha256:89c226257ceaa62746426cd9b40c947e6d09cca87b627ff41ce6e7a66bc788b7'

rust_cargo_lock = file_sha256(os.path.join(rust_pkg, 'tools/rust-quality/Cargo.lock'))
assert rust_cargo_lock == 'sha256:bc06a8704d049aa400805186854436ae214edc0e5a3b525cb338bb18d875f0de'

# Raw-framing mutation negative: mutating any file changes the raw Spec-034 tree digest
tamper_target = os.path.join(rust_pkg, 'references/language-quality/rust/catalogue.json')
with open(tamper_target, 'rb') as f:
    orig = f.read()
try:
    with open(tamper_target, 'wb') as f:
        f.write(orig + b' ')
    _, tampered_digest = compute_spec_034_tree_digest(rust_pkg)
    assert tampered_digest != expected_rust_tree, 'Tampered package tree unexpectedly matched expected digest'
finally:
    with open(tamper_target, 'wb') as f:
        f.write(orig)

# Raw-framing stray file negative: adding stray file fails count
stray_file = os.path.join(rust_pkg, 'stray-repo-check.txt')
try:
    with open(stray_file, 'wb') as f:
        f.write(b'stray')
    stray_count, _ = compute_spec_034_tree_digest(rust_pkg)
    assert stray_count != 59, 'Stray file was not detected in file count'
finally:
    if os.path.exists(stray_file):
        os.remove(stray_file)

# 2. Validate @northstar/typescript-quality release identities
ts_pkg = os.path.join(repo_root, 'packages/typescript')
ts_count, ts_tree_digest = compute_spec_034_tree_digest(ts_pkg)
expected_ts_tree = 'sha256:425ad130a53f6f78604bdfd23068c9a59ca599127b563d293b3d4fd9ba0b288d'
assert ts_tree_digest == expected_ts_tree, f'TypeScript Spec-034 tree digest mismatch: {ts_tree_digest} != {expected_ts_tree}'

expected_ts_manifest = 'sha256:6b8695019e88a6020e5a4244079ebf4ddf92406448c61345d856ac5b71618a06'
ts_manifest = file_sha256(os.path.join(ts_pkg, 'northstar-package.json'))
assert ts_manifest == expected_ts_manifest, f'TypeScript manifest mismatch: {ts_manifest} != {expected_ts_manifest}'

print('Repository package release identities: OK')
" "$root"

# 3. Wire external expected tree binding into package proof
"$root/packages/rust/scripts/prove-installed-invocation.sh" "$root/packages/rust" "sha256:59f05e9be6868fb77b7a47e093120648ea68edb8d970f1c0838c62fc506ddf21"
