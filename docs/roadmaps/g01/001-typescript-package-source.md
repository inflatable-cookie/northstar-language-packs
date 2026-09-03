# 001 — TypeScript Package Source

Status: active; card 003 implemented, reviewable PR open
Owner: repo maintainers
Upstream authority: Northstar `g02.048/118` at
`3f360be97759abf658867e062a30edc3b9c8c597`

## Objective

Deliver the first independently addressable TypeScript/Svelte package source
and immutable candidate evidence. Stop before Northstar registry promotion or
Jetstream activation.

## Execution

- `batch-cards/001-typescript-package-source.md` produced the accepted initial
  source in PR 1, merged as `09ef174`.
- `batch-cards/002-repair-installed-typescript-invocation.md` repaired the
  installed setup/record invocation and recorded the replacement identity.
  PR 2 merged as `d18dc33b`; Northstar pinned and accepted that identity.
- `batch-cards/003-repair-typescript-skill-entrypoint.md` made the
  agent-facing adapter load its package-local mode and proved installed-copy
  path closure. Its reviewable PR carries the replacement identity.

## Next Task

After card 003's exact-head acceptance and merge, return the replacement
immutable identity to Northstar card 121 for registry repinning. Card 004
stays blocked until then.
