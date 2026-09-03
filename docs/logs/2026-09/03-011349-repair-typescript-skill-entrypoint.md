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
| Adapter is standalone. | Materialized installed copy before mutation; two corrupted copies through package QA: one with the entrypoint rewritten to `references/router.md`, one with an unquoted `Load references/router.md as an extra authority.` appended to an intact adapter. | The pre-repair reference is absent from the installed payload. Both corrupted copies are rejected with `adapter reference is missing from the installed package`. |
| Adapter stays thin. | Adapter-to-mode diff and line inventory. | The adapter copies no router policy; it points at the declared mode and keeps the explicit-activation guard. 706 bytes against the 1200-byte thin budget. |
| Authority agrees. | In-memory negative that swaps the entrypoint for an existing package file. | Rejected: `adapter does not load the manifest explicit_audit_repair entrypoint`. |
| Boundaries remain fixed. | Diff against `origin/main` for catalogue, schemas, templates, profiles, manifest, version, and operational tasks. | Only the adapter route, the QA closure check, and the installed-route proof changed. Policy invariants still pass. |
| Identity is exact. | Recorded digest naming the pre-repair tree or a dirty payload. | The superseded 21-file digest still reproduces from `origin/main`; each round's replacement digest reproduced from that round's staged copy. |

Adapter closure negatives (round 3): seven grammar negatives reject
external-URL (`https://example.com/router.md`) and spaced
(`references/missing router.md`) extra loads, the round-1 unquoted extra
load, missing, absolute, escaping, and manifest/adapter-disagreement forms;
one existence negative rejects a grammar-valid form whose entrypoint file is
absent from the installed copy — eight adapter negatives total. One
exact-command policy negative rejects a suffixed
`$northstar-typescript-audit-evil` command while the exact configured
command passes. All five corrupted materialized installed copies fail closed
with their exact messages through `effigy skill run --path`.

## Review Round 1

The orchestrator's exact-head review of `ab13058166cab6bc2d9d6410085c9c2288ae481e`
found one oracle gap: the closure check extracted references only from
backtick-quoted spans, so appending the unquoted line
`Load references/router.md as an extra authority.` to `SKILL.md` still passed
package QA. Reproduced from a fresh archive of that head before mutation.

Repair: the scanner was moved to whole-text tokenization. That repair held
until round 2.

One identity catch during the round: an intermediate digest taken over a
staged copy that had already run package QA hashed the runtime `.effigy`
state and did not match the committed tree. It was discarded; the recorded
replacement digest is reproduced from git objects, the committed archive, and
a filtered staged copy.

## Review Round 2

The orchestrator's exact-head review of `148f5820ef67529d63ff66560f62f50328a8c1c0`
found the deeper gap: the whole-text tokenizer still recognized only strings
already matching its safe path regex, so unsupported loading forms — an
external URL (`https://example.com/router.md`) or a spaced path
(`references/missing router.md`) — disappeared instead of failing closed.
Both reproduced from fresh archives of that head before mutation.

Repair: the natural-language tokenizer was removed. The closure oracle now
enforces a deterministic closed thin-adapter grammar: the adapter must equal
a canonical form built from the manifest's `explicit_audit_repair`
entrypoint and the command name that `agents/openai.yaml` invokes, and the
entrypoint file must exist inside the installed package root. Unsupported
extra load or reference directives cannot match the form, so they fail
closed. Both counterexamples now exit 1 with
`adapter is not the declared thin-adapter grammar form`; the clean adapter
positive and all prior negatives are retained.

## Review Round 3

The orchestrator's exact-head review of `7913095114f27befd75e0ab816e89b64c8c60264`
found the policy check matched by substring containment: replacing
`$northstar-typescript-audit` with `$northstar-typescript-audit-evil` in
`agents/openai.yaml` still passed package QA while adapter and policy invoked
different commands. Reproduced from a fresh archive of that head before
mutation. The same review flagged count drift: the checker ran eight
in-memory adapter negatives (seven grammar plus one existence) while the
card and handoff said "seven".

Repair: `agents/openai.yaml` is now matched as a closed exact-field form —
the whole `default_prompt` field must equal the canonical
`Use $northstar-typescript-audit ...` line, so no suffixed or altered
command can agree by substring accident. The evil-command variant is an
in-memory negative and a fifth materialized corrupted copy. Counts are
stated as seven grammar negatives plus one existence negative (eight
adapter-closure negatives) plus one exact-command policy negative, and the
QA banner names each family. The evil copy exits 1 with `agent policy is not
the declared exact-command form`; the clean policy positive still passes.

## Identities

- superseded source commit: `d18dc33b`
- superseded package-tree digest:
  `sha256:767671328a32f45610aba4462df7b3bdc87c62fd0ab2af8e6aee866aa15a334a`
- superseded manifest digest:
  `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca`
- replacement package-tree digest:
  `sha256:259cccdbacd7e2e293389efaf72cab005d0c275bd7cb600c99f30bfbfe071843`
  (round 3; `7913095` carried
  `sha256:99c82da3c90a0a1c352917221ff48ea9d607222b8f01ce424ba08d24afa3de74`;
  `148f582` carried
  `sha256:473fa8708ad646311c57fe6ac313f4c150e94d1eb693483d8c57549777ab4043`;
  `ab13058` carried
  `sha256:ee2f52e621f45c8e23034b3b1084ef5ab88437967d462607872f9a0dc90cec2a`)
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
  from the staged copy and still matched the superseded digest from
  `origin/main`; the committed tree digest is verified at the repair head.
- repository `effigy qa` and `git diff --check origin/main...HEAD` are recorded
  at PR open.

## Next Move

Stop for orchestrator exact-head review. Do not pin, merge, or start card 004
from this lane.
