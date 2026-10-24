# Architecture

## Repository boundary

Northstar core owns package discovery, the official registry, compatibility,
operator trust, installation, activation, rollback, offline routing, and the
host protocol. This repository owns independently addressable official package
source, package self-checks, and immutable release evidence.

Package manifests describe capability only. They never grant their own trust or
acquisition authority.

## Package boundary

Each package lives under `packages/<language>` and contains its own `SKILL.md`,
agent metadata, `northstar-package.json`, Effigy catalogue, rules, overlays,
schemas, tools, fixtures, templates, and direct self-check wrapper. A package
resolves its installed task source separately from the consumer repository
target.

A package must never retain or load a sibling package's content. Installing one
language installs exactly that package's payload. Stop when extraction would
change rule meaning, workflow availability, evidence schema, or consumer
policy.

## Packages

| Package | Path | Version | Core range | Workflows |
| --- | --- | --- | --- | --- |
| `@northstar/typescript-quality` | `packages/typescript` | `0.2.3` | `>=0.2.0 <1.0.0` | `explicit_audit_repair` |
| `@northstar/rust-quality` | `packages/rust` | `0.2.4` | `>=0.2.0 <1.0.0` | `everyday_authoring`, `explicit_audit_repair` |

The TypeScript package owns the `base`, `svelte`, and `sveltekit` overlays. The
Rust package owns no overlays.

The Rust manifest declares one buildable tool (`rust-quality`, from
`tools/rust-quality`). Northstar's lifecycle builds it during acquisition into
its own cache with an explicit target directory, outside the immutable install,
and records the binary in the installation receipt; every route returns its
absolute path. The package therefore ships no hand-build procedure, and a
failed build cannot leave build output in a published tree. Northstar's
language-quality contract owns the declaration and the opt-in shape; this
repository owns only the rust declaration and what its docs say.

Everyday authoring is a repository choice, off by default. A consumer opts in
with the boolean `everyday_authoring: true` in
`docs/knowledge/contracts/language-quality-activation.json`; an absent, false,
non-boolean or unreadable value is off, so explicit audit setup never depends on
that file. The rust setup task writes the setting and the activation block only
when asked with `--everyday-authoring`. A repository without it still gets the
explicit audit workflow.

Rust workspace discovery reports exactly the workspaces Cargo resolves. A
manifest that inherits workspace fields while Cargo finds no workspace root,
or that its resolved enclosing workspace neither owns nor excludes, is not a
workspace and stays out of the inventory. Those are unowned templates, such as
Longhorn's `examples/greenfield-compositions`, which are rebuilt inside a
generated private workspace. A real member's failure still fails discovery:
its workspace's own metadata call reports it, and a member whose inheritance
names a field the root does not define is reported as such.

Everyday closeout binds the source bytes it tested. A dirty worktree's
`source_identity` digests every dirty path with its Git status and its worktree
content, staged, working, untracked, deleted and symlinked paths included, so a
content-only change is a new source instead of a repeat; `snapshot_sha256`
stays a metadata digest. Evidence lives in ordered, immutable `attempt-<n>`
directories under that source identity: an unchanged successful plan reuses its
attempt, a failed selector or startup capture is retried as a new attempt
without a source or status change, and earlier attempts are never rewritten. A
successful capture of a different request, a record stamped with another source
identity, and a missing attempt ordinal fail closed.

Everyday closeout also accepts an explicit committed tranche. `inspect --scope
committed` and `closeout --base --head` resolve exact base and head commits,
require the checkout to be that head, reject an invalid revision, a
non-ancestor or empty range, a range without a Rust anchor, and committed paths
dirty in the worktree, and record the changed Rust anchors plus the Cargo
packages and workspace roots the range corrects. Dirty files outside the range
are preserved and reported, never absorbed. Evidence lives under the exact
range identity and reuses or retries attempts the same way. A dirty-worktree
closeout never claims to prove committed bytes. The audit planner rejects
committed scope: it is an everyday closeout input, not a repository claim.

Current immutable identities:

| Package | Files | Package-tree digest | Manifest digest |
| --- | --- | --- | --- |
| `@northstar/typescript-quality` | 21 | `sha256:0ccb43a6bd0e51c1639255df74d415d639bbe76888e83158dc6e5c2ae87c413c` | `sha256:98f26f0d1bdf3c2a403f294075248f5fb45652da478997d44f0dd76b43eb09e7` |
| `@northstar/rust-quality` | 60 | `sha256:7d5ec03d76c7e8044e52184fec8cae62810d0e17a12762bb574ceb30d416d52f` | `sha256:bd45c822c16cad96dec399286674ce2a142349ae258c27759f5c7c525b6ba162` |

`scripts/verify-package-identities.sh` is the oracle for these values. It fails
when a package file changes without the identity being updated.

## Consumer boundary

Consumer profiles, deviations, repair authority, and evidence remain owned by
the consumer repository. A package writes into a consumer target only through
its declared setup and recorder paths; it never reads the consumer's policy as
its own.

## Release boundary

A source PR proves package-scoped source/self-check parity. After accepted
review, the merge records the immutable source commit, package-tree digest, and
manifest digest. Registry promotion is a separate downstream PR owned by
Northstar. See [release](contracts/release.md).
