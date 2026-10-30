#!/usr/bin/env bash
# Install or update the rv skill.
set -euo pipefail

dest="$HOME/.claude/skills/rv"
src="https://raw.githubusercontent.com/zer0ken/skills/main/claude/rv"

if [ -L "$dest" ]; then
  echo "Refusing to overwrite $dest - it is a symlink (developer setup). Edit the source repo directly." >&2
  exit 1
fi

mkdir -p "$dest"
curl -fsSL "$src/SKILL.md" -o "$dest/SKILL.md"

echo "rv skill installed/updated at $dest"
echo 'Restart the agent (or open a new session) to pick it up, then use /rv'
