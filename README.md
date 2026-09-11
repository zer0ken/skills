# zer0ken/skills

Personal skills organized by agent runtime.

| Runtime | Location | Install target |
|---------|----------|----------------|
| Claude Code | [claude/](claude/) | `~/.claude/skills/<skill>/` |
| Codex | [codex/](codex/) | `~/.codex/skills/<skill>/` |
| pi | [pi/](pi/) | `~/.agents/skills/<skill>/` |
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
| [issue](claude/issue/SKILL.md) | 이슈를 올린다. 본문은 항목 이름을 붙인 불릿 한 줄씩, 상세는 코멘트로. |
| [pr](claude/pr/SKILL.md) | PR 을 올린다. 불릿 3줄 요약과 이슈 참조, 상세는 코멘트로. |
| [ponytail](claude/ponytail/SKILL.md) | 최소한의 해결책만 강제한다 (YAGNI, 간결). |
| [handoff](claude/handoff/SKILL.md) | 대화를 핸드오프 문서로 압축해 다른 에이전트가 이어받게 한다. |
| [grill-me](claude/grill-me/SKILL.md) | 계획/설계를 질문으로 끝까지 다지며 이해를 공유한다. |
| [zoom-out](claude/zoom-out/SKILL.md) | 더 넓은 맥락이나 고수준 관점을 요구한다. |
| [eli5](pi/eli5/SKILL.md) | 주제를 쉬운 말과 큰 그림으로 설명한다. |

## Install / Update

Open a skill above and copy the install command from its page: `irm ... | iex` on Windows (PowerShell), `curl ... | bash` on macOS/Linux. The linked page carries the Claude Code command; the Codex command is on the matching page under [codex/](codex/). Re-running an installer fetches the latest version.
