# 003 — Repair TypeScript Skill Entrypoint

Status: ready
Owner: repo maintainers
Updated: 2026-09-03
Upstream authority: Northstar card `g02.048/121` at
`a5d057134d2ed0fc242782093207077c2cff824f`

## Objective

Make the TypeScript package's advertised command skill independently usable
without changing its language policy or operational Effigy workflows.

## Reproduced Defect

`packages/typescript/SKILL.md` tells the agent to load
`references/router.md` from the main Northstar skill. That path is absent from
the package. The installed setup/record proof never reads the command skill,
so package QA accepted a broken direct `$northstar-typescript-audit` adapter.

## Scope

- make the command skill load the package's declared
  `references/modes/typescript-quality-audit.md` directly;
- keep it thin: no copied router, duplicated rules, or new workflow;
- add a deterministic installed-copy check that resolves every path loaded by
  the adapter inside the package root;
- prove a missing, absolute, or escaping adapter reference fails closed;
- preserve the package version, manifest semantics, TypeScript rules,
  profiles, schemas, setup/record behavior, and consumer bytes;
- record the replacement commit, package-tree digest, and manifest digest.

Do not edit Northstar, Jetstream, Rust, the registry, or the package protocol.
Do not merge from the worker lane.

## Acceptance

- [ ] `SKILL.md` loads only package-local files that exist in the installed
  payload;
- [ ] its route matches manifest workflow `explicit_audit_repair`;
- [ ] `agents/openai.yaml` still invokes `$northstar-typescript-audit` and
  implicit activation remains disabled;
- [ ] missing, absolute, and escaping adapter paths are rejected by package QA;
- [ ] policy, package version, manifest meaning, and operational tasks remain
  unchanged;
- [ ] source/staged parity, direct self-check, installed setup/record proof,
  package QA, repository QA, and `git diff --check` pass;
- [ ] replacement immutable identities are recorded honestly.

## Review Oracle

| Invariant | Counterexample | Expected stop | Proof |
| --- | --- | --- | --- |
| Adapter is standalone. | It loads `references/router.md` or any absent path. | Package QA fails. | Materialized installed-copy path closure. |
| Adapter stays thin. | It copies root-router policy. | Review rejects duplication. | Adapter-to-mode diff and line inventory. |
| Authority agrees. | Adapter selects a path other than the manifest entrypoint. | Package QA fails. | Parsed manifest/adapter comparison. |
| Boundaries remain fixed. | Repair exposes everyday authoring or changes rules. | Existing checks or parity fail. | Manifest and payload comparison. |
| Identity is exact. | Evidence records the pre-repair tree digest. | Digest reproduction fails. | Independent canonical tree digest. |

## Stop Conditions

- the standalone adapter needs a copied core router or new protocol field;
- repair changes workflow availability, rule meaning, evidence, or consumer
  policy;
- a package version decision is required;
- validation changes the plan.

## Next Task

Open a review-only source PR. After acceptance and merge, return the replacement
identity to the Northstar orchestrator for registry repinning.
