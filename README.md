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
| claude-cookbook | Find Anthropic Claude Cookbook recipes for a topic. | <details><summary>Claude Code</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/claude-cookbook/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/claude-cookbook/install.sh \| bash</pre></details><details><summary>Codex</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/claude-cookbook/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/claude-cookbook/install.sh \| bash</pre></details> |
| openai-cookbook | Find OpenAI Cookbook examples for a topic. | <details><summary>Claude Code</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/openai-cookbook/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/openai-cookbook/install.sh \| bash</pre></details><details><summary>Codex</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/openai-cookbook/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/openai-cookbook/install.sh \| bash</pre></details> |
| render-formulas | Render a LaTeX formula to a PNG and open it in the image viewer. | <details><summary>Claude Code</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/render-formulas/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/render-formulas/install.sh \| bash</pre></details><details><summary>Codex</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/render-formulas/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/render-formulas/install.sh \| bash</pre></details> |
| uv-setup | Convert a project to uv-based dependency management and enforce the uv workflow. | <details><summary>Claude Code</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/uv-setup/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/uv-setup/install.sh \| bash</pre></details><details><summary>Codex</summary><pre># Windows (PowerShell)<br>irm https://raw.githubusercontent.com/zer0ken/skills/main/codex/uv-setup/install.ps1 \| iex<br><br># macOS/Linux<br>curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/codex/uv-setup/install.sh \| bash</pre></details> |

## Install / Update

Expand a runtime in the table above and copy the command for your OS — `irm … | iex` on Windows (PowerShell), `curl … | bash` on macOS/Linux. Re-running an installer fetches the latest version for that runtime.
