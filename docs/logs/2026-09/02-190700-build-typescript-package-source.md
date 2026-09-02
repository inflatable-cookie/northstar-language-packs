# Build TypeScript Package Source

Date: 2026-09-02
Roadmap: `g01.001`
Card: `g01.001/001`
Result: source candidate ready for exact-head re-review

## Outcome

`packages/typescript` is the 20-file `@northstar/typescript-quality` `0.1.0`
source. Twelve relocated surfaces are byte-exact against Northstar `3f360be`.
Two JSON files are meaning-exact after stripping a pinned extra EOF blank line.
The three Rhai scripts resolve package assets from Effigy `catalog_root` and
leave `repo_root` as the consumer target.

Exact-head review of `5dba4d2` required this EOF normalization so
`git diff --check origin/main...HEAD` is actually green.

Worktree:
`/Users/tom/.paseo/worktrees/0z9augi8/build-typescript-package-source`.
Branch: `worker/build-typescript-package-source`.

## Proof Map

| Oracle | Counterexample run | Result |
| --- | --- | --- |
| Extraction is exact. | SHA-256 of the GNU `sha256sum` listing of the 17 pinned paths; 12 files byte-for-byte; 2 JSON files meaning-exact after one extra EOF newline; Rhai limited to task-source resolution. | Source-list digest `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`; 12 byte-exact, 2 EOF-normalized. |
| Package is independent. | Live and staged inventories compared; Rust/root Northstar paths would be unexpected files. | Exact 20-file staged inventory; staged tree digest matches source. |
| Source and target differ. | Setup/recorder plant a decoy catalogue or template under a consumer `skills/northstar/` tree; `effigy skill run --path <package> --repo <decoy-consumer>` uses an everyday-authoring decoy catalogue. | Package catalogue/templates win; check still reports 9 normative rules. |
| Self-check is real. | Direct wrapper from source and staged roots; PATH without `effigy`; non-executable copy. | Positives pass; missing `effigy` and non-executable copies fail closed. |
| Workflow remains narrow. | Manifest mutated to include `everyday_authoring`. | Check rejects it. |

## Identities

- source-list digest:
  `7e3ff26cd9319743fee5b0433d79b0cea6515347aa5780f68f2fcbb6eb664d26`
- package-tree digest:
  `sha256:0fcd5c58296f168895b66f2472621d49761f7786ea2ad1ebeefb801040967d6b`
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
- `git diff --check origin/main...HEAD` was clean.

## Next Move

Stop for orchestrator exact-head re-review of
https://github.com/inflatable-cookie/northstar-language-packs/pull/1.
