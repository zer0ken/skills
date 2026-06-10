#!/usr/bin/env bash
# Install or update the `uv-setup` skill into the personal Codex skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.codex/skills/uv-setup"
src="https://raw.githubusercontent.com/zer0ken/skills/main/codex/uv-setup/SKILL.md"

# Protect a developer's symlinked working copy from being clobbered.
if [ -L "$dest" ]; then
  echo "Refusing to overwrite $dest - it is a symlink (developer setup). Edit the source repo directly." >&2
  exit 1
fi

mkdir -p "$dest"
curl -fsSL "$src" -o "$dest/SKILL.md"

echo "uv-setup skill installed/updated at $dest"
echo "Restart Codex (or open a new session) to pick it up."
