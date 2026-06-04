# cast-doctor

## Install
```bash
bash install.sh       # installs to ~/.local/bin/cast-doctor
bash uninstall.sh
```
Override install target: `CAST_BIN_DIR=/usr/local/bin bash install.sh`

## Test
```bash
bats tests/cast-doctor.bats
```
Tests must not touch real `~/.claude/` — use env var overrides (see Non-obvious).

## Run
```bash
cast-doctor              # full health check
cast-doctor --quick      # skip memory walk and db read
cast-doctor --json       # machine-readable output
cast-doctor --strict     # exit non-zero on any warning
```

## Non-obvious
- All logic lives in `bin/cast-doctor`. `scripts/` is intentionally empty.
- `python3` and `sqlite3` are runtime prerequisites (`install.sh` checks for them).
- Env var overrides for local testing (avoid touching live CAST runtime):
  - `CAST_DB_PATH` — redirect from `~/.claude/cast.db`
  - `CAST_AGENTS_DIR` — redirect from `~/.claude/agents`
  - `CAST_SETTINGS_FILE` — redirect from `~/.claude/settings.json`
  - `CAST_EVENTS_DIR` — redirect from `~/.claude/cast/events`
  - `CAST_PROJECTS_DIR` — redirect from `~/.claude/projects`
- `CLAUDE_SUBPROCESS=1` causes the binary to exit 0 silently (hook guard).
