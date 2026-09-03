# 003 — Repair TypeScript Skill Entrypoint

Status: implemented; reviewable PR open; awaiting orchestrator exact-head review
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

- [x] `SKILL.md` loads only package-local files that exist in the installed
  payload;
- [x] its route matches manifest workflow `explicit_audit_repair`;
- [x] `agents/openai.yaml` still invokes `$northstar-typescript-audit` and
  implicit activation remains disabled;
- [x] missing, absolute, and escaping adapter paths are rejected by package QA;
- [x] policy, package version, manifest meaning, and operational tasks remain
  unchanged;
- [x] source/staged parity, direct self-check, installed setup/record proof,
  package QA, repository QA, and `git diff --check` pass;
- [x] replacement immutable identities are recorded honestly.

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

## Completion Notes

Worker `worker/repair-typescript-skill-entrypoint` in Paseo worktree
`/Users/tom/.paseo/worktrees/0z9augi8/repair-typescript-skill-entrypoint`
reproduced the absent `references/router.md` load from a materialized 21-file
`origin/main` package, then made the adapter load its declared package-local
mode directly. No router policy was copied; the adapter stays a 706-byte
pointer to the manifest entrypoint.

`check-typescript-quality.rhai` no longer pattern-matches adapter prose. It
enforces a closed thin-adapter grammar: the adapter must equal a canonical
form built from the manifest's `explicit_audit_repair` entrypoint and the
command name that `agents/openai.yaml` invokes, and the entrypoint file must
exist inside the installed package root. Any extra load, reference, or prose
fails closed. Seven in-memory negatives cover the two round-2 counterexamples
(external-URL and spaced-path extra loads), the round-1 unquoted extra load,
missing, absolute, escaping, and manifest/adapter disagreement, plus a
grammar-valid adapter whose entrypoint file is absent from the installed
copy. `prove-installed-invocation.sh` runs package QA on a materialized
installed copy and proves four corrupted copies fail closed with the exact
grammar message: rewritten entrypoint, unquoted extra load, external-URL
extra load, and spaced extra load.

Review round 2: the orchestrator's exact-head review of `148f582` found the
whole-text tokenizer still recognized only strings already matching its safe
path regex, so external-URL and spaced-path extra loads disappeared instead
of failing closed. Reproduced from fresh archives of that head, then the
heuristic was replaced by the closed grammar above.

Replacement identities:

- package-tree digest
  `sha256:99c82da3c90a0a1c352917221ff48ea9d607222b8f01ce424ba08d24afa3de74`
  (verified against the committed tree at the repair head; an intermediate
  staged-copy digest polluted by runtime `.effigy` state was discarded)
- manifest digest
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`
  (unchanged; `northstar-package.json` bytes are untouched)

Superseded identities remain card 002's `d18dc33b` /
`sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a` /
`sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`,
reproduced independently from `origin/main` before and after the repair. The
replacement source commit is this PR head after push.

Evidence: `docs/logs/2026-09/03-011349-repair-typescript-skill-entrypoint.md`.

## Next Task
Orchestrator exact-head review owns acceptance and merge. After merge, the
replacement identity returns to Northstar card `g02.048/121` for registry
repinning. Card 004 stays blocked until that repin.
