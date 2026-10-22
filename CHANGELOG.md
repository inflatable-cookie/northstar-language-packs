# Changelog

## Unreleased

- Release `@northstar/rust-quality` `0.2.3`. The manifest declares one
  buildable `tool`: Northstar's lifecycle builds it during acquisition into its
  own cache with an explicit target directory and records the absolute binary in
  the installation receipt, so no agent runs a hand bootstrap and no build can
  write into the immutable install. `tool-bootstrap.md` now reads that record
  and keeps only the pinned audit scanner. Everyday authoring is opt-in per
  repository (`everyday_authoring: true` in the language-quality activation
  marker): setup installs the activation block and records that setting only
  with `--everyday-authoring`, and an opted-in repository whose pack cannot
  resolve reports `degraded` with its own Validate checks as the fallback
  instead of failing ordinary work. Explicit audit still fails closed.
- Release `@northstar/typescript-quality` `0.2.2`. `0.2.1` is pinned by
  Northstar, so this repair ships as a new immutable identity. The installed
  proof no longer expects the Effigy args echo; it asserts exit status 0 and no
  usage error. Setup skips the single Effigy relay boundary before its usage
  check and tests that skip.
- Release `@northstar/rust-quality` `0.2.2`. `0.2.1` is pinned by Northstar, so
  this repair ships as a new immutable identity. The installed proof takes the
  pinned Northstar source from `NORTHSTAR_SOURCE` or a third argument and fails
  plainly without it, so a Queue worker can run it from its own checkout. Setup
  skips the single Effigy relay boundary before its usage check and tests that
  skip.
- Release `@northstar/rust-quality` `0.2.1`. Tool bootstrap and the installed
  proof build `tools/rust-quality` with `--target-dir` outside the package.
  Cargo no longer writes `target/` into the immutable installed tree. Installs
  already polluted by `0.2.0` need operator repair; the store refuses to
  overwrite them.
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
