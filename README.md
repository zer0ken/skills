# zer0ken/my-skills

Personal agent skills, one source copy per skill under [skills/](skills/). Each skill describes a methodology; each agent runtime decides which of its native features carries it out, so there are no per-agent copies.

## Skills

| Skill | Description |
|-------|-------------|
| [claude-cookbook](skills/claude-cookbook/SKILL.md) | Find Anthropic Claude Cookbook recipes for a topic. |
| [ds](skills/ds/SKILL.md) | 저장소 아키텍처와 근거를 대조하는 read-only 설계 기획. |
| [eli5](skills/eli5/SKILL.md) | 주제를 쉬운 말과 큰 그림으로 설명한다. |
| [handoff](skills/handoff/SKILL.md) | 대화를 핸드오프 문서로 압축해 다른 에이전트가 이어받게 한다. |
| [issue](skills/issue/SKILL.md) | 이슈를 올린다. 본문은 항목 이름을 붙인 불릿 한 줄씩, 상세는 코멘트로. |
| [openai-cookbook](skills/openai-cookbook/SKILL.md) | Find OpenAI Cookbook examples for a topic. |
| [osiri](skills/osiri/SKILL.md) | Technical reviews of code, designs, and PRs, plus peer audits of reports, claims, evidence, and figures. |
| [pov](skills/pov/SKILL.md) | 제품과 관련 기술을 조사하고 일곱 전문가 관점의 의견, 근거와 이견을 종합한다. |
| [pr](skills/pr/SKILL.md) | PR 을 올린다. 불릿 3줄 요약과 이슈 참조, 상세는 코멘트로. |
| [prior-research](skills/prior-research/SKILL.md) | 논문과 저장소 기록을 포함한 선행 연구를 반복 검색으로 조사하고 검색 기록과 근거표를 남긴다. |
| [prv](skills/prv/SKILL.md) | 계획·설계 문서를 관점별 blind 로컬 모델 리뷰와 다른 계열 한 세션의 검증·정리로 구현 전에 검수한다. |
| [problem-modeling](skills/problem-modeling/SKILL.md) | 해법 선택 전 문제의 입력·출력·경계 사례와 평가 기준 정의. |
| [refactor](skills/refactor/SKILL.md) | 기능과 성능을 보존하는 리팩토링 계획·실행과 저장소 예방책 감사. |
| [rv](skills/rv/SKILL.md) | Adversarial code, design, and PR review with evidence and follow-up findings. |
| [swarm-review](skills/srv/SKILL.md) | 코드 변경을 rv 항목 관점별 blind 로컬 모델 리뷰어 여러 세션과 운영자 한 세션의 검증·추가 라운드로 리뷰하고 리뷰 문서 하나를 돌려준다. |
| [sucks](skills/sucks/SKILL.md) | Korean technical prose style rules for docs, issues, PR bodies, and comments. |
| [task-graph](skills/task-graph/SKILL.md) | 여러 턴이 걸리는 작업을 태스크와 의존성의 유향 그래프로 계획하고 그 그래프에서 스케줄링한다. |
| [tdd-is-dead](skills/tdd-is-dead/SKILL.md) | 범위와 의도를 먼저 파악하고 최소 테스트로 검증하는 코드 작업 순서와, 외부 PoC를 ds 이식 설계로 제품에 반영하는 경로. TDD식 작성-실행-수정 반복을 금지한다. |
| [teqr](skills/teqr/SKILL.md) | Write and revise technical reports, runbooks, experiment notes, and test or benchmark plans. |

## Install / Update

Clone the repository once and link the skills each agent should load. A link enables a skill for that agent and removing the link disables it.

```bash
git clone https://github.com/zer0ken/my-skills.git ~/.agents/my-skills
ln -s ~/.agents/my-skills/skills/<skill> ~/.agents/skills/<skill>
```

Agents that read `~/.agents/skills` directly (Codex, pi, Hermes) see every linked skill there and use their own per-skill switches to turn one off. Claude Code reads `~/.claude/skills`, so link `~/.claude/skills/<skill>` to the same source to enable it there. Update with `git -C ~/.agents/my-skills pull`.
