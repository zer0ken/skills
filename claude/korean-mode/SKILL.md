---
name: korean-mode
description: "한국어 5문장 답변 모드를 켜고 끈다. 켜면 매 턴 답변 규칙을 주입하고, thinking을 끌 수 있는 모델에서는 thinking도 끈다."
argument-hint: "[on|off|status]"
disable-model-invocation: true
allowed-tools: Bash(node "${CLAUDE_SKILL_DIR}/scripts/toggle.mjs" *)
metadata:
  author: hrlee
  version: "1.2.0"
---

# korean-mode

!`node "${CLAUDE_SKILL_DIR}/scripts/toggle.mjs" "$ARGUMENTS"`

위 출력이 실행 결과입니다. 그 문장을 그대로 사용자에게 전달하고 끝냅니다. 다른 도구를 호출하거나 설명을 덧붙이지 않습니다.

## 설치와 업데이트

PowerShell (Windows):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/korean-mode/install.ps1 | iex
```

Bash (macOS/Linux/WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/korean-mode/install.sh | bash
```

같은 명령이 설치와 업데이트를 모두 한다. 다시 실행하면 SKILL.md와 RULES.md, scripts 아래 파일을 모두 최신 판으로 받는다.
