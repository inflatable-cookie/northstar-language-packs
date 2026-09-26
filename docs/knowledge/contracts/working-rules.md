# Working rules

## Authority

Northstar core owns the generic language-package protocol. This repository owns
official package-source structure, package self-checks, release evidence, and
its own source PRs.

## Delivery

- Keep each change inside one package or one repository surface.
- A source PR proves package-scoped source/self-check parity and exact
  immutable identity before merge.
- Universal, exact, and negative claims require a counterexample and proof.
- Preserve consumer policy and evidence formats. Return a semantic change to
  Northstar planning instead of making it here.
- Keep package edits in meaningful commits.

## Boundaries

- Do not edit Northstar core or a consumer repository from this repository.
- Do not start registry promotion or consumer canary work here; both are
  Northstar-owned.
- Do not change rule meaning, workflow availability, evidence schema, or
  consumer policy as a side effect of extraction.

## Validation

`effigy qa` is the repository check. It covers documentation shape, link
integrity, and the package release identities in
`scripts/verify-package-identities.sh`. Package work must also prove
package-scoped source/install parity and the change's negative oracle.
