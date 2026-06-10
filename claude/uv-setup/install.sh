#!/usr/bin/env bash
# Install or update the `uv-setup` skill into the personal Claude Code skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.claude/skills/uv-setup"
src="https://raw.githubusercontent.com/zer0ken/skills/main/claude/uv-setup/SKILL.md"

# Protect a developer's symlinked working copy from being clobbered.
if [ -L "$dest" ]; then
  echo "Refusing to overwrite $dest - it is a symlink (developer setup). Edit the source repo directly." >&2
  exit 1
fi

mkdir -p "$dest"
curl -fsSL "$src" -o "$dest/SKILL.md"

echo "uv-setup skill installed/updated at $dest"
echo "Restart Claude Code (or open a new session) to pick it up, then run /uv-setup"
