---
name: render-formulas
description: Use when the user wants to see, preview, or generate an image of a LaTeX math formula or equation — visualizing math notation, rendering a formula to PNG, checking that LaTeX syntax produces the intended output, or creating equation image assets for docs/READMEs/slides. Also handles "render-formulas update" / "업데이트" to self-update.
---

# Render Formulas

## Overview

Render a LaTeX math formula to a PNG with [pnglatex](https://github.com/mneri/pnglatex)
(bundled in `scripts/pnglatex`), then surface it **two ways**: open it in the OS image
viewer **for the user**, and **Read it yourself** to confirm it rendered.

If invoked with the argument `update` / `업데이트`: skip rendering and run the
**self-update check** in [Source & Updates](#source--updates) instead.

## When to Use

- "Render `E=mc^2`" / "show me what this LaTeX looks like" / "preview this equation"
- Verifying a LaTeX snippet compiles and looks right before pasting it elsewhere
- Producing equation images for a README, doc, or slide

**Not for:** full LaTeX documents (use `pdflatex` directly), or non-math text.

## Quick Start

One command renders with good defaults (display style, common math packages, 300 DPI)
and opens the result in the OS default viewer:

```bash
bash ~/.claude/skills/render-formulas/scripts/show-formula.sh "\sum_{i=0}^n i = \frac{n(n+1)}{2}"
```

It prints the PNG's absolute path. **Then Read that PNG** so it also appears in the session.

For more control, call pnglatex directly (see Options) and open the file yourself.

## How Results Are Shown (UX)

**Standard, every OS — open the PNG in the system default image viewer.** This is what the
wrapper does, and it is the reliable way the *user* actually sees the image. Claude should
**also Read the PNG** (shows it to Claude and in the web/desktop UI).

Open-in-viewer commands by OS (the wrapper picks the right one automatically):

| OS | Command (from bash) |
|----|---------------------|
| Windows | `cmd.exe //c start "" "$(cygpath -w FILE)"` |
| macOS | `open FILE` |
| Linux | `xdg-open FILE` |

**Inline-in-terminal** is nicer but conditional: it only works when the **user** runs the
command in their own interactive shell. Claude's tool output is *captured*, so image escape
sequences never reach the screen — running these from a Claude tool just yields garbage
bytes. Offer them to the user; don't run them to "display" inline yourself.

| Terminal | Inline command |
|----------|----------------|
| Windows Terminal ≥1.22 / any Sixel terminal | `magick FILE sixel:-` |
| iTerm2 | `imgcat FILE` |
| Kitty | `kitten icat FILE` |
| WezTerm | `wezterm imgcat FILE` |

## Dependencies

Needs `latex`, `dvipng`, and `imagemagick` on PATH. `optipng` (image optimization, `-O`)
is optional.

| OS | One-time install |
|----|------------------|
| Windows | `scoop install latex imagemagick` then `initexmf --set-config-value '[MPM]AutoInstall=1'` |
| macOS | `brew install --cask mactex-no-gui && brew install imagemagick` (`dvipng` via `tlmgr install dvipng`) |
| Linux | `sudo apt install texlive dvipng imagemagick` |

Verify: `command -v latex dvipng`.

## Options (pnglatex)

| Need | Flag | Example |
|------|------|---------|
| The formula | `-f` | `-f "\frac{a}{b}"` |
| Output file | `-o` | `-o ./tmp/latex/x.png` |
| Resolution (default 96 → too soft) | `-d` | `-d 300` |
| Display math (centered, large) | `-e displaymath` | `-e displaymath -f "\sum_{i=0}^n i"` |
| Extra packages (colon-separated) | `-p` | `-p amssymb:amsmath` |
| Font size (pt, default 11) | `-s` | `-s 14` |
| Transparent background | `-b Transparent` | |
| Full help | `-h` | |

Multi-line / alignment: `-e "align*"` with `-p amsmath`, formula using `\\` and `&`.

## Gotchas

- **Run via bash, not PowerShell.** pnglatex and the wrapper are `#!/bin/bash` scripts.
- **Don't use `-P`/`-B`/`-m` (padding/border/margin) on Windows.** pnglatex calls bare
  `convert`, but ImageMagick 7 ships only `magick` (no `convert.exe`), so `convert` resolves
  to `C:\WINDOWS\system32\convert.exe` (a disk tool) and fails. For padding/border, render
  plain then post-process: `magick eq.png -bordercolor white -border 20x20 eq.png`.
- **Always pass `-o`.** Without it the PNG lands in `$PWD` with a random name.
- **Bump `-d`.** Default DPI is 96; use `-d 300` for crisp output.
- **First render may pause briefly** while TeX auto-installs packages; a MiKTeX
  "not checked for updates" notice is harmless and does not fail the render.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Calling a script from PowerShell | Use the Bash tool / `bash <path>` |
| Forgetting to Read the PNG | The user can't see it otherwise — Read it (the wrapper opens the viewer) |
| Running an inline command yourself to "show" the user | Output is captured; open the viewer instead, or have the user run it |
| `\sum_{i=0}^n` looks cramped | Add `-e displaymath` for proper sizing |
| `Undefined control sequence` on `\mathbb` etc. | Add the package: `-p amssymb:amsmath` |

## Source & Updates

Distributed from a git repository, not bundled with any project:

- Repository: https://github.com/zer0ken/skills (folder `render-formulas/`)
- Installed copy: `~/.claude/skills/render-formulas/`

**Install or update (no git or clone needed):**

PowerShell (Windows):
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/render-formulas/install.ps1 | iex
```
Bash (macOS / Linux / WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/render-formulas/install.sh | bash
```
Re-running the command always fetches the latest `SKILL.md` **and** scripts — install and
update are the same command. (The installer refuses to overwrite a symlinked install dir,
so a developer working from a cloned repo is never clobbered.)

**Self-update check** (triggered by `render-formulas update`): do NOT render. Diff the
canonical files against the installed copies and report:

```bash
base=https://raw.githubusercontent.com/zer0ken/skills/main/render-formulas
for f in SKILL.md scripts/pnglatex scripts/show-formula.sh; do
  curl -fsSL "$base/$f" -o "/tmp/rf-remote-$(basename "$f")"
  diff "/tmp/rf-remote-$(basename "$f")" "$HOME/.claude/skills/render-formulas/$f" \
    && echo "$f: up to date" || echo "$f: UPDATE AVAILABLE"
done
```
- All up to date → tell the user.
- Any update available → show the one-line install command above and offer to run it.
  Updating overwrites the installed files, so confirm with the user first.
