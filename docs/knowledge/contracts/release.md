# Release

Packages are released here as source plus immutable evidence first. No package
has been promoted to the Northstar registry yet.

## Rules

- Published identities are immutable commits and exact content digests, never
  moving branches or tags.
- A source PR proves package-scoped source/self-check parity and exact identity.
  After accepted review, the merge records the immutable source commit,
  package-tree digest, and manifest digest.
- Registry promotion is a separate downstream PR owned by Northstar. This
  repository does not pin, publish, notify consumers, or run release mutations.
- A repair produces a new source commit and a replacement identity. It is not a
  version bump unless capability or compatibility changes.
- Never rewrite a released package tree. Published versions are immutable.

## Identity

The package-tree digest is spec 034's sorted, length-framed regular-file stream,
including the executable bit. The manifest digest covers
`northstar-package.json` bytes. `scripts/verify-package-identities.sh`
recomputes both for each package and rejects a mutated package tree or a stray
file. Current values are in
[architecture](../architecture.md#packages).

## Steps

1. Change the package source; update `northstar-package.json` only when
   capability or compatibility changes.
2. Run `effigy qa`. It covers package QA, the installed-route proof, and
   `scripts/verify-package-identities.sh`.
3. Update the recorded identities in `scripts/verify-package-identities.sh` and
   [architecture](../architecture.md#packages) in the same change.
4. Merge the source PR. Record the source commit, package-tree digest, and
   manifest digest for Northstar registry promotion.
5. Northstar promotes the package in its own downstream PR.

## Verify

- `effigy qa` passes at the released commit.
- `scripts/verify-package-identities.sh` reproduces both the tree and manifest
  digests for both packages.
- The identities recorded in
  [architecture](../architecture.md#packages) match the script.

## Roll back

Published identities are immutable. Fix forward with a new source commit and a
replacement identity. Do not move, re-cut, or delete a released commit.
