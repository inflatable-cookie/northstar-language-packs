# Changelog

## Unreleased

- Route the maintained Rust engine tests and the installed-route proof through
`oxide`. `effigy test:rust-quality-engine` now runs `oxide test` with the same
manifest argument, so the intermediates use Oxide's shared slot while final
outputs stay in `tools/rust-quality/target`; there is no `:cargo` escape
selector, and the package check rejects one reappearing with a plain-Cargo
engine route as its negative fixture. The installed-route proof's pinned
producer build, probe install, installed engine suite and the manifest's own
tool recipe run under `oxide exec` with their private `--target-dir` unchanged,
so final outputs stay in the proof's own directories and the intermediates use
the held slot; each throwaway copy carries a real empty `target` as Oxide's
documented opt-out from permanent-drive output adoption for a checkout that is
not a Git work tree, and the proof still rejects anything there but Cargo's
zero-byte lock placeholders, so the installed payload cannot collect build
output. The declared tool recipe stays a `cargo install` declaration that
Northstar's lifecycle owns and runs, the engine's own `cargo metadata` calls and
its `cargo_native`/`cargo_json` evidence names are unchanged, and the detector
fixtures still run their own pinned-toolchain Cargo. The engine's CLI fixtures
now give each fixture its own `CARGO_TARGET_DIR` under
`<fixture>/.git/northstar-test-target` and drop the inherited build directory:
Oxide exports one shared Cargo build directory, where Cargo gives two crates
with the same package name and version one unit, so unrelated fixtures could
otherwise alias and a passing fixture hide a failing one. The escapes are
Effigy's machine-wide `[programs.oxide] fallback = "cargo"` in the user config
or running Cargo by hand; nothing falls back silently. The repair produces
replacement package-tree and listing identities; the manifest bytes, version,
workflows, declaration and the Northstar core range are unchanged.

- Release `@northstar/typescript-quality` `0.2.3`. The installed-route proof
launches named `skill run` Effigy children from shell code, so its selector
declares `durable = true` (Effigy contract 052 §3.1) like the rust proof: a
foreground parent cannot acquire the late durable capability those children
need, and a declared capability selects durability for the whole tree before
go. Static task references propagate it, so the package QA group is durable too;
nested capability and admission inheritance are unchanged and no capability or
admission variable is unset. The catalogue raises `minimum_effigy_version` from
`0.12.0` to `0.15.0`, the Effigy release line that declares durable tasks, so a
runner without it refuses plainly instead of failing to parse the catalogue.
That Effigy floor is the compatibility change behind the version bump;
workflows, declaration, package shape and the Northstar core range are
unchanged. The repair produces a replacement package-tree, listing and manifest
identity.

- Add covering nonmutating format checks for maintained package sources. The
root `effigy format:check` selector, the same selector in both package
catalogues, and the repository `format:check` inventory check maintained shell
sources with `shfmt` (mvdan/sh v3) in `--diff` mode under the declared
`--indent 4 --language-dialect posix` style, so they report unformatted sources
and never rewrite a file. They fail closed when `shfmt` is absent, and the root
selector also fails when a maintained shell or Rhai source is undeclared or when
a package catalogue stops naming its own shell files. Rhai has no maintained
formatter, so the root selector declares that bounded limitation instead of
claiming format coverage it cannot prove. `effigy test:format-check` proves a
finite malformed fixture fails, its formatted control passes, and neither file
is rewritten. Both installed-route proof scripts now carry the declared shell
style, and each manifest gains `format:check` as an optional selector. The
repair produces replacement package-tree, listing and manifest identities;
versions, workflows, declaration and the Northstar core range are unchanged.

- Release `@northstar/rust-quality` `0.2.4`. The installed-route proof launches
named and `skill run` Effigy children from shell code, so its selector and the
root package-identity selector that shells into the same proof declare
`durable = true`; the declared capability makes their QA groups durable too.
Both catalogues raise `minimum_effigy_version` to `0.15.0`, the Effigy release
line that declares durable tasks, so a runner without it refuses plainly
instead of failing to parse the catalogue. That Effigy floor is the
compatibility change behind the version bump; workflows, declaration, package
shape and the Northstar core range are unchanged. The repair produces a
replacement package-tree, listing and manifest identity.

