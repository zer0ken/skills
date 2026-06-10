#!/usr/bin/env bash
# Render a LaTeX formula to PNG with good defaults and open it in the OS default
# image viewer. Usage: show-formula.sh "<formula>" [output.png]
set -euo pipefail

formula="${1:?usage: show-formula.sh \"<formula>\" [output.png]}"
out="${2:-}"

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
pnglatex="$skill_dir/scripts/pnglatex"

# Make the toolchain findable even in a shell whose PATH predates a scoop install.
if ! command -v latex >/dev/null 2>&1; then
    miktex="$HOME/scoop/apps/latex/current/texmfs/install/miktex/bin/x64"
    [ -d "$miktex" ] && PATH="$miktex:$PATH"
fi

if [ -z "$out" ]; then
    mkdir -p ./tmp/latex
    out="./tmp/latex/formula_$$.png"
fi
mkdir -p "$(dirname "$out")"

bash "$pnglatex" -S -d 300 -e displaymath -p amssymb:amsmath -f "$formula" -o "$out"

abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

# Open in the OS default image viewer.
case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) cmd.exe //c start "" "$(cygpath -w "$abs")" >/dev/null 2>&1 || true ;;
    Darwin)               open "$abs" || true ;;
    *)                    command -v xdg-open >/dev/null 2>&1 && xdg-open "$abs" >/dev/null 2>&1 || true ;;
esac

echo "$abs"
