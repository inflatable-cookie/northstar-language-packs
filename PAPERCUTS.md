# Papercuts

Small, actionable friction found during agent work. Agents record it and
continue the scoped task.

## Open

<!-- Newest first. Never include secrets. -->

### [ ] Native Effigy starter uses removed docs command spelling — 2026-09-02
- Friction: Northstar's native manifest template emits `check-links` and other
  hyphenated subcommands rejected by Effigy 0.12.
- Impact: a fresh repository's first `effigy qa` fails before checking docs.
- Possible fix: update the starter to `effigy docs check <kind>` and add a
  template execution fixture.
- Surface: Northstar `effigy.native.toml.template`.
