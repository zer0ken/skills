# zer0ken/skills

Personal [Claude Code](https://claude.com/claude-code) skills. Each skill is
installed individually as a personal skill (no marketplace) — one command fetches
the skill file into `~/.claude/skills/<skill>/`.

## cookbook

Finds Anthropic Claude cookbook recipes for a topic. Invoked as `/cookbook <topic>`;
with no argument it infers a topic from the current conversation.

**Install / update:**

PowerShell (Windows)
```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/cookbook/install.ps1 | iex
```

Bash (macOS / Linux / WSL)
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/cookbook/install.sh | bash
```

Re-running the command updates to the latest version. Inside Claude Code, run
`/cookbook update` to check whether a newer version is available.
