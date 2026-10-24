# Rust Quality Everyday Authoring

Use only for ordinary Rust writing, review, or refactoring when Northstar is
requested or applicable repository instructions already activate Rust quality.
This mode guides the current task; it does not authorize an audit of the
worktree or repository.

Everyday authoring is a repository choice. It exists only where
`everyday_authoring` is `true` in
`docs/knowledge/contracts/language-quality-activation.json`. A route that
returns `unavailable` says the repository has not opted in: stop, do not follow
this mode, and use the repository's own checks. A route that returns `degraded`
reports the pack failure and points at the repository's normal Validate checks;
report it and continue there. Explicit audit is unaffected by either.

## Resolve before editing

1. Check for the marked Rust activation block in the applicable `AGENTS.md`,
   `docs/knowledge/contracts/rust-quality-profile.json`, and
   `docs/knowledge/contracts/rust-quality-deviations.json`. If any are missing, choose the
   narrowest directory that owns the Rust source, manifests, tests, and related
   docs, then run
   `effigy skill run --path <installed-package-root> rust-quality:setup --repo <consumer-root> -- apply <absolute-target-root> <scope-directory> --everyday-authoring`.
   Only that flag opts a repository in. The setup task discovers Cargo and
   toolchain files, preserves existing instructions and contracts, and is
   idempotent. Do not ask the operator to copy templates or populate
   mechanically discoverable paths.
2. Read the installed activation and profile. Require language `rust` and
   profile `strict`; stop if an existing file is unsupported or ambiguous.
   Ask the operator only when repository policy cannot be recovered, such as a
   missing effective MSRV or an uncertain generated/vendor exclusion.
3. Read the declared Cargo manifests and explicit toolchain policy paths.
   Resolve the effective MSRV per package. Never infer a universal version;
   stop on a version-sensitive choice when policy is unsettled.
4. Read `docs/knowledge/contracts/rust-quality-deviations.json` plus relevant project
   architecture and error/API policy. Existing deviations are evidence, not
   permission to broaden their scope.
5. Capture initial repository state and the files the task may change. Preserve
   pre-existing and unrelated work.
6. Use `effigy tasks` when repository-native validation selectors are unknown.
   Do not invent a universal Cargo command graph.

## Load only applicable rules

Open only the matching files under
`../language-quality/rust/authoring/`:

| Trigger | Rule reference |
| --- | --- |
| new or materially changed function, module, control flow, or abstraction | `rust-read-001.json` |
| new or changed public type or public API traits | `rust-api-001.json` |
| fallibility, untrusted input, panic-capable operation, assertion, or indexing | `rust-err-001.json` |
| unsafe operation, raw pointer, unsafe API, or FFI boundary | `rust-unsafe-001.json` |
| async code, suspension, blocking lock, cancellation, or shared state | `rust-async-001.json` |
| version-sensitive syntax, API, lint, dependency, edition, or toolchain choice | `rust-msrv-001.json` |
| a newly introduced or materially changed pass-through wrapper | `rust-slop-001.json` |

Do not load `strict-audit.json` or the audit procedure. `RUST-SLOP-001` is only
a candidate signal and never authorizes a change. Strict unsafe/FFI quality
findings are report-only; do not alter an existing boundary merely to satisfy
this pack. A separately applicable approved rule and the user's task must supply
any mutation authority.

## Work and closeout

- Implement the smallest coherent change that satisfies the task, selected
  rules, repository architecture, and protected behavior.
- Before each coherent batch ends, re-open this mode and the same applicable
  rule files. Review the entire task-attributable changed tranche plus direct
  callers, tests, docs, and contracts needed to establish correctness.
- Compress the final diff after correctness is established. Keep each changed
  line, derive, trait implementation, branch, and helper only when it carries a
  task requirement, governing invariant, or necessary diagnostic responsibility.
- Do not scan, format, lint-fix, or rewrite unrelated repository code.
- Resolve every applicable rule as compliant, a concrete finding repaired under
  existing authority, an accepted recorded deviation, report-only, or blocked.
- At closeout only, load `../language-quality/rust/evidence-collection.md`. Run
  the compact `closeout` operation with the route's absolute `tools` binary and
  explicit repository-owned selectors. It stores raw output outside the
  worktree and returns only tranche paths, applicable rules, normalized
  statuses, diagnostic identifiers, and limitations. Do not load the audit
  projection or ledger.
- When the tranche is committed and the checkout is at its head, name it with
  `--base <rev> --head <rev>` rather than dirtying the worktree to manufacture
  an anchor. The committed form records exact commit identities and the
  packages the range corrects, preserves dirty files outside the range, and
  reuses an identical capture instead of rerunning it. Never present a worktree
  snapshot as proof of committed bytes, and never widen it to repository scope.
- Report changed scope, applicable rules, deviations or blockers, validation,
  and remaining limitations.

Re-entry at task start and coherent batch closeout is the retention mechanism.
Do not claim that it proves behavior across runtime context compaction.
