---
title: Build TypeScript package source worker handoff
kind: northstar-handoff
handoff_mode: worker-pr-loop
worker_mode: implementation
dispatch_authority: orchestrator
handoff: single-file-path-only
status: awaiting-review
owner: repo maintainers
created: 2026-09-02
updated: 2026-09-02
handoff_path: /Users/tom/Dev/projects/northstar-language-packs/docs/handoffs/20260902-185135-build-typescript-package-source.md
base_required: pushed-main
tags: [coordination, handoff, worker, pr, typescript, packages]
---

## What This Thread Was Doing

Northstar card `g02.048/118` made the first language-package canary ready. This
repository now has the public source boundary and one local ready card. This
dispatch owns only the first immutable TypeScript package-source candidate.

No transcript or second prompt is part of the authority chain.

## Why It Matters

Northstar must prove that a useful language-quality implementation can leave
the root skill without changing its rules, consumer policy, or evidence. This
source PR is the serial prerequisite for Northstar registry promotion and the
fresh Jetstream canary.

## Current State

- **Repository:** `inflatable-cookie/northstar-language-packs`
- **Planning branch:** `main`
- **Planning base commit:** `9e307f529bee78c4f76118dd4243aff6267d2d5d`
- **Pushed main verification:** local and `origin/main` matched at the planning
  base before this handoff commit
- **Planning checkout:** clean before this handoff
- **Worker mode:** implementation worker dispatched by the orchestrator; this
  handoff activates worker-only worktree preflight
- **Planning artifacts included at the base:** strict repository spine,
  `g01.001`, and batch card `g01.001/001`
- **Worker branch:** `worker/build-typescript-package-source`
- **Worker worktree:** `/Users/tom/.paseo/worktrees/0z9augi8/build-typescript-package-source`
- **Worktree creation command:** Paseo `branch-off` from `origin/main` with
  worktree slug `build-typescript-package-source`
- **Worker worktree policy:** launcher worktree first; named/manual fallback
  only when required by the completion protocol
- **Required sibling worktree links:** link `northstar`, source
  `/Users/tom/Dev/projects/northstar`, destination `northstar` in this
  worktree's container directory. The Paseo lifecycle must create and verify it
  before the worker starts.
- **Active spec lane:** upstream Northstar spec 034 and card `g02.048/118` at
  `3f360be97759abf658867e062a30edc3b9c8c597`
- **Roadmap milestone:** `docs/roadmaps/g01/001-typescript-package-source.md`
- **Ready cards, in order:** none; local card `g01.001/001` is complete and in
  review
- **Allowed runway:** one package-source card only
- **Remaining card budget:** zero
- **Dispatch topology:** sole ready lane. Northstar registry work is serial on
  this accepted immutable source; Jetstream is serial on the registry merge.
- **Parallel safety check:** no other source-package worker is active
- **Surfaces this lane owns:** `packages/typescript/**`, package-local QA and
  fixtures, the local milestone/card/log/handoff, local roadmap/docs front
  doors, and directly matching `PAPERCUTS.md` evidence
- **Integration ownership:** the orchestrator owns upstream Northstar registry,
  migration closeout, and Jetstream dispatch; do not edit those repositories
- **Merge ordering:** same-repository PRs merge one at a time; the orchestrator
  refreshes and re-reviews changed heads
- **Canonical refs:** `docs/architecture/system-architecture.md`;
  `docs/contracts/001-working-rules.md`; pinned upstream Northstar
  `docs/architecture/system-architecture.md`,
  `docs/contracts/004-language-quality-pack.md`,
  `docs/specs/034-modular-language-quality-packages.md`, and
  `docs/roadmaps/g02/batch-cards/118-extract-typescript-svelte-language-package.md`
  at `3f360be97759abf658867e062a30edc3b9c8c597`
- **Review oracle:** local batch card `## Review Oracle` plus upstream card 118
- **Model capability profile:** day-to-day/mechanical package worker; the
  semantics and five-row source oracle are settled
- **Frontier-worker justification:** none
- **Tool/runtime restrictions:** no release mutation, registry edit, consumer
  edit, Rust extraction, `.github/workflows/` edit, or hidden compatibility
  fallback
- **Required validation:** `effigy qa`, `effigy qa:docs`, direct staged-package
  self-check, pinned 17-file source parity, exact 20-file source/staged
  inventory, all five local oracle counterexamples, and
  `git diff --check origin/main...HEAD`
- **PR base/head:** `main` <- `worker/build-typescript-package-source`
- **PR URL:** https://github.com/inflatable-cookie/northstar-language-packs/pull/1
- **Review state:** awaiting orchestrator exact-head review
- **Merge path:** orchestrator after accepted exact-head review and passing
  required checks

## Boundaries

- **In scope:** relocate the pinned 17-file TypeScript payload into the exact
  initial 20-file package, add its manifest/catalogue/self-check, refactor only
  task-source resolution, prove it, and open the source PR.
- **Out of scope:** Northstar core/registry/fallback, Jetstream, Rust, semantic
  rule changes, consumer policy/evidence migration, release publication, and
  merge.
- **Outcome shape:** complete source candidate with immutable identity inputs,
  local closeout, validation, and reviewable PR.
