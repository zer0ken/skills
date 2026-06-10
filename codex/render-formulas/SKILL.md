---
name: render-formulas
description: Use when the user wants to see, preview, or generate an image of a LaTeX math formula or equation — visualizing math notation, rendering a formula to PNG, checking that LaTeX syntax produces the intended output, or creating equation image assets for docs/READMEs/slides. Also handles "render-formulas update" / "업데이트" to self-update.
---

# Render Formulas

## Overview

Render LaTeX math to a PNG, then surface it **two ways**: open it in the OS image viewer
**for the user**, and **Read it yourself** to confirm it rendered.

**Render in context (recommended).** Prefer rendering the explanatory passage — prose with
inline `$..$` and display `\[..\]` math — as **one readable image**, rather than one bare
formula per image. A formula shown together with the sentence that motivates it is far
easier to follow. Use `show-passage.sh` for that; reach for `show-formula.sh` only when a
single standalone formula is genuinely all that's wanted.

**Write the prose in the user's language** (e.g. Korean). `show-passage.sh`
renders via XeLaTeX + `kotex`, so Hangul and other scripts typeset correctly while math
stays in Computer Modern.

If invoked with the argument `update` / `업데이트`: skip rendering and run the
**self-update check** in [Source & Updates](#source--updates) instead.

## When to Use

- "Render `E=mc^2`" / "show me what this LaTeX looks like" / "preview this equation"
- Verifying a LaTeX snippet compiles and looks right before pasting it elsewhere
- Producing equation images for a README, doc, or slide

**Not for:** full LaTeX documents (use `pdflatex` directly), or non-math text.

## Rendering

Both wrappers render, open the OS viewer, and print the PNG's absolute path.
**Then Read that PNG** so it also appears in the session.

**Recommended — a passage in context** (`show-passage.sh`): prose + inline `$..$` and
display `\[..\]` math, wrapped to a width, as one image. Pass the body as an argument, or
`-` to read it from stdin (use a quoted heredoc so the shell does not expand `$`):

```bash
cat <<'TEX' | bash ~/.codex/skills/render-formulas/scripts/show-passage.sh - ./tmp/latex/var.png 13cm
The \textbf{sample variance} of $x_1,\dots,x_n$ with mean
$\bar{x}=\frac{1}{n}\sum_{i=1}^{n}x_i$ is
\[ s^2 = \frac{1}{n-1}\sum_{i=1}^{n}(x_i-\bar{x})^2 . \]
The divisor $n-1$ (Bessel's correction) corrects for using $\bar{x}$ in place of $\mu$.
TEX
```
Args: `show-passage.sh "<body>"|- [output.png] [width]` (default width `14cm`).

**Quick single formula** (`show-formula.sh`): math only, display style, good defaults.

```bash
bash ~/.codex/skills/render-formulas/scripts/show-formula.sh "\sum_{i=0}^n i = \frac{n(n+1)}{2}"
```

For finer control over a single formula, call `pnglatex` directly (see Options).

## How Results Are Shown (UX)

**Standard, every OS — open the PNG in the system default image viewer.** This is what the
wrapper does, and it is the reliable way the *user* actually sees the image. Codex should
**also view the PNG** so it can confirm the rendered result.

Open-in-viewer commands by OS (the wrapper picks the right one automatically):

| OS | Command (from bash) |
|----|---------------------|
| Windows | `cmd.exe //c start "" "$(cygpath -w FILE)"` |
| macOS | `open FILE` |
| Linux | `xdg-open FILE` |

**Inline-in-terminal** is nicer but conditional: it only works when the **user** runs the
command in their own interactive shell. Codex tool output is *captured*, so image escape
sequences never reach the screen — running these from a Codex tool just yields garbage
bytes. Offer them to the user; don't run them to "display" inline yourself.

| Terminal | Inline command |
|----------|----------------|
| Windows Terminal ≥1.22 / any Sixel terminal | `magick FILE sixel:-` |
| iTerm2 | `imgcat FILE` |
| Kitty | `kitten icat FILE` |
| WezTerm | `wezterm imgcat FILE` |

## Dependencies

Single formula (`show-formula.sh` / pnglatex) needs `latex`, `dvipng`, `imagemagick`.
Passage (`show-passage.sh`) additionally needs `xelatex` (bundled with any TeX distro),
`kotex` (auto-installed by MiKTeX/TeX Live on first use), and **Ghostscript** (for the
PDF→PNG step). `optipng` (`-O`) is optional.

| OS | One-time install |
|----|------------------|
| Windows | `scoop install latex imagemagick ghostscript` then `initexmf --set-config-value '[MPM]AutoInstall=1'` |
| macOS | `brew install --cask mactex-no-gui && brew install imagemagick ghostscript` (`dvipng` via `tlmgr install dvipng`) |
| Linux | `sudo apt install texlive-xetex texlive-lang-korean dvipng imagemagick ghostscript` |

Verify: `command -v latex dvipng xelatex gs`. The default Hangul font is `Malgun Gothic`
(Windows); on other OSes set another installed Korean font in `show-passage.sh`.

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

- Repository: https://github.com/zer0ken/skills (folder `codex/render-formulas/`)
- Installed copy: `~/.codex/skills/render-formulas/`

**Install or update (no git or clone needed):**

PowerShell (Windows):
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/render-formulas/install.ps1 | iex
```
Bash (macOS / Linux / WSL):
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/render-formulas/install.sh | bash
```
Re-running the command always fetches the latest `SKILL.md` **and** scripts — install and
update are the same command. (The installer refuses to overwrite a symlinked install dir,
so a developer working from a cloned repo is never clobbered.)

**Self-update check** (triggered by `render-formulas update`): do NOT render. Diff the
canonical files against the installed copies and report:

```bash
base=https://raw.githubusercontent.com/zer0ken/skills/main/codex/render-formulas
for f in SKILL.md scripts/pnglatex scripts/show-formula.sh scripts/show-passage.sh; do
  curl -fsSL "$base/$f" -o "/tmp/rf-remote-$(basename "$f")"
  diff "/tmp/rf-remote-$(basename "$f")" "$HOME/.codex/skills/render-formulas/$f" \
    && echo "$f: up to date" || echo "$f: UPDATE AVAILABLE"
done
```
- All up to date → tell the user.
- Any update available → show the one-line install command above and offer to run it.
  Updating overwrites the installed files, so confirm with the user first.
