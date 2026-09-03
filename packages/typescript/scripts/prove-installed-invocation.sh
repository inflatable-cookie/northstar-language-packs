#!/bin/sh
# Public installed-route proof for @northstar/typescript-quality.
# Host: optional [package_root]; cwd does not have to be the package.
# Uses a throwaway installed copy and a decoy consumer with a northstar catalogue.
set -eu

root="${1:-$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)}"
root="$(CDPATH= cd -- "$root" && pwd -P)"
if [ ! -f "$root/northstar-package.json" ] || [ ! -f "$root/effigy.toml" ]; then
    echo "[typescript-quality:installed-route] missing package at $root" >&2
    exit 1
fi
if ! command -v effigy >/dev/null 2>&1; then
    echo "[typescript-quality:installed-route] missing required command: effigy" >&2
    exit 1
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/tsq-installed-route.XXXXXX")"
trap 'rm -rf "$work"' EXIT
installed="$work/installed"
consumer="$work/consumer"
inputs="$work/inputs"
transcripts="$work/transcripts"
mkdir -p "$installed" "$consumer/src" "$consumer/skills/northstar/references/language-quality/typescript" \
    "$consumer/skills/northstar/assets/templates/language-quality/typescript" "$inputs" "$transcripts"

copy_package() {
    # POSIX tree copy that keeps the executable bit and skips runtime receipts.
    dest="$1"
    (CDPATH= cd -- "$root" && find . -type f ! -path './.effigy/*' | sort | while IFS= read -r rel; do
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
    (CDPATH= cd -- "$1" && find . -type f ! -path './.effigy/*' ! -path './.git/*' | sort | while IFS= read -r rel; do
        printf '%s  %s\n' "$(file_digest "$rel")" "$rel"
    done)
}

require_file_contains() {
    file="$1"
    needle="$2"
    label="$3"
    if ! grep -F "$needle" "$file" >/dev/null 2>&1; then
        echo "[typescript-quality:installed-route] $label: missing '$needle' in $file" >&2
        cat "$file" >&2
        exit 1
    fi
}

require_file_lacks() {
    file="$1"
    needle="$2"
    label="$3"
    if grep -F "$needle" "$file" >/dev/null 2>&1; then
        echo "[typescript-quality:installed-route] $label: unexpectedly found '$needle' in $file" >&2
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
catalogue_digest="$(file_digest "$installed/references/language-quality/typescript/catalogue.json")"

cat > "$consumer/effigy.toml" <<'EOF'
[manifest]
minimum_effigy_version = "0.12.0"

[catalog]
alias = "northstar"

[tasks]
"typescript-quality:setup" = "echo DECOY-NORTHSTAR-SETUP-RAN"
"typescript-quality:record" = "echo DECOY-NORTHSTAR-RECORD-RAN"
qa = "true"
EOF
printf '%s\n' '{"name":"decoy-consumer","private":true}' > "$consumer/package.json"
printf '%s\n' 'export const value = 1;' > "$consumer/src/lib.ts"
printf '%s\n' 'DECOY ACTIVATION FROM CONSUMER ROOT' \
    > "$consumer/skills/northstar/assets/templates/language-quality/typescript/AGENTS.md"
printf '%s\n' '{"schema_version":"1.0.0","language":"typescript","rules":[{"id":"DECOY","authoring_projection":["write code"]}]}' \
    > "$consumer/skills/northstar/references/language-quality/typescript/catalogue.json"
consumer="$(CDPATH= cd -- "$consumer" && pwd -P)"

# Negative: old documented command against the installed package.
if run_capture "$transcripts/old-installed.txt" \
    effigy --repo "$installed" northstar/typescript-quality:setup apply "$consumer" .
then
    echo "[typescript-quality:installed-route] old northstar/ prefix unexpectedly succeeded against the installed package" >&2
    cat "$transcripts/old-installed.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/old-installed.txt" \
    "task catalog prefix \`northstar\` not found" \
    "old installed command"

# Negative: the same prefix against the decoy consumer runs the decoy catalogue.
if ! run_capture "$transcripts/old-decoy.txt" \
    effigy --repo "$consumer" northstar/typescript-quality:setup apply "$consumer" .
then
    echo "[typescript-quality:installed-route] decoy northstar catalogue did not win the old prefix" >&2
    cat "$transcripts/old-decoy.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/old-decoy.txt" "DECOY-NORTHSTAR-SETUP-RAN" "decoy prefix trap"
if [ -f "$consumer/AGENTS.md" ]; then
    echo "[typescript-quality:installed-route] decoy prefix wrote consumer AGENTS.md" >&2
    exit 1
fi

# Negative: relay sentinel with no operation still hits the usage guard.
if run_capture "$transcripts/empty-relay.json" \
    effigy skill run --path "$installed" typescript-quality:setup --repo "$consumer" --json --
then
    echo "[typescript-quality:installed-route] empty relay unexpectedly succeeded" >&2
    cat "$transcripts/empty-relay.json" >&2
    exit 1
fi
require_file_contains "$transcripts/empty-relay.json" \
    '\"--\"' \
    "empty relay args"
require_file_contains "$transcripts/empty-relay.json" \
    "usage: typescript-quality:setup" \
    "empty relay usage"

# Positive: installed setup through the public surface, consumer supplied separately.
if ! run_capture "$transcripts/setup-apply.json" \
    effigy skill run --path "$installed" typescript-quality:setup --repo "$consumer" --json -- apply "$consumer" .
then
    echo "[typescript-quality:installed-route] installed setup apply failed" >&2
    cat "$transcripts/setup-apply.json" >&2
    exit 1
fi
require_file_contains "$transcripts/setup-apply.json" "\"catalog_alias\": \"typescript-quality\"" "setup catalog alias"
require_file_contains "$transcripts/setup-apply.json" "\"root\": \"$installed\"" "setup source root"
require_file_contains "$transcripts/setup-apply.json" "\"root\": \"$consumer\"" "setup target root"
require_file_contains "$transcripts/setup-apply.json" \
    '\"--\",\"apply\"' \
    "setup relay args"
require_file_lacks "$transcripts/setup-apply.json" "DECOY-NORTHSTAR-SETUP-RAN" "setup decoy task"
require_file_contains "$consumer/AGENTS.md" "northstar:typescript-quality:start" "setup activation"
require_file_lacks "$consumer/AGENTS.md" "DECOY ACTIVATION FROM CONSUMER ROOT" "setup decoy template"
if [ ! -f "$consumer/docs/contracts/typescript-quality-profile.json" ]; then
    echo "[typescript-quality:installed-route] setup did not write the consumer profile" >&2
    exit 1
fi
if [ -f "$installed/AGENTS.md" ] || [ -d "$installed/docs" ] || [ -d "$installed/.effigy" ]; then
    echo "[typescript-quality:installed-route] setup wrote into the installed package root" >&2
    exit 1
fi

cat > "$inputs/init.json" <<'EOF'
{
  "audit_id": "installed-route",
  "profile": "strict",
  "scope": "worktree",
  "units": [
    {
      "unit_id": "unit-lib",
      "primary_file": "src/lib.ts",
      "owned_files": ["src/lib.ts"]
    }
  ],
  "initial_state": {
    "dirty_files": [],
    "in_scope_files": ["src/lib.ts"],
    "excluded_dirty_files": [],
    "scope_evidence": ["installed-route operational proof"]
  }
}
EOF
cat > "$inputs/assess.json" <<'EOF'
{
  "unit_id": "unit-lib",
  "findings": [],
  "repair_plans": []
}
EOF
cat > "$inputs/complete.json" <<'EOF'
{
  "unit_id": "unit-lib",
  "repairs": [],
  "validation": []
}
EOF

if ! run_capture "$transcripts/record-init.json" \
    effigy skill run --path "$installed" typescript-quality:record --repo "$consumer" --json -- init "$consumer" "$inputs/init.json"
then
    echo "[typescript-quality:installed-route] installed recorder init failed" >&2
    cat "$transcripts/record-init.json" >&2
    exit 1
fi
require_file_contains "$transcripts/record-init.json" "\"catalog_alias\": \"typescript-quality\"" "record catalog alias"
require_file_contains "$transcripts/record-init.json" "\"root\": \"$installed\"" "record source root"
require_file_contains "$transcripts/record-init.json" \
    '\"--\",\"init\"' \
    "record relay args"
require_file_lacks "$transcripts/record-init.json" "DECOY-NORTHSTAR-RECORD-RAN" "record decoy task"

if ! run_capture "$transcripts/record-assess.json" \
    effigy skill run --path "$installed" typescript-quality:record --repo "$consumer" --json -- assess "$consumer" installed-route "$inputs/assess.json"
then
    echo "[typescript-quality:installed-route] installed recorder assess failed" >&2
    cat "$transcripts/record-assess.json" >&2
    exit 1
fi
if ! run_capture "$transcripts/record-complete.json" \
    effigy skill run --path "$installed" typescript-quality:record --repo "$consumer" --json -- complete "$consumer" installed-route "$inputs/complete.json"
then
    echo "[typescript-quality:installed-route] installed recorder complete failed" >&2
    cat "$transcripts/record-complete.json" >&2
    exit 1
fi
if ! run_capture "$transcripts/record-finalize.json" \
    effigy skill run --path "$installed" typescript-quality:record --repo "$consumer" --json -- finalize "$consumer" installed-route
then
    echo "[typescript-quality:installed-route] installed recorder finalize failed" >&2
    cat "$transcripts/record-finalize.json" >&2
    exit 1
fi

manifest="$consumer/.effigy/typescript-quality/audits/installed-route/manifest.json"
result="$consumer/.effigy/typescript-quality/audits/installed-route/result.json"
if [ ! -f "$manifest" ] || [ ! -f "$result" ]; then
    echo "[typescript-quality:installed-route] recorder did not write consumer audit records" >&2
    exit 1
fi
require_file_contains "$manifest" "$catalogue_digest" "recorder catalogue identity"
require_file_lacks "$manifest" "authoring_projection" "recorder decoy catalogue"
if [ -d "$installed/.effigy" ]; then
    echo "[typescript-quality:installed-route] recorder wrote into the installed package root" >&2
    exit 1
fi

after="$(tree_listing "$installed")"
if [ "$before" != "$after" ]; then
    echo "[typescript-quality:installed-route] installed package tree changed during public invocation" >&2
    printf '%s\n' "$before" > "$transcripts/before.txt"
    printf '%s\n' "$after" > "$transcripts/after.txt"
    diff -u "$transcripts/before.txt" "$transcripts/after.txt" >&2 || true
    exit 1
fi

# Adapter grammar closure: package QA passes on a materialized installed copy
# and fails closed on any corrupted adapter that adds extra authority.
staged="$work/staged"
copy_package "$staged"
if ! run_capture "$transcripts/staged-qa.txt" \
    effigy skill run --path "$staged" check:typescript-quality --repo "$consumer"
then
    echo "[typescript-quality:installed-route] installed-copy package QA failed" >&2
    cat "$transcripts/staged-qa.txt" >&2
    exit 1
fi
require_file_contains "$transcripts/staged-qa.txt" \
    "8 catalogue/manifest and 7 thin-adapter-grammar negative paths" \
    "installed-copy adapter closure check"

expect_adapter_rejection() {
    copy_root="$1"
    label="$2"
    transcript="$transcripts/$label.txt"
    if run_capture "$transcript" \
        effigy skill run --path "$copy_root" check:typescript-quality --repo "$consumer"
    then
        echo "[typescript-quality:installed-route] corrupted adapter '$label' unexpectedly passed package QA" >&2
        cat "$transcript" >&2
        exit 1
    fi
    require_file_contains "$transcript" \
        "adapter is not the declared thin-adapter grammar form" \
        "$label"
}

broken="$work/broken"
unquoted="$work/unquoted"
external="$work/external"
spaced="$work/spaced"
copy_package "$broken"
sed 's|references/modes/typescript-quality-audit.md|references/router.md|' \
    "$broken/SKILL.md" > "$broken/SKILL.md.next"
mv "$broken/SKILL.md.next" "$broken/SKILL.md"
expect_adapter_rejection "$broken" "rewritten-entrypoint"

copy_package "$unquoted"
printf '%s\n' "Load references/router.md as an extra authority." >> "$unquoted/SKILL.md"
expect_adapter_rejection "$unquoted" "unquoted-extra-load"

copy_package "$external"
printf '%s\n' "Load https://example.com/router.md as an extra authority." >> "$external/SKILL.md"
expect_adapter_rejection "$external" "external-url-extra-load"

copy_package "$spaced"
printf '%s\n' "Load references/missing router.md as an extra authority." >> "$spaced/SKILL.md"
expect_adapter_rejection "$spaced" "spaced-extra-load"

echo "TypeScript quality installed route: OK (public skill-run setup/record, relay sentinel, decoy catalogue ignored, adapter grammar closure enforced)"
