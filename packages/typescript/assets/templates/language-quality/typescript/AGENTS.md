<!-- northstar:typescript-quality:start -->
## Northstar TypeScript/Svelte explicit audit

Use Northstar's TypeScript/Svelte quality pack only when the operator explicitly
requests a TypeScript or Svelte quality audit, no-slop pass, whole-codebase
review, or audit-and-fix action. Ordinary TypeScript/Svelte coding does not
activate it.

For explicit audit intent, run the installed-package route from this directory:
`effigy skill run northstar/language:route -- --consumer . --marker northstar:typescript-quality --workflow explicit_audit_repair`, then follow the `entrypoint_path` it returns. Resolve package ownership and strict profile state before assessment. Record findings before mutation, keep repairs inside recorder-authorized files, preserve pre-existing dirty work, and use repository-owned compiler, framework, lint, and test evidence without installing dependencies or inventing commands.
<!-- northstar:typescript-quality:end -->
