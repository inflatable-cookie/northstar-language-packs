# Build TypeScript Package Source

Date: 2026-09-02
Roadmap: `g01.001`
Card: `g01.001/001`
Result: source candidate ready for exact-head review

## Outcome

`packages/typescript` is the 20-file `@northstar/typescript-quality` `0.1.0`
source. Fourteen relocated surfaces are byte-exact against Northstar `3f360be`.
The three Rhai scripts resolve package assets from Effigy `catalog_root` and
leave `repo_root` as the consumer target.

Worktree:
`/Users/tom/.paseo/worktrees/0z9augi8/build-typescript-package-source`.
Branch: `worker/build-typescript-package-source`.

## Proof Map

| Oracle | Counterexample run | Result |
| --- | --- | --- |
| Extraction is exact. | SHA-256 of the GNU `sha256sum` listing of the 17 pinned paths; 14 relocated files compared byte-for-byte; Rhai limited to task-source resolution. | Source-list digest `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`; 14/14 byte-exact. |
| Package is independent. | Live and staged inventories compared; Rust/root Northstar paths would be unexpected files. | Exact 20-file staged inventory; staged tree digest matches source. |
| Source and target differ. | Setup/recorder plant a decoy catalogue or template under a consumer `skills/northstar/` tree; `effigy skill run --path <package> --repo <decoy-consumer>` uses an everyday-authoring decoy catalogue. | Package catalogue/templates win; check still reports 9 normative rules. |
| Self-check is real. | Direct wrapper from source and staged roots; PATH without `effigy`; non-executable copy. | Positives pass; missing `effigy` and non-executable copies fail closed. |
| Workflow remains narrow. | Manifest mutated to include `everyday_authoring`. | Check rejects it. |

## Identities

- source-list digest:
  `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`
- package-tree digest:
  `sha256:b4844ecabdd6a4e21cd33d4da9c94eb18fb8982996e32e92f06be07c08cd0337`
- manifest digest:
  `sha256:ed95883c428ef43f0f02d38d60bf8d50e6e29313f5751c1b2a5744157a5b5362`

The source-list digest is SHA-256 over the GNU `sha256sum` listing of the
original 17 Northstar paths at `3f360be`. The package-tree digest uses spec
034's sorted length-framed regular-file stream, including the executable bit
on `scripts/self-check.sh`.

## Limits

- Adapter and mode files still name Northstar-root routing; the registry lane
  owns installed-package invocation.
- No registry pin, consumer canary, or merge.

## Validation

- package-local `effigy qa` and `effigy qa:docs` passed;
- direct self-check passed from the package root and a 20-file staged copy;
- `effigy skill run --path packages/typescript check:typescript-quality --repo <decoy-consumer>` passed;
- repository `effigy qa` and `effigy qa:docs` passed;
- `git diff --check` was clean.

## Next Move

Open the source PR and stop for orchestrator exact-head review.
