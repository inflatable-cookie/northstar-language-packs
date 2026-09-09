# Flattened-Task Switchover

Date: 2026-09-09
Result: g01 flattened to the generation README; no active Northstar task remains

## Outcome

g01 is the only expanded generation. No historic generation exists, so no
archival compaction ran. The milestone wrappers and `batch-cards/` held only
completed, merged work. Both outcomes collapsed into `docs/roadmaps/g01/README.md`,
which is now the sole roadmap and frontier. Remaining registry promotion and
the Convergence canary are Northstar-owned; this repository dispatches nothing
until Northstar returns a new pinned source boundary.

## Classification

- `g01` — active. Sequential current generation. Both package outcomes merged.
  No executable repo-owned work remains.
- Historic generations — none. No `docs/roadmaps/archive/` roll-up needed.

## Preservation Manifest

Exact deletions (nothing else):

- `docs/roadmaps/g01/001-typescript-package-source.md`
- `docs/roadmaps/g01/002-rust-package-source.md`
- `docs/roadmaps/g01/batch-cards/001-typescript-package-source.md`
- `docs/roadmaps/g01/batch-cards/002-repair-installed-typescript-invocation.md`
- `docs/roadmaps/g01/batch-cards/003-repair-typescript-skill-entrypoint.md`
- `docs/roadmaps/g01/batch-cards/004-build-rust-package-source.md`

No unique live rule lived only in those files; authority stays on
`docs/architecture/system-architecture.md` and
`docs/contracts/001-working-rules.md`. No open repo-owned commitment remains;
the identity handoff and promotion lanes are Northstar-owned by boundary.
Material evidence stays in git history and the logs below.

## Old-To-New Map

- Milestone `g01.001` + batch cards 001/002/003 → collapsed. Outcome:
  `@northstar/typescript-quality` `0.1.0` under `packages/typescript`,
  merged as `09ef174`, repaired as `d18dc33b`, adapter-closed in PR 3
  (`c9ef2a2`). Current tree
  `sha256:259cccdbacd7e2e293389efaf72cab005d0c275bd7cb600c99f30bfbfe071843`,
  manifest
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`.
  No successor task.
- Milestone `g01.002` + batch card 004 → collapsed. Outcome:
  `@northstar/rust-quality` `0.1.0` under `packages/rust`, merged in PR 4
  (`56b2e11`). Current tree
  `sha256:e5cf9c5da4a30c0f5164f2ea0c5e9d87d544c0c32f09f3c139a386c56154dba0`,
  manifest
  `sha256:dd71d04efd67cc7805f417a79666dd920ea1811ee252d941108dfbeca8aab612`.
  No successor task.
- New Northstar tasks: none. Explicit absence, recorded in the g01 README.

## Validation

- `effigy qa`, `effigy qa:docs`, `scripts/verify-package-identities.sh` pass.
- `git diff --check` clean.
- No live front door references `batch-cards/`, a milestone wrapper, or an
  old `g01.NNN/NNN` card ID. Closed handoffs and logs keep historic wording.
