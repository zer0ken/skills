# zer0ken/skills

Personal [Claude Code](https://claude.com/claude-code) skills. Each skill installs
individually into `~/.claude/skills/<skill>/` (no marketplace).

| Skill | Description |
|-------|-------------|
| [cookbook](cookbook/) | Find Anthropic Claude cookbook recipes for a topic. |
| [render-formulas](render-formulas/) | Render a LaTeX formula to a PNG and open it in the image viewer. |

**Install / update** any skill (install == update):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/<skill>/install.ps1 | iex   # Windows
```
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/<skill>/install.sh | bash   # macOS / Linux / WSL
```

Inside Claude Code, `/<skill> update` checks whether a newer version is available.
See each skill's folder for details.