- Repair `@northstar/rust-quality` `0.2.3` evidence classification. Unstructured
output is now classified by the diagnostic each line begins instead of by any
`warning` word inside it: a line is a warning only when its first token is
`warning:` or a coded `warning[...]`, or when `warning:` follows a rustc
short-format `path:line:column:` position. A passing nextest or libtest line
whose test name contains `warning` therefore stays `note` evidence and no
longer turns a clean test record into a warning, while compiler, cargo, runner
and stderr warnings, `failed` exit precedence and `unavailable` startup
failures are unchanged and no output line is dropped. New engine fixtures cover
passing nextest and standard test lines with warning identifiers, compiler and
runner warning prefixes, supported structured events, stderr warnings, mixed
output, nonzero exits and startup failures. The repair produces a replacement
package identity inside the `0.2.4` change above; workflows, declaration and
the Northstar core range are unchanged.

- Repair `@northstar/rust-quality` `0.2.3` everyday closeout identity. A dirty
worktree closeout binds `source_identity` to the bytes it tested: every dirty
path with its Git status and worktree content, including staged, working,
untracked, deleted and symlinked paths. Two tranches with identical paths and
statuses but different content no longer share an identity, so a content-only
change is a new source instead of a rejected repeat; `snapshot_sha256` stays a
metadata digest. Evidence lives in ordered, immutable `attempt-<n>` directories
per source identity: an unchanged successful plan reuses its attempt, a failed
selector or startup capture is retried as a new attempt without a source or
status change, and earlier attempts are never overwritten. A successful
capture of a different request, a record stamped with another source identity,
and a missing attempt ordinal fail closed. New engine fixtures cover
content-only changes, staged and working bytes, untracked and deleted paths,
failed-selector and startup retries, unchanged reuse, and mismatched or
tampered attempt history. The repair produces a replacement package identity;
the version, workflows, declaration and compatibility range are unchanged.

- Repair `@northstar/rust-quality` `0.2.3` everyday closeout. `inspect` and
`closeout` take an explicit committed tranche (`--scope committed --base <rev>
--head <rev>`, and `--base/--head` on `closeout`). The tool resolves exact
commit identities, rejects an invalid revision, a non-ancestor, empty or
anchorless range, a checkout that is not the range head, and any committed path
dirty in the worktree. It records the changed Rust anchors, the Cargo packages
and workspace roots the range corrects, and the dirty files it preserved
outside the tranche. Evidence is stored and stamped under the exact range
identity: an identical request is reused without rerunning, and a repeat of the
same plan still reports every applicable class it already holds, including a
sealed `unrun` limitation for a class no request named. A record from another
range or another request fails closed instead of being substituted.
New engine fixtures cover clean pinned heads, a real Rust change, empty and
no-Rust ranges, invalid and unbounded revisions, checkout mismatch, dirty range
paths, dirty-state preservation, reuse, and mismatched or stale evidence. The
repair produces a replacement package identity; the version, workflows,
declaration and compatibility range are unchanged.

- Repair `@northstar/rust-quality` `0.2.3` discovery. `inspect` reports exactly
the workspaces Cargo resolves: a workspace-inheriting manifest with no
workspace root, and a manifest its resolved enclosing workspace does not own
or exclude, stays out of the inventory instead of failing discovery. Malformed
real members and broken member inheritance still fail closed. New engine
fixtures cover root members, an independent nested workspace, unowned
templates, malformed members, unrelated content and deterministic
attribution. The repair produces a replacement package identity. `oxide init`
adopts the repository; the engine suite stays on plain Cargo because its
fixtures run Cargo themselves and Oxide's inherited target directory changes
those results.

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
