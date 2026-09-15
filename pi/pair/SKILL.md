---
name: pair
description: "tmux 세션 안에서 claude(fable 5.1, effort low, permission bypass)를 현재 윈도우에 수평 분할로 띄워 pi 작업의 페어 어드바이저로 붙인다. 작업 상세를 넘겨 계획·조언을 받고, pi가 만든 커밋을 감시해 방향을 검토받고, 완료 시 /sucks·/osiri·프로젝트/전역 규칙 기준으로 완료를 검토받는다. tmux 밖에서는 동작하지 않는다. 사용자가 /pair 를 호출하거나, 클로드 페어, claude 에게 검토, 작업 완료 검토를 요청할 때 사용한다."
metadata:
  author: hrlee
  version: "1.2.0"
  domain: workflow
  triggers: pair, 페어, 클로드 페어, claude pair, 검토 요청, 완료 검토, 커밋 리뷰, 어드바이저
  role: guardian
  scope: output
  output-format: action
---

# Pair

pi 가 드라이버, claude 가 어드바이저로 붙는 지속적 페어 하네스다. claude 는 같은 tmux 윈도우의 옆 pane 에서 실행되며 계획·조언, 커밋 방향 검토, 완료 검토를 맡는다. 페어가 끝나도 claude 와 감시기는 종료하지 않고 실행 상태로 유지한다.

전역 규칙, 프로젝트 규칙 중 관련된 것을 다시 명시적으로 읽고 작업할 것.

## 선행 조건

tmux 세션 안에서만 동작한다. `$TMUX` 가 비어 있으면 중단하고 "tmux 세션 안에서만 사용할 수 있다"고 사용자에게 알린다.

아래 값을 확보한다.

| 값 | 확보 방법 |
| --- | --- |
| PI_PANE | `tmux display-message -p -F '#{pane_id}'` |
| WINDOW_ID | `tmux display-message -p -F '#{window_id}'` |
| SESSION_ID | `tmux display-message -p -F '#{session_id}'` |
| REPO | `git rev-parse --show-toplevel` |

tmux 명령은 항상 `-t` 로 대상을 명시한다. 대상 없이 두면 현재 세션의 현재 윈도우가 아니라 엉뚱한 세션을 가리킬 수 있다.

## 상태 파일

페어 상태를 `${TMPDIR:-/tmp}/pair-$(id -u)/state/<SESSION_ID>_<WINDOW_ID>.json` 에 기록한다. 존재하면 재사용 판단에 쓴다.

```json
{ "pi_pane": "%25", "claude_pane": "%42", "repo": "/path/to/repo" }
```

## 최초 기동

1. 작업 요약(TASK)을 정리한다. 사용자가 /pair 뒤에 준 말이 있으면 그것을 우선으로, 없으면 현재 대화에서 pi 가 진행 중인 작업을 한두 문단으로 요약한다.
2. 상태 파일의 claude_pane 이 살아 있으면 재사용한다. pane 존재 확인은 `tmux display-message -p -t <pane> '#{pane_id}'` 결과가 비어 있지 않은지로 판단한다. 살아 있으면 [메시지 전송]만 하고 끝낸다.
3. 없으면 감시기 스크립트를 먼저 만들고, 초기 메시지를 임시 파일로 쓴 뒤, claude 를 수평 분할로 띄운다. 초기 메시지를 claude 의 첫 프롬프트로 넘긴다.

```bash
D="${TMPDIR:-/tmp}/pair-$(id -u)"
mkdir -p "$D/state"
WATCHER_FILE="$D/watcher-$CLAUDE_PANE.sh"
WATCHER_LOG="$D/watcher-$CLAUDE_PANE.log"
INIT="$D/init-$(date +%s).md"
# 감시기 절의 스크립트를 <REPO>, <CLAUDE_PANE>, <PI_PANE> 을 채워 WATCHER_FILE 로 쓴다.
# 초기 메시지 절의 템플릿을 값으로 채워 INIT 로 쓴다.
CLAUDE_PANE=$(tmux split-window -t "$PI_PANE" -h -P -F '#{pane_id}' -c "$REPO" "claude --model claude-fable-5-1 --effort low --permission-mode bypassPermissions \"\$(cat '$INIT')\"")
```

4. 상태 파일을 쓴다.
5. 초기 메시지에는 claude 가 `WATCHER_FILE` 을 백그라운드로 실행해 모니터링을 만들도록 지시한다.

## 초기 메시지

아래를 실제 값으로 채워 초기 메시지로 보낸다.

