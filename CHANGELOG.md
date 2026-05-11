# Changelog

## [0.1.0] — 2026-05-12

Initial release. Extracted from [claude-agent-team](https://github.com/ek33450505/claude-agent-team) v7.0's `cast doctor` subcommand.

### Added
- Standalone `cast-doctor` CLI — works without the full CAST framework
- Checks:
  - cast.db accessibility + core schema (sessions, agent_runs, agent_memories, routing_events)
  - Hook count + hook script path existence (from `~/.claude/settings.json`)
  - Events dir writability
  - Agent count + agent frontmatter parse (name + description required)
  - BATS version
  - MCP server configuration count
  - Stale auto-memory entries (>30 days verified_at AND name specific paths/flags)
  - Pending memory review queue (`projects/<id>/memory/_pending/`)
- Flags: `--quick` (skip slow checks), `--json` (machine-readable output), `--strict` (exit non-zero on warnings)
- Configurable paths via env vars (`CAST_DB_PATH`, `CAST_AGENTS_DIR`, `CAST_SETTINGS_FILE`, `CAST_EVENTS_DIR`, `CAST_PROJECTS_DIR`)
- Idempotent `install.sh` / `uninstall.sh` installing into `~/.local/bin`

### Notes
- No PyYAML dependency
- Trimmed framework-specific checks (slowest-agents query, _doctor_upgrades, migrations) that don't apply outside full CAST. Run `cast doctor` from claude-agent-team for the full check set.
