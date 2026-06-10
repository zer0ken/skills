#!/usr/bin/env bash
# Install or update the `render-formulas` skill into the personal Codex skills dir.
# Re-running this fetches the latest version (install and update are identical).
set -euo pipefail

dest="$HOME/.codex/skills/render-formulas"
base="https://raw.githubusercontent.com/zer0ken/skills/main/codex/render-formulas"

# Protect a developer's symlinked working copy from being clobbered by remote files.
if [ -L "$dest" ]; then
    echo "Refusing to overwrite $dest — it is a symlink (developer setup)." >&2
    echo "Edit the source repo directly, or remove the symlink to install a fetched copy." >&2
    exit 1
fi

mkdir -p "$dest/scripts"
curl -fsSL "$base/SKILL.md"                -o "$dest/SKILL.md"
curl -fsSL "$base/scripts/pnglatex"        -o "$dest/scripts/pnglatex"
curl -fsSL "$base/scripts/show-formula.sh" -o "$dest/scripts/show-formula.sh"
curl -fsSL "$base/scripts/show-passage.sh" -o "$dest/scripts/show-passage.sh"
chmod +x "$dest/scripts/pnglatex" "$dest/scripts/show-formula.sh" "$dest/scripts/show-passage.sh"

echo "render-formulas skill installed/updated at $dest"
echo "One-time toolchain (needs latex, dvipng, imagemagick on PATH):"
echo "  Windows: scoop install latex imagemagick"
echo "  macOS:   brew install --cask mactex-no-gui && brew install imagemagick"
echo "  Linux:   sudo apt install texlive dvipng imagemagick"
echo "Restart Codex (or open a new session) to pick it up."
