# Contributing to cast-doctor

Thanks for your interest! cast-doctor is a focused diagnostic CLI. Contributions that add new checks, improve existing ones, or harden cross-platform support are welcome.

## Prerequisites

- **bash** + **python3** — both ship with macOS / standard Linux
- **sqlite3** — usually present; required for `cast.db` checks at runtime
- **BATS** — `brew install bats-core` (macOS) or `apt-get install bats` (Ubuntu)

No PyYAML dependency. Stdlib Python only.

## Quick Start

```bash
git clone https://github.com/ek33450505/cast-doctor
cd cast-doctor
bash install.sh
cast-doctor
```

`install.sh` is idempotent — safe to re-run.

## How to Modify

**CLI** (`bin/cast-doctor`): The main diagnostic script. Each numbered section is one check. To add a check:

1. Increment the section number in the comment block
2. Use `_say_ok` / `_say_warn` / `_say_err` / `_say_info` to record results — the `label` is a stable key for `--json` output
3. If the check is expensive (DB read, full directory walk), gate it on `[ "$QUICK" -eq 0 ]`
4. If the check writes anything anywhere, STOP — cast-doctor is read-only

**Status helpers:**

| Helper | When to use |
|---|---|
| `_say_ok` | The check passed |
| `_say_warn` | The check found a degraded but not broken state |
| `_say_err` | The check found a broken/missing critical piece |
| `_say_info` | Informational, not pass/fail (e.g., "Agents: 22 installed") |

## PR Checklist

- [ ] `bash install.sh && bash uninstall.sh` round-trip clean
- [ ] BATS tests pass: `bats tests/`
- [ ] `bash -n bin/cast-doctor install.sh uninstall.sh` — all syntax-check
- [ ] `cast-doctor --quick` and `cast-doctor --json` both work
- [ ] No writes to disk anywhere — cast-doctor is strictly read-only
- [ ] No hardcoded `/Users/<name>/` paths — `$HOME` / `~/`
- [ ] `CHANGELOG.md` updated for user-visible changes

## Code Style

- All scripts: `set -euo pipefail`
- Quote variable expansions: `"$var"`
- Use `[[ ]]` for conditionals, not `[ ]`
- ShellCheck clean — no warnings
- Python: stdlib only

## Reporting issues

Use the GitHub issue templates under `.github/ISSUE_TEMPLATE/`.
