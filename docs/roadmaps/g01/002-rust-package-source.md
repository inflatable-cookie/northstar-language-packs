# 002 — Rust Package Source

Status: active; card 004 candidate ready for review
Owner: repo maintainers
Upstream authority: Northstar `g02.048/119`

## Objective

Build the independently addressable Rust quality package from Northstar's
frozen 54-file source boundary while preserving both workflows and the
Cargo-native engine.

## Execution

- `batch-cards/004-build-rust-package-source.md` owns source relocation and
  package-local proof from the post-repin Northstar source pin.
- Northstar owns official registry promotion and the Convergence canary.

## Next Task

Review-only pull request opened for card 004. Stop for review and merge of the
immutable package candidate; return its identities to Northstar.