- Do not invent architecture, widen the card, or choose a new package protocol.
- Work only in the clean worker worktree selected by the completion protocol.
- Do not merge the PR.

## Important Context

- **Planning lineage:** Northstar PR 22 merged the generic lifecycle at
  `75db6f5`; readiness promotion is Northstar commit `3f360be`.
- **Why this card is ready:** repository topology, package identity, version,
  core range, workflow, overlays, source inventory, package shape, runtime
  capabilities, self-check form, and review oracle are settled.
- **Pinned source:** read upstream bytes with
  `git -C ../northstar show 3f360be:<path>`. Do not use moving working-tree
  bytes as extraction evidence.
- **The 17 source paths:**
  - `skills/northstar/assets/templates/language-quality/typescript/AGENTS.md`
  - `skills/northstar/assets/templates/language-quality/typescript/typescript-quality-deviations.json`
  - `skills/northstar/assets/templates/language-quality/typescript/typescript-quality-profile.json`
  - `skills/northstar/commands/northstar-typescript-audit/SKILL.md`
  - `skills/northstar/commands/northstar-typescript-audit/agents/openai.yaml`
  - eight files below
    `skills/northstar/references/language-quality/typescript/`
  - `skills/northstar/references/modes/typescript-quality-audit.md`
  - `skills/northstar/scripts/check-typescript-quality.rhai`
  - `skills/northstar/scripts/typescript-quality-recorder.rhai`
  - `skills/northstar/scripts/typescript-quality-setup.rhai`
- **Relocation map:** command skill -> package-root `SKILL.md`; command agent
  metadata -> `agents/openai.yaml`; all other source paths keep their suffix
  below `skills/northstar/`. Add only package-root `northstar-package.json`,
  package-root `effigy.toml`, and executable `scripts/self-check.sh`.
- **Source baseline digest:**
  `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`.
  Reproduce and explain the digest method before relying on it.
- **Open tensions:** none remaining in this lane. Package Rhai resolves assets
  from Effigy `catalog_root`; `repo_root` stays the consumer target.
- **Identities:** source-list digest
  `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`;
  package-tree digest
  `sha256:0fcd5c58296f168895b66f2472621d49761f7786ea2ad1ebeefb801040967d6b`;
  manifest digest
  `sha256:ed95883c428ef43f0f02d38d60bf8d50e6e29313f5751c1b2a5744157a5b5362`.
- **Report after:** package shape plus source/staged parity is complete, or an
  earlier stop condition is reached.
- **Report to:** this Paseo orchestrator through finish notification.

## Suggested Next Move

Stop for orchestrator exact-head review of
https://github.com/inflatable-cookie/northstar-language-packs/pull/1.
Do not merge or start registry/Jetstream work.

## Completion Protocol

### Before you start

1. This handoff's worker metadata activates worker mode. Before broad reads,
   run `git rev-parse --show-toplevel`, `git branch --show-current`,
   `git status --porcelain`, and `git worktree list --porcelain`.
2. Accept a clean registered non-`main` launcher worktree regardless of its
   generated path or branch spelling. Do not create another worktree.
3. If the launcher context is dirty, `main`, unregistered, or unusable, stop
   and report it. Only a manual fallback may use `.agents.local.env` and its
   explicit `AGENTS_WORKTREE_CONTAINER_DIR`; never guess a path or discard
   state.
4. Run a bounded non-interactive `git fetch origin`. Require `HEAD ==
   origin/main`, require the planning base to be its ancestor, and load this
   tracked handoff from `HEAD`. Stop if the absolute dispatch file differs.
5. Verify the `northstar` sibling link in the worktree container directory
   resolves exactly to `/Users/tom/Dev/projects/northstar`. Never replace or
   overwrite a mismatch.
6. Read `AGENTS.md`, the local milestone/card, and pinned upstream refs. Run
   cheap orientation only after this worktree decision.

### While you work

- Execute the one local card in meaningful commits.
- Use ordinary implementation judgment inside the settled relocation and
  task-source boundary. Return any protocol or semantic choice to planning.
- Report a meaningful chunk or blocker through Paseo. Do not edit the planning
  checkout or upstream/consumer repos.

### When the assigned runway is complete

1. Run every required validation named above.
2. Falsify all exact/universal/negative claims and every local/upstream oracle
   row in scope. Record the proof map.
3. Reconcile the local card, milestone, one dated log, this handoff, and local
   front doors. Record actual worktree, branch, source inventory, package tree
   digest, and manifest digest.
4. Fetch current `main`; integrate it if it moved, then revalidate.
5. Push the worker branch and open a PR to `main`. Link the local card, pinned
   upstream card, changed surfaces, immutable identity inputs, proof, validation,
   and unresolved limits.
6. Report PR URL and exact tested head. Do not merge or start downstream work.

### Review and merge path

The orchestrator reviews the exact head independently. Shared GitHub identity
means an accepted verdict may be a PR comment rather than formal approval. If
changes are requested, the orchestrator will post classified findings and wake
this same worker. Requested changes: none.

- **Closeout refs:** local card, milestone `g01.001`, dated log, this handoff,
  `docs/README.md`, `docs/roadmaps/README.md`, generation index, and g01 runway.

### Handoff closeout

Leave the local authority chain honest. Stop on a blocker instead of claiming a
candidate exists. This runway ends at the package-source PR.
