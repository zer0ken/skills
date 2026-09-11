#!/usr/bin/env bash
# Install or update the `do-it` skill into the personal Codex skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.codex/skills/do-it"
base="https://raw.githubusercontent.com/zer0ken/skills/main/codex/do-it"

# Protect a developer's symlinked working copy from being clobbered by remote files.
if [ -L "$dest" ]; then
    echo "Refusing to overwrite $dest - it is a symlink (developer setup)." >&2
    echo "Edit the source repo directly, or remove the symlink to install a fetched copy." >&2
    exit 1
fi

mkdir -p "$dest/scripts"
curl -fsSL "$base/SKILL.md"               -o "$dest/SKILL.md"
curl -fsSL "$base/scripts/launch-role.ps1"   -o "$dest/scripts/launch-role.ps1"
curl -fsSL "$base/scripts/run-role.ps1"      -o "$dest/scripts/run-role.ps1"
curl -fsSL "$base/scripts/wait-role.ps1"     -o "$dest/scripts/wait-role.ps1"
curl -fsSL "$base/scripts/make-worktree.ps1" -o "$dest/scripts/make-worktree.ps1"

echo "do-it skill installed/updated at $dest"
echo "Restart Codex (or open a new session) to pick it up, then invoke the do-it skill"
