# Build Rust Package Source

Date: 2026-09-03
Roadmap: `g01.002`
Card: `g01.002/004`
Result: source candidate reconciled after exact-head review; ready for PR update

## Outcome

`packages/rust` is the 59-file `@northstar/rust-quality` `0.1.0` source.
54 frozen source paths reproduced from sibling `../northstar` at
`69e4d5dea3daa4f6133d7363d39c1a0f72848435` with source listing digest
`2f8515afce33c87e9b38f103b9c41440ed7f182142fc2c65fed4d10d9264040b`.

All six findings from exact-head review on PR #4 are addressed:
1. Canonical spec-034 package-tree digest is recorded and proved separately
   from the legacy GNU listing digest.
2. Exact extraction is falsified through a deterministic 54-source map and
   parity proof (44 byte-exact, 4 EOF-newline-normalized, 6 package-adapted)
   with unrecorded semantic rewrites failing closed.
3. `references/language-quality/rust/tool-bootstrap.md` is adapted to resolve
   relative to the installed Rust package; package QA rejects stale
   skill-relative phrasing.
4. Non-vacuous cross-boundary migration proof runs the frozen pre-extraction
   Northstar engine as producer and the installed package engine as consumer,
   proving existing v2 audit records remain readable and finalizable while
   consumer profile and deviation bytes are preserved.
5. Engine source-payload integrity oracle is reconciled against Northstar
   planning commit `d4dd821` (embedded source-payload digest ↔ current
   source-payload digest agreement without changing the engine lifecycle).
6. Exact raw receipt field value `2b75b0866e3bedf99c133e53cb742c284715fb1f10f589358ce2a91331571157`
   is stated explicitly for `embedded_payload_sha256` and `source_payload_sha256`.

Worktree: `/Users/tom/.paseo/worktrees/0z9augi8/build-rust-package-source`.
Branch: `worker/build-rust-package-source`.

## Proof Map

| Oracle | Counterexample run | Result |
| --- | --- | --- |
| Source inventory is exact. | SHA-256 of sorted GNU `sha256sum` listing of 54 frozen paths reproduced from `../northstar` at `69e4d5d`. | Source listing digest `2f8515afce33c87e9b38f103b9c41440ed7f182142fc2c65fed4d10d9264040b`. |
| Source parity is deterministic. | 54 source files verified against frozen Northstar commit `69e4d5d`: 44 byte-exact, 4 EOF-newline-normalized, 6 package-adapted; unrecorded semantic rewrite injected into byte-exact source fails closed. | Deterministic source parity verified; unrecorded rewrite rejected. |
| Package tree identity is canonical. | Spec-034 length-framed regular-file stream computed across all 59 package files. | Canonical package-tree digest `sha256:cd6bd40ebd8e942f12f882033168d483e20783b12f42acbf81c1bff80157f1df`. |
| Package is isolated. | Live inventory checked for unexpected files, TypeScript payloads, or sibling contamination. | Exact 59-file package inventory; no sibling content. |
| Workflows remain distinct. | Projections (`strict-authoring.json`, `strict-audit.json`), routing fixtures, and authoring workflow cases validated. | Everyday authoring and explicit audit remain distinct and package-local. |
| Tool bootstrap is package-local. | `tool-bootstrap.md` references the installed Rust package; corruption to stale skill-relative phrasing fails package QA. | Stale root-dependent skill phrasing rejected. |
| Engine integrity survives extraction. | Probe binary installed; `verify-install` binds raw `embedded_payload_sha256` to `source_payload_sha256`; mutating `src/lib.rs`, `Cargo.toml`, or `diagnostic-mapping.json` fails closed with `install.payload_mismatch`. | 27 Cargo tests pass; probe verification passes; tamper negatives fail closed. |
| Pre-extraction ledger is compatible. | Frozen pre-extraction Northstar engine acts as producer (`inspect`, `plan`, `init`, `assess`); installed package engine acts as consumer (`validate-ledger`, `extend`, `collect`, `complete`, `finalize`); consumer profile/deviation bytes checked. | Full cross-boundary migration succeeds to clean closeout; profile/deviations preserved. |
| Source and target differ. | Setup run against decoy consumer with decoy catalogue and template; relay sentinel `--` enforced. | Decoy catalogue/templates ignored; consumer `AGENTS.md` and contracts updated; package root unmutated. |
| Self-check is real. | `scripts/self-check.sh` directly executed and tested for missing manifest/catalogue/commands. | Direct wrapper and package task pass. |
| Adapter closure is enforced. | Closed thin-adapter grammar and exact-command policy tested with 7 grammar, 1 existence, and 1 command-mismatch counterexamples. | All corrupted variations fail closed. |

