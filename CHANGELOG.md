# Changelog

## Unreleased

- Update the TypeScript AGENTS template to use the installed-package route and
  release `@northstar/typescript-quality` `0.2.1`.
- Bump both language-quality packages to `0.2.0` for the breaking move of
  consumer profiles and deviations to `docs/knowledge/contracts/`. Consumers
  still using `docs/contracts/` must move those files before upgrading.
- Adopt lean Northstar: current truth moves to `docs/knowledge/`, intent to
  `docs/plan.md`; roadmaps, handoffs, logs and lifecycle records are removed.
- Add `@northstar/rust-quality` `0.1.0` source under `packages/rust` from the
  frozen 54-file Northstar source boundary.
- Make `@northstar/typescript-quality` `SKILL.md` load its package-local audit
  mode and prove installed-copy adapter path closure.
- Repair `@northstar/typescript-quality` `0.1.0` so installed setup/record run
  through `effigy skill run --path` against a separate consumer.
- Add `@northstar/typescript-quality` `0.1.0` source under `packages/typescript`.
- Repository created for independently addressable Northstar language packages.
