# 001 — Build TypeScript Package Source

Status: ready
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

- [ ] `packages/typescript` contains the exact 20-file initial package shape;
- [ ] manifest identity is `@northstar/typescript-quality` `0.1.0`, core range
  `>=0.2.0 <1.0.0`, workflow `explicit_audit_repair`, overlays `base`,
  `svelte`, and `sveltekit`;
- [ ] the nine normative rules, evaluation-only signal, revision-S behavior,
  schemas, templates, and retained limitations are byte- or meaning-exact;
- [ ] package scripts use task-source/catalog context for package assets and
  consumer target context for audit scope;
- [ ] direct self-check declares and enforces `effigy` plus `sh` capabilities;
- [ ] source/self-check parity and package-local QA pass;
- [ ] no Rust or unrelated Northstar payload appears in source or staged
  package inventories;
- [ ] local card, milestone, log, handoff, and front doors are honest.

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
- `git diff --check`.

## Stop Conditions

- rule meaning, workflow availability, evidence schema, or consumer policy
  would change;
- the frozen manifest/host contract cannot express the package honestly;
- an upstream source surface is ambiguous or its pinned bytes cannot be read;
- validation requires registry, consumer, or Rust work;
- a new product or protocol decision is needed.

## Next Task

Implement the package source, open the PR, and stop for exact-head review.

