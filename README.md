# zer0ken/skills

Personal skills organized by agent runtime.

| Runtime | Location | Install target |
|---------|----------|----------------|
| Claude Code | [claude/](claude/) | `~/.claude/skills/<skill>/` |
| Codex | [codex/](codex/) | `~/.codex/skills/<skill>/` |
| Shared | [shared/](shared/) | Common references or assets for future platform-specific skills |

## Skills

| Skill | Description |
|-------|-------------|
| [claude-cookbook](claude/claude-cookbook/SKILL.md) | Find Anthropic Claude Cookbook recipes for a topic. |
| [openai-cookbook](claude/openai-cookbook/SKILL.md) | Find OpenAI Cookbook examples for a topic. |
| [osiri](claude/osiri/SKILL.md) | Peer review protocol for auditing another agent's claims, evidence, and figures. |
| [render-formulas](claude/render-formulas/SKILL.md) | Render a LaTeX formula to a PNG and open it in the image viewer. |
| [sucks](claude/sucks/SKILL.md) | Korean technical prose style rules for docs, issues, PR bodies, and comments. |
| [uv-setup](claude/uv-setup/SKILL.md) | Convert a project to uv-based dependency management and enforce the uv workflow. |

## Install / Update

Open a skill above and copy the install command from its page: `irm ... | iex` on Windows (PowerShell), `curl ... | bash` on macOS/Linux. The linked page carries the Claude Code command; the Codex command is on the matching page under [codex/](codex/). Re-running an installer fetches the latest version.
