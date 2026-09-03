---
title: Repair TypeScript skill entrypoint worker handoff
kind: northstar-handoff
handoff_mode: worker-pr-loop
worker_mode: implementation
dispatch_authority: orchestrator
handoff: single-file-path-only
status: ready-to-launch
owner: repo maintainers
created: 2026-09-03
updated: 2026-09-03
handoff_path: /Users/tom/Dev/projects/northstar-language-packs/docs/handoffs/20260903-010129-repair-typescript-skill-entrypoint.md
base_required: pushed-main
tags: [coordination, handoff, worker, typescript, package, adapter]
---

## What This Thread Was Doing

The card-119 Rust readiness review found that the accepted TypeScript package's
agent-facing `SKILL.md` loads `references/router.md`, which is absent from the
independently installed package. Local card `g01.001/003` is the sole ready
repair.

This dispatches one bounded implementation lane. No transcript or second prompt
is part of the authority chain.

## Why It Matters

An independently installable skill must not depend on an uninstalled root
Northstar file. Rust extraction stays blocked until the TypeScript package shape
is honest and its replacement identity is reviewed and repinned.

## Current State

- **Repository:** `/Users/tom/Dev/projects/northstar-language-packs`
- **Planning branch:** `main`
- **Planning base commit:** `71a64562f17a4abc4dbef98d13f90ab72e76c9e5`
- **Pushed main verification:** local `HEAD` equals `origin/main` at that commit
- **Planning checkout:** clean
- **Worker mode:** implementation worker dispatched by the orchestrator; this
  handoff activates the worker-only worktree preflight
- **Planning artifacts included at the base:** card `g01.001/003`, milestone
  `g01.001`, and Northstar card `g02.048/121`
- **Worker branch:** `worker/repair-typescript-skill-entrypoint`
- **Worker worktree:** Paseo-managed; accept the launcher's actual registered
  worktree path
- **Worktree creation command:** Paseo `branch-off` from `origin/main`
- **Required sibling worktree links:** `northstar` ->
  `/Users/tom/Dev/projects/northstar`, beside the worker worktree; read-only
- **Active spec lane:** Northstar spec 034
- **Roadmap milestone:** `docs/roadmaps/g01/001-typescript-package-source.md`
- **Ready cards, in order:**
  `docs/roadmaps/g01/batch-cards/003-repair-typescript-skill-entrypoint.md`
- **Allowed runway:** card 003 only
- **Remaining card budget:** one card
- **Dispatch topology:** sole ready lane; Rust card 004 is serial behind this
  source repair and Northstar's replacement registry pin
- **Parallel safety check:** no other package-source lane is ready
- **Surfaces this lane owns:** `packages/typescript/**`, card 003, milestone
  001, one dated log, this handoff, and package-source front doors
- **Integration ownership:** worker reconciles its local closeout; Northstar
  registry and card 121 remain orchestrator-owned
- **Canonical refs:** `docs/architecture/system-architecture.md`;
  `docs/contracts/001-working-rules.md`; Northstar
  `docs/contracts/004-language-quality-pack.md` and
  `docs/specs/034-modular-language-quality-packages.md`
- **Review oracle:** card 003
- **Model capability profile:** ordinary bounded implementation; economical
  non-frontier route with exact-head frontier review retained by orchestrator
- **Frontier-worker justification:** none
- **Tool/runtime restrictions:** do not edit the `northstar` sibling, registry,
  Jetstream, Rust package planning, CI, or release state
- **Required validation:** package QA, installed-copy path-closure negatives,
  direct self-check, existing installed setup/record proof, repository
  `effigy qa`, and `git diff --check origin/main...HEAD`
- **PR base/head:** `main` <- `worker/repair-typescript-skill-entrypoint`
- **PR URL:** pending
- **Review state:** awaiting worker PR
- **Merge path:** orchestrator after accepted review of the current head and
  passing required checks

## Boundaries

- **In scope:** reproduce the missing reference, make the command skill load
  its declared package-local audit mode, add fail-closed path-closure proof,
  preserve semantics, recompute identities, and open the reviewable PR.
- **Out of scope:** copied root router, new workflow, version decision, policy
  change, generic protocol change, Northstar registry edit, consumer mutation,
  Rust work, or merge.
- **Outcome shape:** complete issue fix, not diagnostics-only.
- Work only in the clean worker worktree selected by the completion protocol.
  Never edit the planning checkout or the read-only Northstar sibling.
- Do not merge the PR.

## Important Context

- The package manifest already declares
  `references/modes/typescript-quality-audit.md` as its sole workflow
  entrypoint. The command skill should remain a thin adapter to that authority.
- Existing package proof covers Effigy setup and recorder invocation, not the
  agent-facing `SKILL.md`; extend proof at that precise gap.
- Package version and policy stay fixed. The source edit changes the immutable
  tree identity, which must be reported for the later Northstar repin.
- Report after the fix, adversarial path checks, identity reproduction, full
  validation, push, and PR creation.
- Report through Paseo to the orchestrator.

## Suggested Next Move

Run the worker preflight before broad reads. Then read `AGENTS.md`, card 003,
milestone 001, and the named architecture/contract refs. Reproduce the absent
path from a materialized package before editing.

## Completion Protocol

1. This handoff activates worker mode. Before broad reads, run
   `git rev-parse --show-toplevel`, `git branch --show-current`,
   `git status --porcelain`, and `git worktree list --porcelain`.
2. Accept a clean, registered, non-`main` launcher worktree even when its path
   differs from this handoff. Do not create another worktree. If the launcher
   context is unusable, follow the repository's configured manual fallback;
   never clean or discard another checkout.
3. Fetch with the bounded SSH command from the Northstar worker protocol.
   Confirm `HEAD == origin/main`, planning base `71a64562f17a4abc4dbef98d13f90ab72e76c9e5`
   is an ancestor, and this tracked handoff matches the absolute dispatch file.
4. Verify the `northstar` sibling link resolves to
   `/Users/tom/Dev/projects/northstar`; treat it as read-only.
5. Execute card 003 only. Record the reproduced defect before mutation. Try to
   falsify every oracle row, including missing, absolute, escaping, and
   adapter/manifest-disagreement paths.
6. Reconcile card 003, milestone 001, one dated log, this handoff, and local
   front doors. Keep card 004 blocked.
7. Run all required validation, integrate moved `origin/main` if necessary,
   revalidate, push, and open a PR against `main`. Link the card and evidence;
   report the exact head, replacement commit/tree/manifest identities, limits,
   and PR URL. Do not merge.
8. Stay on this agent and branch for requested changes. The orchestrator will
   post classified findings and explicitly wake this same worker.

### Review and merge path

The orchestrator reviews the exact current head independently. If changes are
requested, repair only those in-bounds findings on this branch. A
`planning-change` returns to the orchestrator first. Once the exact head is
accepted, checks pass, and the PR is mergeable, the orchestrator may merge
without another approval prompt.

- **Requested changes:** none
- **Closeout refs:** card 003, milestone 001, dated log, handoff, docs and
  roadmap front doors