## Identities

- source commit:
  `69e4d5dea3daa4f6133d7363d39c1a0f72848435`
- source listing digest (54 files, GNU sha256sum listing):
  `2f8515afce33c87e9b38f103b9c41440ed7f182142fc2c65fed4d10d9264040b`
- package file count:
  `59`
- canonical package-tree digest (spec-034 length-framed stream):
  `sha256:cd6bd40ebd8e942f12f882033168d483e20783b12f42acbf81c1bff80157f1df`
- package-tree listing digest (59 files, GNU sha256sum listing):
  `sha256:16f9d460944f6636df13a52d039aa68dda9613eec2d7798a654c2f39794da90c`
- manifest digest (`northstar-package.json`):
  `sha256:dd71d04efd67cc7805f417a79666dd920ea1811ee252d941108dfbeca8aab612`
- manifest raw SHA-256:
  `dd71d04efd67cc7805f417a79666dd920ea1811ee252d941108dfbeca8aab612`
- engine file count:
  `22`
- engine Cargo tree listing digest (`tools/rust-quality`):
  `sha256:46df2d0d11286885b2c9a5dfb20f52232091519c357486bc7a1aea4d05cb83c2`
- engine payload digest (`embedded_payload_sha256` raw receipt field):
  `2b75b0866e3bedf99c133e53cb742c284715fb1f10f589358ce2a91331571157`
- engine `Cargo.lock` digest:
  `sha256:bc06a8704d049aa400805186854436ae214edc0e5a3b525cb338bb18d875f0de`
- engine `Cargo.toml` digest:
  `sha256:89c226257ceaa62746426cd9b40c947e6d09cca87b627ff41ce6e7a66bc788b7`

## Limits

- Do not edit Northstar or Convergence.
- Do not start registry promotion or canary lanes.
- Do not merge the PR.

## Validation

- `effigy --repo packages/rust check:rust-quality` passed (7 rules, 14 qualified detector candidates, 59-file inventory, 10 catalogue/manifest/bootstrap, 7 grammar, 1 existence, 1 exact-command negative paths).
- `effigy --repo packages/rust test:rust-quality-setup` passed (install, preserve, idempotency, absolute-under-target, decoy ignored, 4 negative paths).
- `effigy --repo packages/rust test:rust-quality-engine` passed (4 unit tests, 21 CLI integration tests, 2 detector integration tests).
- `effigy --repo packages/rust test:rust-quality-installed-route` passed (spec-034 canonical tree digest, 54-source deterministic parity, cross-boundary pre-extraction ledger migration, public skill-run setup, relay sentinel, decoy catalogue ignored, engine cargo tests and tamper rejection, probe verify-install, adapter grammar and exact-command closure enforced).
- `packages/rust/scripts/self-check.sh` passed.
- `effigy --repo packages/rust qa:docs` and `effigy --repo packages/rust qa` passed.
- Repository `effigy qa` and `effigy qa:docs` passed.
- `git diff --check` clean.

## Next Move

Push updated commits to `worker/build-rust-package-source` and report the new exact head.
