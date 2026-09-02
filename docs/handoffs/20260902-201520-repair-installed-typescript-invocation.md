---
title: Repair installed TypeScript invocation worker handoff
kind: northstar-handoff
handoff_mode: worker-pr-loop
worker_mode: implementation
dispatch_authority: orchestrator
handoff: single-file-path-only
status: ready
owner: repo maintainers
created: 2026-09-02
updated: 2026-09-02
handoff_path: /Users/tom/Dev/projects/northstar-language-packs/docs/handoffs/20260902-201520-repair-installed-typescript-invocation.md
base_required: pushed-main
tags: [coordination, handoff, worker, typescript, package, invocation]
---

## What This Thread Was Doing

Northstar PR 23's exact-head review falsified the first package source's
installed setup/record route. Card `g01.001/002` is the sole ready repair: fix
the external task invocation and produce a replacement immutable identity.

## Why It Matters

The registry must not make a package authoritative when only its self-check and
identity route work. A consumer needs the package's setup and recorder through
the same installed source/consumer target boundary that Jetstream will use.

## Current State

- Repository: `/Users/tom/Dev/projects/northstar-language-packs`.
- Planning branch: `main`; dispatch base is the commit containing this handoff.
- Worker branch: `worker/repair-installed-typescript-invocation`.
- Worktree: Paseo `branch-off` from pushed `main`, slug
  `repair-installed-typescript-invocation`.
- Required sibling: `/Users/tom/Dev/projects/northstar`, linked as
  `../northstar` for governing contract and independent comparison only.
- Ready card:
  `docs/roadmaps/g01/batch-cards/002-repair-installed-typescript-invocation.md`.
- Accepted but superseded source: merge `09ef1743dd8fc18bae3bf04fae791f1d7d4e5daf`,
  tree digest
  `sha256:0fcd5c58296f168895b66f2472621d49761f7786ea2ad1ebeefb801040967d6b`.
- Upstream review finding:
  https://github.com/inflatable-cookie/northstar/pull/23#issuecomment-5514983257.
- Allowed runway: card 002 only. Northstar registry repin and Jetstream remain
  serial behind accepted review and merge.
- Surfaces owned: `packages/typescript` invocation docs/scripts/fixtures,
  package-local validation, card 002, one dated log, this handoff, and directly
  dependent local front doors.
- Worker class: day-to-day. The failure and required public boundary are exact;
  no frontier reasoning remains after review.
- Required validation: every card-002 oracle, package QA, direct self-check,
  exact installed setup/record proof against a decoy consumer, repository QA,
  independent canonical identity, and
  `git diff --check origin/main...HEAD`.
- PR base/head: `main` <- `worker/repair-installed-typescript-invocation`.
- Merge path: orchestrator after accepted exact-head review and checks.

## Boundaries

- Repair the external package only. Do not edit the Northstar sibling,
  registry, Jetstream, Rust, package version, rule meaning, or consumer policy.
- Preserve task-source/consumer-target separation. Do not make a consumer
  checkout or embedded Northstar catalogue the source of package assets.
- Treat the valid Effigy relay sentinel as transport syntax, not a package
  operation. Normalize it once before setup/recorder dispatch and prove the
  raw valid public invocation.
- Do not replace operational proof with direct script execution or package-
  local self-tests. The oracle must use `effigy skill run --path` with a
  distinct consumer and no available `northstar` catalogue.
- Return a planning stop if the existing Effigy surface cannot carry the
  invocation honestly.
- Never merge the PR or mutate the sibling.

## Suggested Next Move

Reproduce both review failures from the materialized main package. Map the
smallest docs/script changes, initialize decoy consumer fixtures, then prove
setup and at least the recorder lifecycle operations through the installed
public surface before recomputing identity.

## Completion Protocol

1. Verify clean worker head equals pushed `origin/main` and this handoff is
   tracked byte-for-byte.
2. Execute card 002 only. Record findings before mutation and keep package
   policy/evidence semantics unchanged.
3. Falsify all five oracle rows using the exact public invocation and a
   separate decoy consumer.
4. Run required validation, recompute package tree/manifest identities, and
   reconcile card 002, milestone 001, one dated log, this handoff, and local
   front doors.
5. Integrate moved `origin/main` if necessary, revalidate, push, and open a
   reviewable PR with exact head and limits.
6. Report through Paseo and stop. Stay on the branch for classified findings;
   do not merge.
