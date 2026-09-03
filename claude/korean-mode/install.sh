#!/usr/bin/env bash
# Install or update the `korean-mode` skill into the personal Claude Code skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.claude/skills/korean-mode"
base="https://raw.githubusercontent.com/zer0ken/skills/main/claude/korean-mode"

# Protect a developer's symlinked working copy from being clobbered by remote files.
if [ -L "$dest" ]; then
    echo "Refusing to overwrite $dest - it is a symlink (developer setup)." >&2
    echo "Edit the source repo directly, or remove the symlink to install a fetched copy." >&2
    exit 1
fi

mkdir -p "$dest/scripts"
curl -fsSL "$base/SKILL.md"                  -o "$dest/SKILL.md"
curl -fsSL "$base/RULES.md"                  -o "$dest/RULES.md"
curl -fsSL "$base/scripts/toggle.mjs"        -o "$dest/scripts/toggle.mjs"
curl -fsSL "$base/scripts/prompt-hook.sh"    -o "$dest/scripts/prompt-hook.sh"
chmod +x "$dest/scripts/toggle.mjs" "$dest/scripts/prompt-hook.sh"

echo "korean-mode skill installed/updated at $dest"
echo "Needs Node.js and Bash (Git Bash on Windows) on PATH."
echo "Restart Claude Code (or open a new session) to pick it up, then run /korean-mode"