```
너는 tmux pane <PI_PANE> 의 pi 세션이 진행하는 작업의 페어 어드바이저다.

작업 저장소: <REPO>
작업 내용:
<TASK>

역할
- pi 의 작업에 대해 계획과 조언을 준다.
- pi 가 만든 커밋의 방향을 검토하고 의견을 준다.
- pi 가 완료를 알리면 아래 기준으로 완료 여부를 검토한다.

응답 프로토콜
- pi 세션에 답할 때는 답변을 /tmp/pair-reply.md 로 쓰고 아래 명령을 실행한다. 메시지는 명확하고 간결하게, 줄 첫머리에 슬래시(/)를 쓰지 않는다.
  tmux load-buffer -b pairreply - < /tmp/pair-reply.md
  tmux paste-buffer -b pairreply -t <PI_PANE> -p
  tmux send-keys -t <PI_PANE> Enter
- 첫 응답(작업에 대한 계획과 조언)을 완성한 뒤에도 위 방식으로 pi pane 에 보낸다.

커밋 감시 생성
- pi 세션의 새 커밋을 감지하는 감시기를 백그라운드로 만들어 실행한다.
  nohup bash <WATCHER_FILE> > <WATCHER_LOG> 2>&1 &
- 감시기가 이 pane 으로 새 커밋을 알리면 git show, git diff 로 작업 방향과 맞는지 검토하고 의견을 pi pane 으로 보낸다.

완료 검토
- pi 가 작업 완료를 알리면 아래 기준으로 검토한다.
  - /sucks : 한국어 기술 문서 문체
  - /osiri : 주장·수치·근거의 검증
  - 프로젝트 로컬 규칙 (저장소의 AGENTS.md 등)
  - 전역 규칙
- 기준에 어긋나거나 남은 작업이 있으면 구체적인 재작업을 지시하고, 충분하면 완료를 확인한다. 결과를 pi pane 으로 보낸다.

유지
- 페어가 끝나도 이 세션과 감시기를 종료하지 않는다. 실행 상태로 유지한다.
```

## 메시지 전송

claude 에게 메시지를 보낼 때. 대상 pane 에 bracketed paste 로 넣고 Enter 로 제출한다. claude 의 답변도 같은 방식으로 pi pane 에 도착한다. 상대 TUI 가 bracketed paste 를 지원하지 않아 `200~` 마커가 그대로 보이면 `tmux send-keys -t <pane> -l "<내용>"` 으로 대체한다.

```bash
MSG="${TMPDIR:-/tmp}/pair-$(id -u)/msg-$(date +%s).md"
cat > "$MSG" <<'EOF'
<보낼 메시지>
EOF
tmux load-buffer -b pairmsg - < "$MSG"
tmux paste-buffer -b pairmsg -t "$CLAUDE_PANE" -p
tmux send-keys -t "$CLAUDE_PANE" Enter
```

## 조언 요청

사용자가 claude 에게 조언·계획·검토를 요청하면, 현재 작업 맥락을 요약해 claude pane 으로 보낸다. 재분할하지 않는다.

## 완료 검토

사용자가 작업 완료를 알리면 claude 에게 완료 검토를 요청한다. 완료 판단 근거와 작업 요약을 담고, /sucks·/osiri·프로젝트/전역 규칙 기준으로 검토해 재작업 지시 또는 완료 확인을 요청한다. claude 의 응답이 도착하면 사용자에게 전달하고, 재작업 지시가 있으면 그대로 이어서 작업한다.

## 유지

페어가 끝나도 claude 와 감시기를 종료하지 않는다. pi, claude, 감시기 모두 실행 상태로 유지한다.

## 감시기

아래 스크립트를 `<REPO>`, `<CLAUDE_PANE>`, `<PI_PANE>` 을 채워 임시 파일로 만들고 실행 가능하게 만든다. claude 가 이 파일을 백그라운드로 실행해 모니터링을 생성한다. 감시기는 claude 가 종료되어도 돌아가므로, claude 를 다시 띄울 때는 감시기를 내리고 새 claude 의 pane id 로 다시 올린다.

```bash
#!/usr/bin/env bash
# pi 세션의 새 커밋을 감지해 claude 어드바이저 pane 으로 알린다
set -u
REPO="<REPO>"
CLAUDE_PANE="<CLAUDE_PANE>"
PI_PANE="<PI_PANE>"
INTERVAL=10
norm() { case "$1" in %*) printf '%s' "$1" ;; *) printf '%%%s' "$1" ;; esac; }
CLAUDE_PANE=$(norm "$CLAUDE_PANE")
PI_PANE=$(norm "$PI_PANE")
git -C "$REPO" rev-parse HEAD >/dev/null 2>&1 || { echo "not a git repo: $REPO"; exit 1; }
last=$(git -C "$REPO" rev-parse HEAD)
while true; do
  sleep "$INTERVAL"
  head=$(git -C "$REPO" rev-parse HEAD 2>/dev/null) || continue
  [ "$head" = "$last" ] && continue
  log=$(git -C "$REPO" log --oneline --no-merges "$last..$head" 2>/dev/null) || log=""
  if [ -n "$log" ]; then
    msg=$(printf '[pair] pi 세션의 새 커밋이 감지되었다.\n%s\n방향이 작업과 맞는지 검토하고 의견을 pi pane %s 로 보내라.\n' "$log" "$PI_PANE")
    printf '%s' "$msg" | tmux load-buffer -b pairwatch -
    tmux paste-buffer -b pairwatch -t "$CLAUDE_PANE" -p
    tmux send-keys -t "$CLAUDE_PANE" Enter
  fi
  last="$head"
done
```

## Install and Update

PowerShell (Windows):

```powershell
irm https://raw.githubusercontent.com/zer0ken/skills/main/pi/pair/install.ps1 | iex
```

Bash (macOS / Linux / WSL):

```bash
curl -fsSL https://raw.githubusercontent.com/zer0ken/skills/main/pi/pair/install.sh | bash
```

Re-running the command fetches the latest version; install and update are the same command.
