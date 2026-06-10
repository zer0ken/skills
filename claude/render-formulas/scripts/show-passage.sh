#!/usr/bin/env bash
# Render a LaTeX *passage* (prose + inline $..$ and display \[..\] math) to ONE
# tightly-cropped PNG and open it in the OS default viewer. This is the preferred
# way to show math in context, rather than one bare formula per image.
#
# Prose is rendered with XeLaTeX + kotex, so the explanatory text can be in the
# user's language (Korean, etc.), while math keeps Computer Modern.
#
# Usage:
#   show-passage.sh "<latex body>" [output.png] [width]
#   <body-producing-cmd> | show-passage.sh - [output.png] [width]
# Defaults: output ./tmp/latex/passage_<pid>.png, width 14cm.
set -euo pipefail

body_arg="${1:?usage: show-passage.sh \"<latex body>\"|- [output.png] [width]}"
out="${2:-}"
width="${3:-14cm}"

if [ "$body_arg" = "-" ]; then body="$(cat -)"; else body="$body_arg"; fi

# PATH/env fallbacks for shells whose environment predates the scoop installs.
# (No-ops on machines where the tools are already on PATH, e.g. macOS/Linux.)
sa="$HOME/scoop/apps"
command -v xelatex >/dev/null 2>&1 || { d="$sa/latex/current/texmfs/install/miktex/bin/x64"; [ -d "$d" ] && PATH="$d:$PATH"; }
if ! command -v magick >/dev/null 2>&1; then
    im="$sa/imagemagick/current"
    if [ -d "$im" ]; then
        PATH="$im:$PATH"
        export MAGICK_HOME="$im" MAGICK_CONFIGURE_PATH="$im" MAGICK_CODER_MODULE_PATH="$im/modules/coders"
    fi
fi
command -v gswin64c >/dev/null 2>&1 || command -v gs >/dev/null 2>&1 || {
    for d in "$sa"/ghostscript/current/bin "$sa"/ghostscript/*/bin; do [ -d "$d" ] && { PATH="$d:$PATH"; break; }; done
}

if [ -z "$out" ]; then mkdir -p ./tmp/latex; out="./tmp/latex/passage_$$.png"; fi
mkdir -p "$(dirname "$out")"
out_abs="$(cd "$(dirname "$out")" && pwd)/$(basename "$out")"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
tex="$tmp/passage.tex"

# Build the document without shell-expanding the body (it contains $ and \).
{
    printf '%s\n' "\documentclass[border=12pt,varwidth=$width]{standalone}"
    printf '%s\n' "\usepackage{kotex}"
    printf '%s\n' "\usepackage{amsmath,amssymb,amsfonts}"
    printf '%s\n' "\setmainhangulfont{Malgun Gothic}"
    printf '%s\n' "\begin{document}"
    printf '%s\n' "$body"
    printf '%s\n' "\end{document}"
} > "$tex"

# XeLaTeX -> PDF (standalone crops to content), surfacing only real "! ..." errors.
xelatex -halt-on-error -interaction=nonstopmode -output-directory="$tmp" "$tex" \
    | sed -n '/^!/,/^ /p' >&2

# PDF -> PNG via ImageMagick (Ghostscript delegate), flattened on white.
magick -density 300 "$tmp/passage.pdf" -background white -alpha remove -alpha off "$out_abs"

case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*) cmd.exe //c start "" "$(cygpath -w "$out_abs")" >/dev/null 2>&1 || true ;;
    Darwin)               open "$out_abs" || true ;;
    *)                    command -v xdg-open >/dev/null 2>&1 && xdg-open "$out_abs" >/dev/null 2>&1 || true ;;
esac

echo "$out_abs"
