# Northstar Language Packs

This repository owns official optional language-quality package source and
release evidence. Northstar core owns discovery, trust, installation,
activation, and routing protocol. It must never make a consumer install or load
a language it did not request.

## Where things live

- Current state: `docs/README.md`
- Knowledge (one owner per fact): `docs/knowledge/README.md`
- Retired concepts, which must not come back: `docs/knowledge/retired.toml`
- Open questions: `docs/knowledge/questions.md`
- Tool and process friction: Queue papercuts, filed with `papercut.add` (see
  the `northstar` skill). The repository holds no papercut file or triage folder.

The plan (lanes, their documents and their order), leads, papercuts, brief
drafts, tasks and status live in Queue, never in this repository. Read what's
next with `plan.get` (see the `northstar` skill).

## Commands

Commands go through Effigy from the repository root:

- `effigy tasks` — the task list
- `effigy doctor` — health and routing when something looks wrong
- `effigy test --plan` — test scope before choosing it
- `effigy qa` — the full repository check
- `scripts/verify-package-identities.sh` — the release-identity oracle

## Product rules

- Every package stays independently addressable. Installing one language must
  not retain or load sibling package content.
- Package manifests describe capability; they never grant their own trust or
  acquisition authority.
- Published identities are immutable commits and exact content digests, never
  moving branches or tags.
- Consumer profiles, deviations, repair authority, and evidence stay owned by
  the consumer repository.
- Keep package task-source paths distinct from consumer target paths.

## Guardrails

- Do not run release mutations or edit CI/workflow files without explicit
  operator authority.
- Do not edit Northstar core or a consumer repository from here.
- Do not copy a sibling package into another package's installed payload.
- Stop when extraction would change rule meaning, workflow availability,
  evidence schema, or consumer policy.
- When a change alters what is true, update the owning knowledge file in the
  same PR.
- An operator ruling given in conversation goes into its owning file before
  the thread ends.

Write in the short, blunt house style defined by
`docs/knowledge/contracts/writing-style.md`.

## Validate

`effigy qa` before opening a PR. Package work must also prove package-scoped
source/install parity, the change's negative oracle, and exact immutable
identity.
