# Northstar language packs — current state

This repository is the public source and release-evidence home for official
Northstar language-quality packages. Two packages are complete source and are
not yet promoted to the Northstar registry:

- `@northstar/typescript-quality` `0.1.0` in `packages/typescript`
- `@northstar/rust-quality` `0.1.0` in `packages/rust`

Both are compatible with Northstar core `>=0.2.0 <1.0.0`. Registry promotion and
the Convergence canary are Northstar-owned, so nothing here reaches a consumer
until those land.

`scripts/verify-package-identities.sh` is the release-identity oracle. Current
package identities are in
[knowledge/architecture.md](knowledge/architecture.md#packages).

## By topic

- Vision: [knowledge/vision.md](knowledge/vision.md)
- Architecture and packages: [knowledge/architecture.md](knowledge/architecture.md)
- Contracts: [knowledge/contracts/](knowledge/contracts/README.md)
- Knowledge index: [knowledge/README.md](knowledge/README.md)
- Foundation facts and commands: [../README.md](../README.md)

## What's next

See [plan.md](plan.md).
