# Papercuts

Small, actionable friction found during agent work. Agents record it and
continue the scoped task.

## Open

<!-- Newest first. Never include secrets. -->

### [ ] Installed skill-run fixtures need a project root and physical paths — 2026-09-02
- Friction: `effigy skill run --repo` rejects a bare directory (`could not
  resolve a project root`). On macOS, `pwd` keeps `/var/folders/...` while
  Effigy JSON records `/private/var/folders/...`.
- Impact: a decoy consumer must plant an Effigy catalogue even to prove that
  catalogue cannot win, and proofs must canonicalize with `pwd -P` before
  comparing source/target evidence.
- Possible fix: document skill-run consumer fixtures; compare JSON roots
  after physical-path normalization.
- Surface: `effigy skill run --repo`; package installed-route proof.

### [ ] Working-tree `git diff --check` misses new-file EOF blanks — 2026-09-02
- Friction: `git diff --check` on a clean worktree is empty; the required
  check is `git diff --check origin/main...HEAD`, which reports trailing
  blank lines on newly added files.
- Impact: closeout claimed a clean diff-check while the base-to-head range
  failed on two copied JSON files.
- Possible fix: make package QA or the card validation spell the base-to-head
  form, and strip extra EOF blanks on extraction.
- Surface: worker closeout validation; copied JSON package files.

### [ ] Rhai functions cannot read Effigy catalog_root constant — 2026-09-02
- Friction: `catalog_root` and `repo_root` are script-scope constants; a
  function that names them throws `Variable not found`.
- Impact: package scripts must resolve task-source at top level and pass it
  down, which is easy to get wrong when extracting from repo-root heuristics.
- Possible fix: capture host constants into the Rhai global module, or
  document that they are top-level only.
- Surface: Effigy Rhai host (`catalog_root`, `repo_root`, `skill_root`).

### [ ] Native Effigy starter uses removed docs command spelling — 2026-09-02
- Friction: Northstar's native manifest template emits `check-links` and other
  hyphenated subcommands rejected by Effigy 0.12.
- Impact: a fresh repository's first `effigy qa` fails before checking docs.
- Possible fix: update the starter to `effigy docs check <kind>` and add a
  template execution fixture.
- Surface: Northstar `effigy.native.toml.template`.
