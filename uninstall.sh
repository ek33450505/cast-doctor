#!/bin/bash
# uninstall.sh — remove cast-doctor CLI from common install locations.
set -euo pipefail

if [ -t 1 ] && [ "${TERM:-}" != "dumb" ]; then
  C_BOLD='\033[1m'; C_GREEN='\033[0;32m'; C_RESET='\033[0m'
else
  C_BOLD='' C_GREEN='' C_RESET=''
fi
_ok()   { printf "${C_GREEN}  [ok]${C_RESET} %s\n" "$*"; }
_step() { printf "\n${C_BOLD}%s${C_RESET}\n" "$*"; }

printf "\n${C_BOLD}cast-doctor uninstaller${C_RESET}\n"
printf "═════════════════════════════════════════════\n\n"

_step "Removing CLI shim..."
for d in "$HOME/.local/bin" "/usr/local/bin" "/opt/homebrew/bin"; do
  if [ -f "$d/cast-doctor" ]; then
    rm -f "$d/cast-doctor" && _ok "removed $d/cast-doctor"
  fi
done

printf "\n${C_GREEN}cast-doctor uninstalled.${C_RESET}\n\n"
exit 0
