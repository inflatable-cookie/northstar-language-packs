# Rust Quality Tool

The package declares one buildable tool, `tools/rust-quality`. The lifecycle
builds it during acquisition, in the operator cache, outside the immutable
install, and records the binary in the installation receipt. Do not run a Cargo
build for `tools/rust-quality` by hand.

## Use the routed binary

A route result that carries `tools` names the engine: `id` `rust-quality`, an
absolute `path`, the binary `sha256`, and `built_at`. The installation receipt
records the same entry, and `<tool>` in the other references means that absolute
path.

- Never add the binary's directory to `PATH`.
- Never build inside the installed package; the install store is immutable and
  digest-addressed.
- An intact cache is reused, so a route never rebuilds the engine.

Acquisition runs the manifest's recipe with an explicit target directory and
output root under the operator cache, against a throwaway copy of the verified
payload, so the installed tree keeps its pinned digest. A missing,
non-executable, or digest-drifted binary makes the pack unusable: re-acquire the
package instead of building by hand.

Everyday authoring and explicit audit use the same binary. The receipt's tool
entry is not audit evidence.

## Ensure the explicit-audit scanner

This step is audit-only. Everyday authoring does not install or run the scanner.

1. Set `<scanner-root>` to `<cache>/scanners/stopslop-0.5.1`.
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
