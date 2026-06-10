# zer0ken/skills

Personal skills organized by agent runtime.

| Runtime | Location | Install target |
|---------|----------|----------------|
| Claude Code | [claude/](claude/) | `~/.claude/skills/<skill>/` |
| Codex | [codex/](codex/) | `~/.codex/skills/<skill>/` |
| Shared | [shared/](shared/) | Common references or assets for future platform-specific skills |

## Skills

| Skill | Description | Runtimes |
|-------|-------------|----------|
| claude-cookbook | Find Anthropic Claude Cookbook recipes for a topic. | [Claude Code](claude/claude-cookbook/), [Codex](codex/claude-cookbook/) |
| openai-cookbook | Find OpenAI Cookbook examples for a topic. | [Claude Code](claude/openai-cookbook/), [Codex](codex/openai-cookbook/) |
| render-formulas | Render a LaTeX formula to a PNG and open it in the image viewer. | [Claude Code](claude/render-formulas/), [Codex](codex/render-formulas/) |
| uv-setup | Convert a project to uv-based dependency management and enforce the uv workflow. | [Claude Code](claude/uv-setup/), [Codex](codex/uv-setup/) |

## Install / Update

Claude Code:

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/<skill>/install.ps1 | iex
```
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/<skill>/install.sh | bash
```

Codex:

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/<skill>/install.ps1 | iex
```
```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/<skill>/install.sh | bash
```

Re-running an installer fetches the latest version for that runtime.
