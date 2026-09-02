# Compile Adapter Repair And Rust Source

Date: 2026-09-03
Result: TypeScript repair ready; Rust source planned and blocked

## Outcome

The merged TypeScript source and installed setup/record repair are reconciled.
A later Northstar readiness review found one untested surface:
`packages/typescript/SKILL.md` loads an absent `references/router.md`. Card 003
is ready to make that adapter package-local and return a replacement immutable
identity.

The same review selected Convergence for the later Rust canary and froze a
54-file Northstar Rust source boundary. Milestone g01.002 and card 004 record
the source-repository part of that later work, but remain blocked until the
TypeScript repair and Northstar registry repin merge.

## Authority Split

- this repository owns card 003 source repair and card 004 Rust source;
- Northstar card 121 owns replacement registry promotion;
- Northstar card 119 owns Rust registry promotion and Convergence proof;
- no implementation, registry mutation, or consumer mutation occurred in this
  planning batch.
