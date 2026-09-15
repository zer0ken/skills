#!/usr/bin/env bash
# Install or update the `pair` skill into the personal pi skills dir (~/.agents/skills).
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.agents/skills/pair"
base="https://raw.githubusercontent.com/zer0ken/skills/main/pi/pair"

# Protect a developer's symlinked working copy from being clobbered.
if [ -L "$dest" ]; then
  echo "Refusing to overwrite $dest - it is a symlink (developer setup). Edit the source repo directly." >&2
  exit 1
fi

mkdir -p "$dest"
curl -fsSL "$base/SKILL.md" -o "$dest/SKILL.md"
curl -fsSL "$base/pair-select-advisor.sh" -o "$dest/pair-select-advisor.sh"
chmod +x "$dest/pair-select-advisor.sh"

echo "pair skill installed/updated at $dest"
echo "Restart the agent (or open a new session) to pick it up, then run /pair"
