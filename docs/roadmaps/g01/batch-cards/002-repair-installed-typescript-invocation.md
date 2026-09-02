# 002 — Repair Installed TypeScript Invocation

Status: complete; merged through PR 2 as `d18dc33b`
Owner: repo maintainers
Updated: 2026-09-02
Upstream finding: Northstar PR 23 exact-head review at `057dd2841c1e6d81abb0955fe6d8a3572c173638`

## Objective

Make the accepted TypeScript package operational as an installed external task
source without changing language policy, workflow availability, consumer
authority, or evidence meaning.

## Reproduced Defect

- The package mode and recording contract still invoke
  `northstar/typescript-quality:*` below an `<installed-northstar>` root. A
  materialized package has only the `typescript-quality` catalogue, so the
  documented setup command fails with `task catalog prefix 'northstar' not
  found`.
- `effigy skill run` relays task arguments with a leading `--` sentinel. The
  relocated setup and recorder scripts inspect `args` directly and reject the
  valid external invocation at their usage guard.
- Northstar's canary transcript proved identity, self-check, installation, and
  resolve, but never executed installed setup or recorder operations against a
  separate consumer.

## Scope

- make the mode and recording contract use the installed package root as task
  source and an explicit consumer repository as target;
- normalize the external-task relay sentinel in every package script that
  accepts task arguments;
- add a package-owned operational proof that runs setup and recorder through
  the exact installed/public Effigy surface against a decoy consumer with no
  embedded Northstar task catalogue;
- preserve all policy/rule/profile/schema/template meaning and the explicit-
  audit-only boundary;
- recompute the package tree digest and record the replacement source commit,
  manifest digest, and validation evidence.

Do not edit Northstar core or its registry, Jetstream, Rust, package version,
rule meaning, evidence schema, or consumer policy. Do not merge.

## Acceptance

- [x] the package mode and recording contract contain no embedded
  `northstar/typescript-quality:*` invocation;
- [x] installed setup runs through `effigy skill run --path <package-root>`
  with the consumer supplied separately and applies package-owned assets;
- [x] installed recorder operations receive their relayed arguments and bind
  the package-owned catalogue while writing only to the consumer target;
- [x] a consumer decoy embedded catalogue cannot win task-source resolution;
- [x] the old documented command and unnormalized-argument variants are
  explicit negative fixtures;
- [x] package-local QA, direct self-check, installed operational proof,
  source/staged parity, repository QA, and
  `git diff --check origin/main...HEAD` pass;
- [x] replacement commit and package identities are recorded honestly.

## Review Oracle

| Invariant | Counterexample | Expected stop | Proof |
| --- | --- | --- | --- |
| Installed source owns execution. | Setup resolves the `northstar` catalogue or a consumer decoy. | Fail before mutation. | Materialized package + decoy consumer run. See `docs/logs/2026-09/02-202944-repair-installed-typescript-invocation.md`. |
| Relay arguments survive. | Setup/record see `--` as the operation. | Usage guard must not fire for a valid skill-run relay. | Exact public command transcript. |
| Consumer stays the target. | Package task writes policy/evidence below its own installed root. | Attribution/identity proof fails. | Before/after package and consumer inventories. |
| Policy is unchanged. | Repair changes rule, overlay, workflow, schema, or template meaning. | Parity fails before PR. | Pinned semantic/source comparison. |
| Replacement identity is exact. | Recorded tree digest names the old or dirty payload. | Identity proof fails. | Independent canonical digest reproduction. |

## Stop Conditions

- Effigy cannot express external task arguments or distinct task-source/target
  invocation without a runtime change;
- repair requires changing package policy, evidence format, workflow
  availability, or consumer files outside the fixture;
- a new package version or protocol decision is required;
- validation changes the plan.

## Completion Notes

Worker `worker/repair-installed-typescript-invocation` in Paseo worktree
`/Users/tom/.paseo/worktrees/0z9augi8/repair-installed-typescript-invocation`
reproduced both review failures from the materialized `origin/main` package,
then repaired invocation only.

Public command:

```text
effigy skill run --path <installed-package-root> typescript-quality:setup --repo <consumer-root> -- apply <absolute-target-root> <scope-directory>
effigy skill run --path <installed-package-root> typescript-quality:record --repo <consumer-root> -- <operation> ...
```

Setup and recorder strip one leading `--` before dispatch, matching
Northstar's `paseo-worktree.rhai` pattern. `scripts/prove-installed-invocation.sh`
runs those commands against a decoy consumer whose catalogue alias is
`northstar`. Package version remains `0.1.0`.

Replacement identities:

- package-tree digest
  `sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a`
- manifest digest
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`

Superseded identities remain `09ef174` /
`sha256:0fcd5c58296f168895b66f2472621d49761f7786ea2ad1ebeefb801040967d6b` /
`sha256:ed95883c428ef43f0f02d38d60bf8d50e6e29313f5751c1b2a5744157a5b5362`.

## Next Task

Card 003 owns the later standalone agent-facing adapter defect. Do not reopen
setup/record invocation from this card.
