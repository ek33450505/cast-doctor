# Security Policy

## Supported Versions

| Version | Support Status |
|---|---|
| 0.1.x | Full support — security fixes backported |
| < 0.1 | No longer supported |

## Reporting a Vulnerability

**Do NOT open a public GitHub issue for security vulnerabilities.**

Report privately using [GitHub Security Advisories](https://github.com/ek33450505/cast-doctor/security/advisories/new).

### What to Include

- **Version** — `cast-doctor version`
- **Operating system** — `sw_vers` (macOS) or `lsb_release -a` (Linux)
- **Which file or check** — e.g., `bin/cast-doctor`, "the schema check"
- **Steps to reproduce** — minimal, clear reproduction steps
- **Impact** — what an attacker could do

### Response Timeline

| Severity | Acknowledgment | Fix Target |
|---|---|---|
| Critical | 48 hours | 14 days |
| High | 48 hours | 30 days |
| Medium / Low | 5 business days | Next release |

## Security Design Notes

cast-doctor is a read-only diagnostic. Key design decisions:

- **No writes** — every check is a read against the filesystem, `cast.db`, or `settings.json`. cast-doctor never modifies state.
- **No network calls** — `install.sh`, `uninstall.sh`, and the CLI make no external network requests.
- **No credentials** — cast-doctor does not handle API keys, tokens, or secrets.
- **Path expansion is bounded** — env-var paths default to `~/.claude/*`; the script does not resolve symlinks outside the home directory tree.
- **JSON parsing is exception-safe** — malformed `settings.json` is caught and reported as a warning, not a crash.

## Out of Scope

- Vulnerabilities in the Claude API or Anthropic services — report to [Anthropic](https://www.anthropic.com/security)
- Vulnerabilities in third-party tools (bash, Python, sqlite3, BATS)
- The contents of `~/.claude/settings.json` or hook scripts — those are user-controlled inputs

## Trust Model

cast-doctor assumes:

- The user controls `~/.claude/`. Files in that directory are trusted input for reporting purposes (not executed).
- The `sqlite3` binary is trustworthy. cast-doctor only reads from `cast.db`; it never writes.
- The Python interpreter is trustworthy. cast-doctor uses stdlib only (json, os, re, datetime, sys).
