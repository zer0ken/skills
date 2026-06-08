#!/usr/bin/env bash
# Install or update the `cookbook` skill into the personal Claude Code skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.claude/skills/cookbook"
src="https://raw.githubusercontent.com/zer0ken/skills/main/cookbook/SKILL.md"

mkdir -p "$dest"
curl -fsSL "$src" -o "$dest/SKILL.md"

echo "cookbook skill installed/updated at $dest"
echo "Restart Claude Code (or open a new session) to pick it up, then run /cookbook"
