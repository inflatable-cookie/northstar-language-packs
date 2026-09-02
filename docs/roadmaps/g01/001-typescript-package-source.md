# 001 — TypeScript Package Source

Status: active; card 003 ready for standalone adapter repair
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
- `batch-cards/003-repair-typescript-skill-entrypoint.md` repairs the remaining
  agent-facing adapter reference before Rust package work starts.

## Next Task

Execute card 003. Stop at a reviewable source PR with the replacement immutable
identity; Northstar owns its later registry repin.
