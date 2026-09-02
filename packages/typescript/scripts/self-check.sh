#!/bin/sh
# Direct self-check for @northstar/typescript-quality.
# Host contract: execute this entrypoint with [package_root]; cwd is package_root.
set -eu
root="${1:?usage: self-check.sh <package-root>}"
cd "$root"
if [ ! -f "northstar-package.json" ]; then
    echo "[typescript-quality:self-check] missing manifest: $root/northstar-package.json" >&2
    exit 1
fi
if [ ! -f "effigy.toml" ]; then
    echo "[typescript-quality:self-check] missing package catalogue: $root/effigy.toml" >&2
    exit 1
fi
if ! command -v sh >/dev/null 2>&1; then
    echo "[typescript-quality:self-check] missing required command: sh" >&2
    exit 1
fi
if ! command -v effigy >/dev/null 2>&1; then
    echo "[typescript-quality:self-check] missing required command: effigy" >&2
    exit 1
fi
effigy check:typescript-quality
