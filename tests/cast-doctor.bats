#!/usr/bin/env bats
#
# Standalone tests for cast-doctor.
#
# Each test runs in an isolated $HOME so the user's real ~/.claude/ is never touched.

REPO_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
CLI="$REPO_DIR/bin/cast-doctor"

setup() {
  export ORIG_HOME="$HOME"
  HOME="$(mktemp -d)"
  export HOME
  mkdir -p "$HOME/.claude/agents" "$HOME/.claude/cast/events" "$HOME/.claude/projects"
  export CAST_DB_PATH="$BATS_TEST_TMPDIR/test-doctor-$$.db"
  export CAST_AGENTS_DIR="$HOME/.claude/agents"
  export CAST_SETTINGS_FILE="$HOME/.claude/settings.json"
  export CAST_EVENTS_DIR="$HOME/.claude/cast/events"
  export CAST_PROJECTS_DIR="$HOME/.claude/projects"
}

teardown() {
  rm -f "$CAST_DB_PATH"
  rm -rf "$HOME"
  HOME="$ORIG_HOME"
  export HOME
}

# ── Sanity ───────────────────────────────────────────────────────────────────

@test "CLI is executable" {
  [ -x "$CLI" ]
}

@test "version subcommand prints VERSION" {
  run bash "$CLI" version
  [ "$status" -eq 0 ]
  [[ "$output" == *"cast-doctor v"* ]]
}

@test "help subcommand prints usage banner" {
  run bash "$CLI" help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage:"* ]]
}

@test "unknown argument exits non-zero" {
  run bash "$CLI" --not-a-real-flag
  [ "$status" -ne 0 ]
}

# ── Subprocess guard ─────────────────────────────────────────────────────────

@test "exits 0 silently under CLAUDE_SUBPROCESS=1" {
  run env CLAUDE_SUBPROCESS=1 bash "$CLI"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ── Empty home: should run cleanly, report missing pieces as info/warn ──────

@test "runs cleanly on empty ~/.claude/" {
  run bash "$CLI" --quick
  [ "$status" -eq 0 ]
  [[ "$output" == *"Overall:"* ]]
}

# ── Hook script existence check ──────────────────────────────────────────────

@test "warns when hook script path is missing" {
  cat > "$CAST_SETTINGS_FILE" <<EOF
{
  "hooks": {
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "bash $HOME/.claude/scripts/does-not-exist.sh", "timeout": 3}]}
    ]
  }
}
EOF
  run bash "$CLI" --quick
  [[ "$output" == *"Hook script missing"* ]]
  [[ "$output" == *"does-not-exist.sh"* ]]
  # Strict-mode and missing-script both push exit non-zero, but neither alone in default mode
  # The missing script is _say_err which makes OVERALL=1
  [ "$status" -ne 0 ]
}

@test "passes when all hook scripts exist" {
  mkdir -p "$HOME/.claude/scripts"
  cat > "$HOME/.claude/scripts/real-hook.sh" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$HOME/.claude/scripts/real-hook.sh"
  cat > "$CAST_SETTINGS_FILE" <<EOF
{
  "hooks": {
    "SessionStart": [
      {"hooks": [{"type": "command", "command": "bash $HOME/.claude/scripts/real-hook.sh", "timeout": 3}]}
    ]
  }
}
EOF
  run bash "$CLI" --quick
  [[ "$output" == *"Hook scripts: all referenced paths exist"* ]]
}

# ── Agent frontmatter check ──────────────────────────────────────────────────

@test "warns when agent frontmatter is missing required keys" {
  cat > "$CAST_AGENTS_DIR/broken.md" <<'EOF'
# An agent file with no frontmatter

content here
EOF
  run bash "$CLI"
  [[ "$output" == *"Agent frontmatter"* ]]
  [[ "$output" == *"broken.md"* ]]
}

@test "passes when agent frontmatter parses" {
  cat > "$CAST_AGENTS_DIR/valid.md" <<'EOF'
---
name: valid
description: A valid agent for testing
---

Content here.
EOF
  run bash "$CLI"
  [[ "$output" == *"Agent frontmatter: all parse"* ]]
}

# ── JSON output ──────────────────────────────────────────────────────────────

@test "--json output is valid JSON" {
  run bash "$CLI" --json --quick
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  # Validate via python
  echo "$output" | python3 -c "import json,sys; json.load(sys.stdin)"
}

@test "--json output has expected top-level keys" {
  run bash "$CLI" --json --quick
  echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
assert 'version' in d
assert 'overall' in d
assert 'warnings' in d
assert 'errors' in d
assert 'checks' in d
assert isinstance(d['checks'], list)
"
}

@test "--json output check entries have label/status/detail" {
  run bash "$CLI" --json --quick
  echo "$output" | python3 -c "
import json, sys
d = json.load(sys.stdin)
for c in d['checks']:
    assert 'label' in c
    assert 'status' in c
    assert 'detail' in c
    assert c['status'] in ('ok', 'warn', 'err', 'info')
"
}

# ── Strict mode ──────────────────────────────────────────────────────────────

@test "--strict turns warnings into non-zero exit" {
  # Empty home produces warnings (no hooks, no MCP). Strict should fail.
  run bash "$CLI" --strict --quick
  # If warnings are present, exit should be 1; if no warnings, 0 is also acceptable
  if [[ "$output" == *"warnings: 0"* ]]; then
    [ "$status" -eq 0 ]
  else
    [ "$status" -eq 1 ]
  fi
}

# ── Quick mode skips slow checks ─────────────────────────────────────────────

@test "--quick skips cast.db schema check" {
  run bash "$CLI" --quick
  # Schema check produces a "Schema:" line when run; quick mode skips it
  [[ "$output" != *"Schema:"* ]]
}

@test "full mode runs schema check" {
  # Make a fake cast.db so schema check runs
  command -v sqlite3 >/dev/null || skip "sqlite3 not available"
  sqlite3 "$CAST_DB_PATH" "CREATE TABLE sessions (id TEXT); CREATE TABLE agent_runs (id TEXT); CREATE TABLE agent_memories (id TEXT); CREATE TABLE routing_events (id TEXT);"
  run bash "$CLI"
  [[ "$output" == *"Schema:"* ]]
  [[ "$output" == *"4 / 4 core tables present"* ]]
}

# ── Syntax checks ────────────────────────────────────────────────────────────

@test "bin/cast-doctor passes bash -n" {
  run bash -n "$CLI"
  [ "$status" -eq 0 ]
}

@test "install.sh passes bash -n" {
  run bash -n "$REPO_DIR/install.sh"
  [ "$status" -eq 0 ]
}

@test "uninstall.sh passes bash -n" {
  run bash -n "$REPO_DIR/uninstall.sh"
  [ "$status" -eq 0 ]
}
