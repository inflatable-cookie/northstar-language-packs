---
title: Build Rust package source worker handoff
status: ready
handoff_mode: worker
worker_mode: worker-pr-loop
dispatch_authority: northstar-orchestrator
branch: worker/build-rust-package-source
worktree_slug: build-rust-package-source
base_branch: main
handoff_path: /Users/tom/Dev/projects/northstar-language-packs/docs/handoffs/20260903-020553-build-rust-package-source.md
---

# Build Rust Package Source

## Outcome

Build the independently addressable Rust quality package under
`packages/rust`, preserving both workflows and the Cargo-native engine. Return
one review-only PR with immutable source, package-tree, manifest, and engine
identities. Do not edit Northstar or Convergence.

## Authority And Source

- Governing local card: `g01.002/004`.
- Upstream authority: Northstar `g02.048/119`, ready after card 121 merged as
  `69e4d5dea3daa4f6133d7363d39c1a0f72848435`.
- Required sibling worktree links: `../northstar` read-only, resolving to the
  Northstar checkout at that exact commit before source materialization.
- Frozen source boundary: 54 tracked files — 24 Rust references, two modes,
  two Rhai scripts, 22 Cargo-engine files, one explicit command skill, and
  three Rust templates.
- Sorted GNU `sha256sum` listing digest:
  `2f8515afce33c87e9b38f103b9c41440ed7f182142fc2c65fed4d10d9264040b`.
- The prior readiness log named an unavailable `4f534b...` object. Do not use
  it. Reproduce the 54-file listing and digest from `69e4d5d` before mutation.

## Scope

- Materialize each frozen Rust path exactly once under `packages/rust` with a
  documented source map. Preserve meaningful bytes unless package-relative
  task-source resolution requires an explicit, reviewed adaptation.
- Add `northstar-package.json`, package-local `SKILL.md`, agent metadata,
  catalogue/task wiring, self-check, package QA, staged inventory, and release
  evidence using the accepted TypeScript package as shape, not copied policy.
- Expose both manifest workflows: strict everyday authoring and explicit audit.
  Both must route to package-local authority and remain behaviorally distinct.
- Keep the Cargo-native engine payload-addressed, checksum-verified, and
  independent of Northstar root and consumer Effigy catalogues. Prove source
  and built-engine tamper rejection, cache behavior, and installed execution.
- Reuse revision-E production fixtures and prove existing evidence/profile/
  deviation compatibility without mutating consumer authority.
- Prove source/staged parity, direct self-check, installed-copy QA, no
  TypeScript or root-only payload, and sibling-package isolation.
- Reconcile card 004, milestone `g01.002`, front doors, changelog, one dated
  log, and this handoff. Preserve historical evidence.

## Boundaries

- No Northstar, Convergence, registry, release, CI/workflow, or sibling-package
  mutation. The `../northstar` sibling is read-only evidence.
- No Rust rule, MSRV ownership, remediation authority, workflow scope,
  evidence schema/lifecycle, or Cargo-engine behavior change.
- Do not publish or merge. Do not start core registry or consumer-canary work.
- Stop for planning if faithful extraction requires a protocol or policy
  change rather than a package-relative adaptation.

## Review Oracle

1. All 54 frozen paths reconcile exactly once; omission, duplication, or
   unrecorded semantic rewrite fails parity.
2. Installed inventory contains only the Rust package; TypeScript and root-only
   Northstar surfaces are absent.
3. Everyday authoring stays changed-tranche-only; explicit audit alone enters
   repository-wide finding-first recording.
4. Agent-facing adapters, manifest entrypoints, tasks, and modes resolve only
   inside the installed package and agree exactly.
5. Engine source/binary/receipt identities agree; source or binary tamper fails
   before audit execution, including with decoy Northstar and consumer Effigy
   roots.
6. Consumer MSRV, profile, deviations, repair authority, and existing v2
   evidence remain unchanged and readable.
7. Missing runtime capability or failed self-check stops before candidate
   acceptance; source/staged/installed identities remain exact.
8. Package source, staging, QA, and installation never retain or load the
   TypeScript sibling.

## Validation

- package-scoped source/install parity and self-check
- both workflow route fixtures and revision-E evidence fixtures
- Cargo-engine unit/integration tests plus tamper/cache negatives
- `effigy qa`
- `git diff --check origin/main...HEAD`

## Completion Protocol

Commit and push one reviewable branch, open a PR to `main`, and report the PR
URL, exact tested head, package tree and manifest digests, engine identity, and
limits. Stop for orchestrator exact-head review. Do not merge or touch the
Northstar registry.
