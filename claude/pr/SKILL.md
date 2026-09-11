---
name: pr
description: "PR 을 올린다. 본문은 - 불릿 3줄 요약과 이슈 참조 한 줄만 담고, 상세 설명은 PR 코멘트로 따로 올린다. 한국어 산문에는 sucks 스킬을 반드시 적용한다. 사용자가 /pr 을 호출하거나 PR 을 올리라고 지시할 때 사용한다."
metadata:
  author: hrlee
  version: "1.2.0"
  domain: workflow
  triggers: PR, pull request, PR 올려, PR 생성, gh pr create
  role: guardian
  scope: output
  output-format: action
---

# PR

전역 규칙, 프로젝트 규칙 중 관련된 것을 다시 명시적으로 읽고 작업할 것.

## 선행 조건

Skill 도구로 `sucks` 를 먼저 호출한다. 본문과 코멘트의 한국어 산문 전체에 그 규칙을 적용한다.

## 본문

`-` 불릿 세 줄만 쓴다. 각 줄은 변경 하나를 가리키는 한 문장이고, 제목은 넣지 않는다.

체크박스(`- [ ]`)를 쓰지 않는다. 본문은 머지될 변경을 서술하는 자리이지 진행 상태를 추적하는 자리가 아니다. 남은 작업은 코멘트에 쓴다.

```
- LightRAG 질의 경로에 BM25 인덱스를 붙여 키워드 검색을 처리한다
- 인덱스 빌드는 앱 시작 시점이 아니라 첫 질의 시점에 수행한다
- 기존 벡터 검색 결과와 RRF 로 병합한다
```

세 줄 뒤에 이슈 참조 줄을 붙이고, 그 뒤에 harness 가 요구하는 attribution 줄을 붙인다. 이 순서를 지킨다.

## 이슈 참조

대응되는 이슈가 있는지 PR 마다 확인한다. 확인을 건너뛰지 않는다. 브랜치 이름과 커밋 메시지에 남은 번호를 먼저 보고, 없으면 `gh issue list` 로 변경 내용과 맞는 이슈를 찾는다.

이슈를 찾았으면 본문 맨 뒤에 참조 한 줄을 넣는다. 어느 형태로 쓸지는 이 PR 이 머지된 뒤 이슈가 닫혀도 되는지로 가른다.

- `Closes #12` : 이 PR 이 이슈를 전부 해결한다. GitHub 가 머지 시점에 이슈를 자동으로 닫는다.
- `Refs #12` : 이슈의 일부만 해결하거나, 상위 트래킹 이슈이거나, 배경으로만 걸린다. 이슈는 열린 채로 남는다.

판단이 서지 않으면 이슈 본문의 완료 조건과 이 PR 의 변경 범위를 대조한다. 완료 조건이 하나라도 남으면 `Refs` 를 쓴다. 이슈 여러 건에 걸리면 줄을 나눠 각각 쓴다.

대응되는 이슈가 없으면 참조 줄을 넣지 않는다. 없는 번호를 지어내지 않는다.

```
- LightRAG 질의 경로에 BM25 인덱스를 붙여 키워드 검색을 처리한다
- 인덱스 빌드는 앱 시작 시점이 아니라 첫 질의 시점에 수행한다
- 기존 벡터 검색 결과와 RRF 로 병합한다

Closes #12
```

## 코멘트

배경, 설계 근거, 검증 방법, 남은 작업처럼 세 줄에 담기지 않는 내용은 전부 코멘트로 올린다. 본문에 넣지 않는다.

```bash
gh pr create --title "<제목>" --body-file body.md
gh pr comment <번호> --body-file detail.md
```

본문과 코멘트 모두 파일로 넘긴다. 인라인 문자열은 여러 줄에서 깨진다.

## 제목

명사구로 쓴다. 종결어미와 문장부호를 넣지 않는다.
## Install and Update

PowerShell (Windows):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/claude/pr/install.ps1 | iex
```

Bash (macOS / Linux / WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/claude/pr/install.sh | bash
```

Re-running the command fetches the latest version; install and update are the same command.