# Papercuts

Small, actionable friction found during agent work. Agents record it and
continue the scoped task.

## Open

<!-- Newest first. Never include secrets. -->

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
