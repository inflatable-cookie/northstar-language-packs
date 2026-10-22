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
| `@northstar/typescript-quality` | `packages/typescript` | `0.1.0` | `>=0.2.0 <1.0.0` | `explicit_audit_repair` |
| `@northstar/rust-quality` | `packages/rust` | `0.2.2` | `>=0.2.0 <1.0.0` | `everyday_authoring`, `explicit_audit_repair` |

The TypeScript package owns the `base`, `svelte`, and `sveltekit` overlays. The
Rust package owns no overlays.

Current immutable identities:

| Package | Files | Package-tree digest | Manifest digest |
| --- | --- | --- | --- |
| `@northstar/typescript-quality` | 21 | `sha256:259cccdbacd7e2e293389efaf72cab005d0c275bd7cb600c99f30bfbfe071843` | `sha256:e5e32f2baeda2e901b8c327436adf0bfd5955a9de080887660684ad4583185ca` |
| `@northstar/rust-quality` | 59 | `sha256:b1abdb5092b55931b5cea69d72482d85ac02ce791ca943a125eefb42203c436b` | `sha256:5d074a0310eef7d241c61a82f2dc746413e3c55326d9e9327ea7095ada26ded6` |

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
