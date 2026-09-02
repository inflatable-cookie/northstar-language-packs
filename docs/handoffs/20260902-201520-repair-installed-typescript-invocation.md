---
title: Repair installed TypeScript invocation worker handoff
kind: northstar-handoff
handoff_mode: worker-pr-loop
worker_mode: implementation
dispatch_authority: orchestrator
handoff: single-file-path-only
status: awaiting-review
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
- Worker branch: `worker/repair-installed-typescript-invocation`.
- Worktree: `/Users/tom/.paseo/worktrees/0z9augi8/repair-installed-typescript-invocation`.
- Card 002 is implemented. Public invocation is
  `effigy skill run --path <installed-package-root> typescript-quality:{setup,record} --repo <consumer-root> -- <args>`.
- Replacement identities:
  tree `sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a`,
  manifest `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`.
- Evidence: `docs/logs/2026-09/02-202944-repair-installed-typescript-invocation.md`.
- Northstar sibling, registry, and Jetstream were not edited.
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

## Important Context

Effigy already expresses the required public surface:
`effigy skill run --path <SKILL_DIR> <SELECTOR> [--repo <CONSUMER>] [-- <ARGS>]`.
The installed package catalogue alias is `typescript-quality`, not `northstar`.
A decoy consumer may expose a `northstar` catalogue; that catalogue must not
win when the task source is `--path <installed-package-root>`.

## Suggested Next Move

Open the reviewable PR, then stop. Orchestrator exact-head review owns
acceptance, merge, and the Northstar registry repin.

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
