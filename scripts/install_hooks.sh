#!/usr/bin/env bash
# ==========================================================
# install_hooks.sh - Auto-installs pre-commit hook
# ==========================================================

set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
YELLOW="\033[1;33m"
NC="\033[0m"

ok(){ echo -e "${GREEN}✔ $1${NC}"; }
err(){ echo -e "${RED}✖ $1${NC}"; exit 1; }
header(){ echo -e "\n${BLUE}🚀 $1${NC}"; }

ROOT_DIR=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOKS_DIR="$ROOT_DIR/.git/hooks"
SOURCE_HOOK="$ROOT_DIR/scripts/pre-commit"

header "Installing Git pre-commit hook..."

if [ ! -f "$SOURCE_HOOK" ]; then
  err "pre-commit hook not found in scripts/. Please add it there first."
fi

mkdir -p "$HOOKS_DIR"
cp "$SOURCE_HOOK" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

if command -v flutter &> /dev/null; then
  ok "$(flutter --version | head -n 1)"
else
  err "Flutter not found in PATH."
fi

if command -v dart &> /dev/null; then
  ok "$(dart --version 2>&1)"
else
  err "Dart not found in PATH."
fi

ok "Pre-commit hook installed successfully!"
echo -e "${BLUE}➡ Run: git add . && git commit -m 'verify hook'${NC}\n"
