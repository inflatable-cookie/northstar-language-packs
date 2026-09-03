# Repair TypeScript Skill Entrypoint

Date: 2026-09-03
Roadmap: `g01.001`
Card: `g01.001/003`
Result: replacement source candidate ready for exact-head review

## Outcome

The TypeScript package's agent-facing adapter is standalone.
`packages/typescript/SKILL.md` loads
`references/modes/typescript-quality-audit.md` from its own installed root —
the manifest's declared `explicit_audit_repair` entrypoint — instead of an
absent root Northstar router. No router policy was copied; the adapter stays a
706-byte thin pointer. Package version stays `0.1.0`.

Worktree:
`/Users/tom/.paseo/worktrees/0z9augi8/repair-typescript-skill-entrypoint`.
Branch: `worker/repair-typescript-skill-entrypoint`.

## Findings Before Mutation

Materializing the 21-file `origin/main` `packages/typescript` reproduced the
defect:

1. `SKILL.md` line 10 said `Load references/router.md from the main northstar
   skill`.
2. `references/router.md` is absent from the package; only
   `references/modes/typescript-quality-audit.md` exists under `references/`.
   The installed setup/record proof never read the adapter, so QA accepted the
   broken route.

## Proof Map

| Oracle | Counterexample run | Result |
| --- | --- | --- |
| Adapter is standalone. | Materialized installed copy before mutation; a second copy with `references/modes/typescript-quality-audit.md` rewritten to `references/router.md` through package QA. | The pre-repair reference is absent from the installed payload. The corrupted copy is rejected with `adapter reference is missing from the installed package`. |
| Adapter stays thin. | Adapter-to-mode diff and line inventory. | The adapter copies no router policy; it points at the declared mode and keeps the explicit-activation guard. 706 bytes against the 1200-byte thin budget. |
| Authority agrees. | In-memory negative that swaps the entrypoint for an existing package file. | Rejected: `adapter does not load the manifest explicit_audit_repair entrypoint`. |
| Boundaries remain fixed. | Diff against `origin/main` for catalogue, schemas, templates, profiles, manifest, version, and operational tasks. | Only the adapter route, the QA closure check, and the installed-route proof changed. Policy invariants still pass. |
| Identity is exact. | Recorded digest naming the pre-repair tree or a dirty payload. | The superseded 21-file digest still reproduces from `origin/main`; the replacement digest reproduced twice from the staged copy. |

Path-closure negatives: missing (`references/router.md`), absolute
(`/usr/local/share/...`), escaping (`references/../../outside/...`), and
manifest/adapter disagreement all fail closed in
`check-typescript-quality.rhai`; the materialized corrupted-copy run proves the
same rejection end to end through `effigy skill run --path`.

## Identities

- superseded source commit: `d18dc33b`
- superseded package-tree digest:
  `sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a`
- superseded manifest digest:
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`
- replacement package-tree digest:
  `sha256:ee2f52e621f45c8e23034b3b1084ef5ab88437967d462607872f9a0dc90cec2a`
- replacement manifest digest:
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`

The manifest digest is unchanged because `northstar-package.json` bytes are
untouched; only the tree digest moves. The replacement source commit is this
PR head after push. The package-tree digest is spec 034's sorted
length-framed regular-file stream, including the executable bit on both shell
scripts.

## Limits

- Northstar registry pin, card 121, and card 004 Rust source remain serial
  behind this PR.
- Package version is still `0.1.0`; this is a replacement identity, not a
  version bump.
- No merge.

## Validation

- package-local `effigy qa` passed, including the new closure negatives and
  the extended installed-route proof;
- direct self-check passed from the package root and a 21-file staged copy;
- the staged copy also passed the installed-route proof, which runs package QA
  on a materialized installed copy and on a corrupted copy;
- independent spec-034 digest reproduction matched the replacement tree digest
  twice and still matched the superseded digest from `origin/main`;
- repository `effigy qa` and `git diff --check origin/main...HEAD` are recorded
  at PR open.

## Next Move

Stop for orchestrator exact-head review. Do not pin, merge, or start card 004
from this lane.
