---
name: issue
description: "이슈를 올린다. 본문은 `- **문제:**` 처럼 항목 이름을 붙인 불릿 한 줄씩으로 문제와 원인 또는 추정과 목표와 계획 중 필요한 것만 담고, 상세 설명은 이슈 코멘트로 따로 올린다. 한국어 산문에는 sucks 스킬을 반드시 적용한다. 사용자가 /issue 를 호출하거나 이슈를 올리라고 지시할 때 사용한다."
metadata:
  author: hrlee
  version: "1.3.0"
  domain: workflow
  triggers: 이슈, issue, 이슈 올려, 이슈 생성, gh issue create
  role: guardian
  scope: output
  output-format: action
---

# Issue

전역 규칙, 프로젝트 규칙 중 관련된 것을 다시 명시적으로 읽고 작업할 것.

## 선행 조건

Skill 도구로 `sucks` 를 먼저 호출한다. 본문과 코멘트의 한국어 산문 전체에 그 규칙을 적용한다.

## 본문

아래 템플릿을 채운다. 항목 하나가 불릿 한 줄이고, 그 줄은 한 문장으로 끝낸다. 항목 이름을 `**문제:**` 처럼 굵게 적어 어느 항목인지 드러낸다. 제목을 넣지 않는다.

```
- **문제:** 
- **원인:** 
- **목표:** 
- **계획:** 
```

필요한 항목만 이 순서로 남기고 나머지 줄은 지운다. 한 내용을 두 항목에 나누어 적지 않는다. 한 항목을 두 줄로 늘리지 않는다.

| 항목 | 적는 것 | 쓰는 경우 |
| --- | --- | --- |
| 문제 | 관측된 현상 | 항상 |
| 원인 | 확인한 원인 | 원인을 확인했을 때 |
| 추정 | 원인의 후보 | 원인을 확인하지 못했을 때. 원인을 쓴 경우에는 쓰지 않는다 |
| 목표 | 이슈를 해결해 달성하려는 상태 | 문제 문장에서 자명하지 않을 때 |
| 계획 | 바로 착수할 수 있는 작업 방향 | 원인을 확인했을 때 |

체크박스(`- [ ]`)를 쓰지 않는다. 본문은 이슈를 설명하는 자리이지 진행 상태를 추적하는 자리가 아니다. 하위 작업으로 쪼개야 하면 코멘트에 쓴다.

원인을 확인하지 못한 경우:

```
- **문제:** 20000건을 동시에 insert 하면 벡터 인덱스 서버가 종료 코드 없이 죽는다
- **추정:** 세그먼트 병합 경로에서 인덱스 락을 잡지 않는 것으로 추정한다
- **목표:** 동시 insert 부하에서 인덱스 서버가 살아남는 것을 목표로 한다
```

원인을 확인한 경우:

```
- **문제:** 20000건을 동시에 insert 하면 벡터 인덱스 서버가 종료 코드 없이 죽는다
- **원인:** 세그먼트 병합 경로가 인덱스 락을 잡지 않아 병합 중인 세그먼트를 다른 스레드가 해제한다
- **계획:** 병합 진입부에서 인덱스 락을 잡고 동시 insert 재현 테스트를 회귀 테스트로 추가한다
```

## 코멘트

본문의 각 항목은 한 줄로 끝낸다. 재현 절차, 로그, 조사 경과, 추정의 근거, 검토하고 배제한 원인, 계획의 세부 절차처럼 한 줄에 담기지 않는 내용은 전부 코멘트로 올린다. 본문에 넣지 않는다.

```bash
gh issue create --title "<제목>" --body-file body.md
gh issue comment <번호> --body-file detail.md
```

본문과 코멘트 모두 파일로 넘긴다. 인라인 문자열은 여러 줄에서 깨진다.

## 제목

명사구로 쓰고, 같은 저장소의 다른 이슈와 구별되는 식별자를 남긴다. 종결어미와 문장부호를 넣지 않는다.

- 나쁜 예: `20000건 동시 insert 시 벡터 인덱스 서버가 죽는다`
- 좋은 예: `동시 Insert 시 Segfault (Crash 30) 발생`
## Install and Update

PowerShell (Windows):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/issue/install.ps1 | iex
```

Bash (macOS / Linux / WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/issue/install.sh | bash
```

Re-running the command fetches the latest version; install and update are the same command.