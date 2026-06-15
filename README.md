# cast-doctor

A read-only health check for any Claude Code install. Validates hook registrations, hook script paths, MCP server config, agent definitions, `cast.db` schema integrity, and stale auto-memory entries.

Works **without** the full CAST framework. Drop it in to any Claude Code setup — it tells you what's wired, what's missing, and what's drifted.

## Install (Homebrew)

```bash
brew tap ek33450505/cast-doctor && brew install cast-doctor
```

That's it — the formula symlinks `cast-doctor` into `$(brew --prefix)/bin` so it's on your PATH immediately.

## Manual install

```bash
git clone https://github.com/ek33450505/cast-doctor.git
cd cast-doctor
bash install.sh
```

## Usage

```bash
cast-doctor              # full health check
cast-doctor --quick      # skip db read + memory walk (fast path)
cast-doctor --json       # machine-readable output
cast-doctor --strict     # exit non-zero on any warning
cast-doctor version      # print version
```

Sample output:

```
cast-doctor v0.1.2
────────────────────────────────────────────────────
[ok] cast.db accessible (/Users/you/.claude/cast.db)
[ok] Schema: 4 / 4 core tables present
[ok] Hooks registered: 12 entries in settings.json
[ok] Hook scripts: all referenced paths exist
[ok] Events dir writable (/Users/you/.claude/cast/events)
[--] Agents: 23 installed in /Users/you/.claude/agents
[ok] Agent frontmatter: all parse (name, description required)
[ok] BATS available (Bats 1.13.0)
[ok] MCP servers: 3 configured
[ok] Stale auto-memories: none (verified_at within 30 days)
[ok] Pending memory review: queue empty
────────────────────────────────────────────────────
Overall: healthy  (warnings: 0)
```

## What it checks

| # | Check | When it warns |
|---|---|---|
| 1 | `cast.db` accessibility | DB exists but `sqlite3` can't open it |
| 2 | Core schema (`sessions`, `agent_runs`, `agent_memories`, `routing_events`) | Any of the 4 core tables missing |
| 3 | Hook count in `~/.claude/settings.json` | Zero hooks registered |
| 4 | Hook script path existence | Any referenced script path missing on disk |
| 5 | Events dir writability | Dir present but not writable |
| 6 | Agent count in `~/.claude/agents/` | Informational only |
| 7 | Agent frontmatter parses | Any agent .md missing `name:` or `description:` |
| 8 | BATS availability | `bats` not on PATH |
| 9 | MCP server count in settings | Informational only |
| 10 | Stale auto-memory entries | Any `verified_at` > 30 days AND body names specific paths/flags |
| 11 | Pending memory review queue | Any `_pending/*.md` files awaiting promotion |

## Configuration

Every path is overridable via environment variables — useful in CI, testing, or non-standard installs:

| Var | Default | Purpose |
|---|---|---|
| `CAST_DB_PATH` | `~/.claude/cast.db` | SQLite database |
| `CAST_AGENTS_DIR` | `~/.claude/agents` | Where to look for `*.md` agent definitions |
| `CAST_SETTINGS_FILE` | `~/.claude/settings.json` | Settings file with hooks + MCP config |
| `CAST_EVENTS_DIR` | `~/.claude/cast/events` | CAST event log directory |
| `CAST_PROJECTS_DIR` | `~/.claude/projects` | Per-project memory store roots |

## JSON output

`cast-doctor --json` emits:

```json
{
  "version": "0.1.2",
  "overall": "healthy",
  "warnings": 0,
  "errors": 0,
  "checks": [
    { "label": "cast_db",          "status": "ok",   "detail": "cast.db accessible (...)" },
    { "label": "schema",           "status": "ok",   "detail": "Schema: 4 / 4 core tables present" },
    { "label": "hook_count",       "status": "ok",   "detail": "Hooks registered: 12 entries in settings.json" }
  ]
}
```

Pipe it to `jq`, feed it to monitoring, alert on `.overall != "healthy"`. The schema is stable for v0.1.x.

## Exit codes

| Code | Meaning |
|---|---|
| `0` | Healthy (no errors, no warnings — or warnings present and `--strict` not set) |
| `1` | Degraded (one or more errors, OR warnings present and `--strict` set) |

## Prerequisites

- **bash** — already on macOS / Linux
- **python3** — stdlib only; no external packages
- **sqlite3** — for `cast.db` checks (gracefully skipped if missing)
- **BATS** — recommended; checked but not required

## What it does NOT do

cast-doctor is intentionally narrow:

- Does not run agent dispatches, doesn't talk to the Claude API
- Does not modify any file or DB row — it's read-only
- Does not require any specific CAST repo to be installed; runs against whatever's in `~/.claude/`
- Does not validate hook script *behavior* — only that the file exists at the path the settings claim

