# System Architecture

## Repository Boundary

Northstar core owns package discovery, official registry, compatibility,
operator trust, installation, activation, rollback, offline routing, and host
protocol. This repository owns independently addressable official package
source, package self-checks, and immutable release evidence.

## Package Boundary

Each package lives under `packages/<language>` and contains its own `SKILL.md`,
agent metadata, `northstar-package.json`, Effigy catalogue, rules, overlays,
schemas, tools, fixtures, templates, and direct self-check wrapper. A package
must resolve its installed task source separately from the consumer repository
target.

The first package is `@northstar/typescript-quality` `0.1.0` under
`packages/typescript`, compatible with Northstar core `>=0.2.0 <1.0.0`. It
exposes only `explicit_audit_repair` and owns `base`, `svelte`, and `sveltekit`
overlays.

## Release Boundary

A source PR proves package-scoped source/self-check parity. After accepted
review, the orchestrator merges it and records the immutable source commit,
package tree digest, and manifest digest. Northstar registry promotion is a
separate downstream PR.

