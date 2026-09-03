# 004 — Build Rust Package Source

Status: completed; candidate ready for review
Owner: repo maintainers
Updated: 2026-09-03
Upstream authority: Northstar card `g02.048/119`
Depends on: local card 003 and Northstar card `g02.048/121` (both complete)

## Objective

Relocate the frozen Northstar Rust quality payload into one independently
addressable package without changing rule, workflow, engine, or evidence
meaning.

## Source Boundary

Northstar's post-repin readiness evidence freezes 54 tracked files at
`69e4d5dea3daa4f6133d7363d39c1a0f72848435`: 24 Rust references, two modes,
two Rhai scripts, 22 Cargo-engine files, one explicit command skill, and three
templates. The SHA-256 of its sorted GNU `sha256sum` listing is
`2f8515afce33c87e9b38f103b9c41440ed7f182142fc2c65fed4d10d9264040b`.

The 120-file historical figure is whole Northstar skill distribution parity,
not this package inventory.

## Scope

- materialize only the frozen Rust source boundary under `packages/rust`;
- add the package manifest, local catalogue, self-check, agent metadata, and
  package-owned parity/oracle proof required by the accepted protocol;
- preserve strict everyday authoring and explicit audit as distinct workflows;
- keep the Cargo-native engine payload-addressed, checksum-verified, and
  independent of consumer Effigy catalogues;
- prove no TypeScript or root Northstar payload enters source or staging;
- return immutable source identities to the Northstar orchestrator.

Do not edit Northstar, Convergence, registry state, MSRV policy, Rust rule
meaning, remediation authority, or evidence lifecycle. Do not merge.

## Acceptance

- [x] package inventory reconciles every frozen Rust source path exactly once;
- [x] no TypeScript payload or root-only router surface is present;
- [x] everyday and explicit-audit routes remain distinct and package-local;
- [x] revision-E fixtures and existing evidence compatibility pass;
- [x] Cargo engine source/binary identity and cache behavior remain exact;
- [x] source/staged parity and declared self-check pass;
- [x] package QA, repository QA, and `git diff --check` pass;
- [x] replacement commit, tree digest, manifest digest, and engine identity are
  recorded honestly.

## Review Oracle

| Invariant | Counterexample | Expected stop | Proof |
| --- | --- | --- | --- |
| Inventory is exact. | One frozen path is omitted, duplicated, or rewritten semantically. | Parity fails. | Pinned source map and staged inventory. |
| Workflows remain distinct. | Ordinary authoring enters repository audit. | Stay changed-tranche-only. | Existing routing fixtures. |
| Engine is independent. | Audit engine resolves from Northstar root or consumer Effigy. | Stop before execution. | Decoy roots and digest tamper fixture. |
| Package is isolated. | Staging includes TypeScript or a sibling package. | Inventory rejects it. | Negative installed inventory. |
| Consumer owns policy. | Package infers MSRV or widens repair authority. | Stop for Northstar planning. | Existing policy fixtures. |

## Stop Conditions

- the pinned Northstar source commit or 54-file listing digest cannot be
  reproduced;
- extraction needs a language-specific protocol change;
- policy, evidence, engine lifecycle, or MSRV ownership would change;
- validation changes the plan.

## Next Task

Review-only pull request opened for card 004. Stop for review; Northstar
registry promotion and Convergence canary follow after merge.