For deeper CAST-specific checks (slow-agent reports, migration history, framework-aware diagnostics), use `cast doctor` from [claude-agent-team](https://github.com/ek33450505/claude-agent-team).

## CAST Ecosystem

> Auto-synced from [claude-agent-team/docs/ecosystem.md](https://github.com/ek33450505/claude-agent-team/blob/main/docs/ecosystem.md). Run `scripts/sync-ecosystem-readme.sh` from your claude-agent-team clone to refresh.

<!-- ECOSYSTEM_START -->
| Repo | Description | Latest | Install |
|---|---|---|---|
| [cast-hooks](https://github.com/ek33450505/cast-hooks) | 20 auditable scripts (13 hooks + 7 supporting) — observability, safety guards, quality gates. SessionStart, PreToolUse, PostToolUse, PostCompact. | ![](https://img.shields.io/github/v/release/ek33450505/cast-hooks?style=flat-square) | `brew tap ek33450505/cast-hooks && brew install cast-hooks` |
| [cast-agents](https://github.com/ek33450505/cast-agents) | 23 specialist agents — commit, debug, review, plan, test, research, and more. Agent definitions with YAML frontmatter. v7-synced. | ![](https://img.shields.io/github/v/release/ek33450505/cast-agents?style=flat-square) | `brew tap ek33450505/cast-agents && brew install cast-agents` |
| [cast-memory](https://github.com/ek33450505/cast-memory) | Persistent agent memory with FTS5 search, relevance scoring, shared pool, semantic embeddings. Per-agent knowledge accumulation. | ![](https://img.shields.io/github/v/release/ek33450505/cast-memory?style=flat-square) | `brew tap ek33450505/cast-memory && brew install cast-memory` |
| [cast-routines](https://github.com/ek33450505/cast-routines) | Scheduled autonomous Claude Code routines via YAML + cron. Daily briefings, inbox triage, release celebration, weekly cost reports. | ![](https://img.shields.io/github/v/release/ek33450505/cast-routines?style=flat-square) | `brew tap ek33450505/cast-routines && brew install cast-routines` |
| [cast-parallel](https://github.com/ek33450505/cast-parallel) | Parallel agent execution across worktree sessions. Agent Dispatch Manifest (ADM) support. | ![](https://img.shields.io/github/v/release/ek33450505/cast-parallel?style=flat-square) | `brew tap ek33450505/cast-parallel && brew install cast-parallel` |
| [cast-observe](https://github.com/ek33450505/cast-observe) | Session-level observability — cost tracking, agent run history, token spend, event sourcing. Feeds cast.db. | ![](https://img.shields.io/github/v/release/ek33450505/cast-observe?style=flat-square) | `brew tap ek33450505/cast-observe && brew install cast-observe` |
| [cast-security](https://github.com/ek33450505/cast-security) | Security hooks and audit trails. PII redaction, parry-guard integration, compliance logging. | ![](https://img.shields.io/github/v/release/ek33450505/cast-security?style=flat-square) | `brew tap ek33450505/cast-security && brew install cast-security` |
| [cast-doctor](https://github.com/ek33450505/cast-doctor) | Read-only health check for any Claude Code install. Validates hooks, MCP servers, agent frontmatter, cast.db schema, stale memories. | ![](https://img.shields.io/github/v/release/ek33450505/cast-doctor?style=flat-square) | `brew tap ek33450505/cast-doctor && brew install cast-doctor` |
| [cast-time](https://github.com/ek33450505/cast-time) | Gives Claude Code a clock — injects local time, timezone, and a semantic time-of-day bucket at every SessionStart. | ![](https://img.shields.io/github/v/release/ek33450505/cast-time?style=flat-square) | `brew tap ek33450505/cast-time && brew install cast-time` |
| [cast-dash](https://github.com/ek33450505/cast-dash) | Terminal UI dashboard for live swarm monitoring. 4-panel real-time display (Textual framework). | ![](https://img.shields.io/github/v/release/ek33450505/cast-dash?style=flat-square) | `brew tap ek33450505/cast-dash && brew install cast-dash` |
| [cast-claudes_journal](https://github.com/ek33450505/cast-claudes_journal) | Session continuity — Claude's Journal auto-injects prior-day context via SessionStart hook. Obsidian vault sync. | ![](https://img.shields.io/github/v/release/ek33450505/cast-claudes_journal?style=flat-square) | `brew tap ek33450505/homebrew-claudes-journal && brew install claudes-journal` |
| [cast-website](https://github.com/ek33450505/cast-website) | castframework.dev — marketing site and docs portal for the CAST ecosystem. | ![](https://img.shields.io/github/v/release/ek33450505/cast-website?style=flat-square) | — |
| [cast-desktop](https://github.com/ek33450505/cast-desktop) | Tauri 2 native app — embedded PTY terminal, command palette, multi-target build (app, server, lsp-sidecar, sidecar). | ![](https://img.shields.io/github/v/release/ek33450505/cast-desktop?style=flat-square) | `brew tap ek33450505/homebrew-cast-desktop && brew install cast-desktop` |
<!-- ECOSYSTEM_END -->

## License

MIT — see [LICENSE](LICENSE).
