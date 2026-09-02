# Repair Installed TypeScript Invocation

Date: 2026-09-02
Roadmap: `g01.001`
Card: `g01.001/002`
Result: replacement source candidate ready for exact-head review

## Outcome

The TypeScript package is operational as an installed external task source.
Setup and recorder use `effigy skill run --path <package-root> --repo
<consumer-root> -- <args>`. Both scripts strip one leading Effigy relay
sentinel before dispatch. Policy, schema, template, and workflow meaning are
unchanged. Package version stays `0.1.0`.

Worktree:
`/Users/tom/.paseo/worktrees/0z9augi8/repair-installed-typescript-invocation`.
Branch: `worker/repair-installed-typescript-invocation`.

## Findings Before Mutation

Materializing `origin/main` `packages/typescript` (20 files) reproduced both
review failures:

1. `effigy --repo <installed> northstar/typescript-quality:setup apply …`
   exits 1 with `task catalog prefix \`northstar\` not found (available:
   typescript-quality)`.
2. `effigy skill run --path <installed> typescript-quality:setup --repo
   <consumer> -- self-test` reaches the package task with
   `ARGS_JSON=["--","self-test"]` and dies at the usage guard.

## Proof Map

| Oracle | Counterexample run | Result |
| --- | --- | --- |
| Installed source owns execution. | Old `northstar/` prefix against the installed copy; same prefix against a decoy consumer whose catalogue alias is `northstar`; public `skill run --path` against that decoy. | Old installed command fails closed. Decoy prefix runs `DECOY-NORTHSTAR-SETUP-RAN` and writes no package assets. Public setup/record JSON `catalog_alias` is `typescript-quality` and `source.root` is the installed copy. |
| Relay arguments survive. | Empty `--` relay; `-- apply` and `-- init` through `skill run --json`. | Empty relay hits usage with `ARGS_JSON=["--"]`. Valid apply/init transcripts contain the forwarded sentinel and succeed. |
| Consumer stays the target. | Setup/record would write `AGENTS.md`, contracts, or `.effigy/` under the installed root; decoy templates would win AGENTS text. | Installed tree listing is byte-identical before/after. Consumer receives package activation, profile, and audit records. Recorder `catalogue_sha256` matches the installed catalogue. |
| Policy is unchanged. | Diff against `origin/main` for catalogue, schemas, templates, overlays, SKILL, and self-check wrapper. | Those files are unchanged. Edits are invocation docs/scripts, the new proof, catalogue wiring, and closeout. |
| Replacement identity is exact. | Recorded digest names the old 20-file tree `sha256:0fcd5c58…d6b` or a dirty payload. | Two independent spec-034 reproductions of the 21-file tree match `sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a`. The superseded 20-file tree still reproduces from `origin/main`. |

## Identities

- superseded source commit: `09ef1743dd8fc18bae3bf04fae791f1d7d4e5daf`
- superseded package-tree digest:
  `sha256:0fcd5c58296f168895b66f2472621d49761f7786ea2ad1ebeefb801040967d6b`
- superseded manifest digest:
  `sha256:ed95883c428ef43f0f02d38d60bf8d50e6e29313f5751c1b2a5744157a5b5362`
- replacement package-tree digest:
  `sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a`
- replacement manifest digest:
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`

The replacement source commit is this PR head after push. Merge SHA stays
orchestrator-owned. The package-tree digest is spec 034's sorted length-framed
regular-file stream, including the executable bit on both shell scripts.

## Limits

- Northstar registry pin, PR 23, and Jetstream remain serial.
- Package version is still `0.1.0`; this is a replacement identity, not a
  version bump.
- No merge.

## Validation

- package-local `effigy qa` passed, including the public installed-route proof;
- direct self-check passed from the package root and a 21-file staged copy;
- staged copy also passed the installed-route proof;
- independent spec-034 digest reproduction matched the recorded tree digest
  and still matched the superseded 20-file digest from `origin/main`;
- repository `effigy qa` and `git diff --check origin/main...HEAD` are recorded
  at PR open.

## Next Move

Stop for orchestrator exact-head review. Do not pin, merge, or start Jetstream
work from this card.
