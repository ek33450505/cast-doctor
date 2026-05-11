#!/bin/bash
# install.sh — cast-doctor installer
# Copies the CLI shim into ~/.local/bin so `cast-doctor` is callable directly.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CD_VERSION="$(cat "$REPO_DIR/VERSION" 2>/dev/null || echo unknown)"

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_YELLOW='\033[0;33m'
  C_RED='\033[0;31m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_RESET=''
fi

_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_warn() { printf "${C_YELLOW}  [warn]${C_RESET} %s\n" "$*" >&2; }
_fail() { printf "${C_RED}  [fail]${C_RESET} %s\n" "$*" >&2; exit 1; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-doctor v${CD_VERSION} installer${C_RESET}\n"
printf "═════════════════════════════════════════════\n"
printf "  Health check for any Claude Code install.\n\n"

_step "Checking prerequisites..."
command -v python3 >/dev/null || _fail "python3 not found"
command -v sqlite3 >/dev/null || _warn "sqlite3 not found — cast.db checks will be skipped at runtime"
_ok "python3 available"

_step "Installing CLI shim..."
BIN_TARGET="${CAST_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$BIN_TARGET"
cp "$REPO_DIR/bin/cast-doctor" "$BIN_TARGET/cast-doctor"
chmod 755 "$BIN_TARGET/cast-doctor"
_ok "cast-doctor → $BIN_TARGET/cast-doctor"

if [[ ":$PATH:" != *":$BIN_TARGET:"* ]]; then
  _warn "$BIN_TARGET is not on your PATH — add it to your shell rc to use \`cast-doctor\` directly."
fi

printf "\n${C_BOLD}═════════════════════════════════════════════${C_RESET}\n"
printf "${C_GREEN}cast-doctor v${CD_VERSION} installed.${C_RESET}\n\n"
printf "${C_BOLD}Try it:${C_RESET}\n"
printf "  cast-doctor              # full health check\n"
printf "  cast-doctor --quick      # skip the slower checks\n"
printf "  cast-doctor --json       # machine-readable output\n"
printf "  cast-doctor --strict     # exit non-zero on any warning\n\n"
