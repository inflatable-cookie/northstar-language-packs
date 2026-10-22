# Rust Quality Tool Bootstrap

The lifecycle builds the Cargo tool from `tools/rust-quality/` into the operator
cache when it acquires this package. Use the absolute path the route returns in `tools`;
do not run `cargo install`, edit `PATH`, ask the operator to install a binary, or
build inside the installed package.

The declared build uses an explicit target directory outside the immutable
install and records the binary in the installation receipt. Re-acquire the
package when that path is missing or its digest drifted.

## Explicit-audit scanner

The pinned `stopslop 0.5.1` scanner is audit-only external tooling and is not
part of the package payload. Everyday authoring does not install or run it.

1. Set `<scanner-root>` to the host cache at `<cache>/scanners/stopslop-0.5.1`.
2. If `<scanner-root>/bin/stopslop` is missing, run:

   ```text
   cargo install --locked --offline stopslop --version 0.5.1 --root <scanner-root>
   ```

   Retry without `--offline` only when Cargo reports that the pinned crate or a
   locked dependency is absent and network access is allowed. Do not install an
   unpinned version or use a Git branch.
3. Require `<scanner-root>/bin/stopslop --version` to print `stopslop 0.5.1`.
   Invoke that absolute binary path; never add it to `PATH`.
4. If installation or verification is unavailable, record the scanner request
   as `unavailable` with its actual failure stage. Do not replace it with an
   improvised text search or claim a total forwarder candidate ledger.
