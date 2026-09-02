# 002 — Rust Package Source

Status: planned; blocked on TypeScript card 003 and Northstar card 121
Owner: repo maintainers
Upstream authority: Northstar `g02.048/119`

## Objective

Build the independently addressable Rust quality package from Northstar's
frozen 54-file source boundary while preserving both workflows and the
Cargo-native engine.

## Execution

- `batch-cards/004-build-rust-package-source.md` owns source relocation and
  package-local proof after the TypeScript adapter repair and registry repin.
- Northstar owns official registry promotion and the Convergence canary.

## Next Task

Keep card 004 blocked. Refresh its pinned Northstar base only after card 121
merges and Northstar card 119 becomes ready.
