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
- File tool and process friction in Queue with `papercut.add` (see the
  `northstar` skill). There is no `PAPERCUTS.md`.

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

Format coverage for maintained package sources is a separate selector because
it depends on a host tool. `effigy format:check` at the root, and the same
selector in each package catalogue, run `shfmt` (mvdan/sh v3) in `--diff` mode
under `--indent 4 --language-dialect posix`: they report unformatted sources and
never rewrite a file, and they fail closed when `shfmt` is absent. Rhai sources
have no maintained formatter, so the root selector declares that bounded
limitation instead of inventing formatting semantics. The root selector also
fails when a maintained shell or Rhai source is undeclared or when a package
catalogue stops naming its own shell files, and `effigy test:format-check`
proves a malformed fixture fails, a formatted control passes, and neither file
is rewritten.
