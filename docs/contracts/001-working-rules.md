# Working Rules

## Authority

Northstar core contract 004 and roadmap card g02.048/118 own the migration
protocol and canary acceptance. This repository owns package-source structure,
release evidence, and its reviewable source PR.

## Delivery

- Execute only ready local cards and their pinned upstream authority.
- Worker lanes use committed handoffs, dedicated worktrees, pushed branches,
  reviewable PRs, and no worker-side merge.
- Universal, exact, and negative claims require a counterexample and proof.
- Preserve consumer policy and evidence formats; return semantic changes to
  Northstar planning.
- Keep package and closeout edits in meaningful commits.

## Review And Merge

The orchestrator reviews the exact current head against local and pinned
upstream oracles. Changes requested are repaired by the originating worker.
After accepted review, required checks, and mergeability, the orchestrator may
merge without a second approval prompt.

## Closeout

Reconcile the local card, milestone, log, handoff, and front doors. Record the
source commit and exact package identities. Do not start registry promotion or
consumer canary work from this repository.

