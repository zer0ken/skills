#!/usr/bin/env bash
# Install or update the `cookbook` skill into the personal Codex skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.codex/skills/cookbook"
src="https://raw.githubusercontent.com/zer0ken/skills/main/codex/cookbook/SKILL.md"

mkdir -p "$dest"
curl -fsSL "$src" -o "$dest/SKILL.md"

echo "cookbook skill installed/updated at $dest"
echo "Restart Codex (or open a new session) to pick it up."
