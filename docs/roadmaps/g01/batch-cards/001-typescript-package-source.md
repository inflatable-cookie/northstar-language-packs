# 001 — Build TypeScript Package Source

Status: complete
Owner: repo maintainers
Updated: 2026-09-02
Upstream authority: Northstar card `g02.048/118` at
`3f360be97759abf658867e062a30edc3b9c8c597`

## Objective

Relocate the exact embedded TypeScript quality payload into the initial
20-file `packages/typescript` package without changing semantics.

## Scope

- relocate the pinned 17-file Northstar payload;
- add package manifest, package-local Effigy catalogue, and executable direct
  self-check wrapper;
- refactor only asset-root resolution so installed task source and consumer
  target remain distinct;
- prove exact package inventory, self-check, and source/install parity;
- record the candidate source commit inputs and package identities.

Do not edit Northstar core, its registry, Jetstream, package rule meaning,
consumer profiles/deviations, or the Rust payload. Do not publish a release or
merge the PR.

## Acceptance

- [x] `packages/typescript` contains the exact 20-file initial package shape;
- [x] manifest identity is `@northstar/typescript-quality` `0.1.0`, core range
  `>=0.2.0 <1.0.0`, workflow `explicit_audit_repair`, overlays `base`,
  `svelte`, and `sveltekit`;
- [x] the nine normative rules, evaluation-only signal, revision-S behavior,
  schemas, templates, and retained limitations are byte- or meaning-exact;
- [x] package scripts use task-source/catalog context for package assets and
  consumer target context for audit scope;
- [x] direct self-check declares and enforces `effigy` plus `sh` capabilities;
- [x] source/self-check parity and package-local QA pass;
- [x] no Rust or unrelated Northstar payload appears in source or staged
  package inventories;
- [x] local card, milestone, log, handoff, and front doors are honest.

## Review Oracle

| Invariant | Counterexample | Expected stop | Proof |
| --- | --- | --- | --- |
| Extraction is exact. | One embedded TypeScript surface is omitted or rewritten semantically. | Parity fails before PR. | Pinned 17-file source map and content comparison. |
| Package is independent. | Staging includes Rust or a root Northstar file. | Inventory rejects it. | Exact 20-file staged inventory. |
| Source and target differ. | Recorder loads catalogue below consumer `repo_root`. | Audit stops before evidence. | Distinct task-source/consumer fixture. |
| Self-check is real. | Wrapper is missing, non-executable, or a declared command is unavailable. | Activation candidate fails. | Direct self-check positives and negatives. |
| Workflow remains narrow. | Everyday TypeScript authoring becomes routable. | Manifest/check rejects it. | Negative workflow fixture. |

## Validation

- package-local `effigy qa` and `effigy qa:docs`;
- direct self-check from a staged package root;
- pinned source-to-package and source-to-staged parity;
- all review-oracle counterexamples;
- `git diff --check origin/main...HEAD`.

## Stop Conditions

- rule meaning, workflow availability, evidence schema, or consumer policy
  would change;
- the frozen manifest/host contract cannot express the package honestly;
- an upstream source surface is ambiguous or its pinned bytes cannot be read;
- validation requires registry, consumer, or Rust work;
- a new product or protocol decision is needed.

## Completion Notes

Worker `worker/build-typescript-package-source` in Paseo worktree
`/Users/tom/.paseo/worktrees/0z9augi8/build-typescript-package-source`
relocated the pinned 17-file payload from Northstar `3f360be` into the 20-file
package. Twelve surfaces are byte-exact. Two JSON files
(`audit-manifest.schema.json`, `strict-audit.json`) are meaning-exact after
stripping a pinned extra EOF blank line so `git diff --check origin/main...HEAD`
is green. The three Rhai scripts resolve assets from Effigy `catalog_root` and
keep `repo_root` as the consumer target.

Source-list digest method: SHA-256 of the GNU `sha256sum` listing
(`<file-sha256>  <original-path>\n`) over the 17 pinned paths. Reproduced
digest `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`.
Package-tree digest
`sha256:0fcd5c58296f168895b66f2472621d49761f7786ea2ad1ebeefb801040967d6b`.
Manifest digest
`sha256:ed95883c428ef43f0f02d38d60bf8d50e6e29313f5751c1b2a5744157a5b5362`.

The thin adapter and audit mode still name Northstar-root routing. Registry
and consumer activation stay orchestrator-owned.

## Next Task

Stop for orchestrator exact-head review of the source PR. Do not merge, pin,
or start Jetstream work from this card.
