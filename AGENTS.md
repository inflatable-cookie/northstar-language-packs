# Northstar Language Packs

This repository owns official optional language-quality package source and
release evidence. Northstar core owns discovery, trust, installation,
activation, and routing protocol.

## What must stay true

- Every package remains independently addressable. Installing one language
  must not retain or load sibling package content.
- Package manifests describe capability; they never grant their own trust or
  acquisition authority.
- Published identities are immutable commits and exact content digests, never
  moving branches or tags.
- Consumer profiles, deviations, repair authority, and evidence remain owned by
  consumer repositories.
- Do not run release mutations or edit CI/workflow files without explicit
  operator authority.

## How work moves here

Normal agents follow the canonical docs in this checkout. Worker mode activates
only from an orchestrator-dispatched committed handoff; do not infer it from a
worktree, branch, or harness.

Use ready cards in `docs/roadmaps/`. Keep package implementation, evidence, and
closeout in one bounded lane. Triage is a temporary buffer, never execution
authority.

## Sharp edges

- Do not copy a sibling package into another package's installed payload.
- Keep package task-source paths distinct from consumer target paths.
- Stop when extraction would change rule meaning, workflow availability,
  evidence schema, or consumer policy.

## Finding your way

Start with `effigy tasks`. Use `effigy doctor` only for routing or environment
ambiguity. Use `effigy test --plan` when test shape matters. Prefer repository
selectors over raw commands and use `--repo <PATH>` only for another repo.

- `docs/README.md` — authority front door
- `docs/architecture/system-architecture.md` — repository/package boundary
- `docs/contracts/001-working-rules.md` — delivery and review rules
- `docs/roadmaps/README.md` — active lane and next task
- `docs/logs/README.md` — evidence
- `docs/triage/README.md` — unresolved capture

Write in the short, blunt house style defined by
`docs/policy/internal-writing-style.md`.

## What complete means

Run `effigy qa`. Package work must also prove package-scoped source/install
parity, the card's negative oracle, and exact immutable identity. Record small,
recurring execution friction in `PAPERCUTS.md` without widening the task.

