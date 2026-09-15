---
name: pair
description: "tmux 세션 안에서 드라이버 에이전트(pi/codex/claude 중 하나)와 어드바이저(선임급 모델)를 같은 윈도우에 수평 분할로 띄워 지속적 페어 하네스를 만든다. 어드바이저 모델은 GPT-6 Astra(low, codex)와 Claude Fable 5.1(low, claude) 중 주간 잔여 사용량이 더 많은 쪽을 선택한다. 계획·조언, 커밋 방향 검토, 완료 검토를 맡는다. tmux 밖에서는 동작하지 않는다. 사용자가 /pair 를 호출하거나, 페어, 클로드 페어, claude pair, 코드엑스 페어, codex pair, 검토 요청, 완료 검토, 커밋 리뷰, 어드바이저를 요청할 때 사용한다."
metadata:
  author: hrlee
  version: "1.3.0"
  domain: workflow
  triggers: pair, 페어, 클로드 페어, claude pair, 코드엑스 페어, codex pair, 검토 요청, 완료 검토, 커밋 리뷰, 어드바이저
  role: guardian
  scope: output
  output-format: action
---

# Pair

드라이버 에이전트(pi/codex/claude 중 하나)와 어드바이저(astra 또는 fable 중 잔여 사용량이 많은 쪽)가 붙는 지속적 페어 하네스다. 어드바이저는 같은 tmux 윈도우의 옆 pane 에서 실행되며 계획·조언, 커밋 방향 검토, 완료 검토를 맡는다. 페어가 끝나도 어드바이저와 감시기는 종료하지 않고 실행 상태로 유지한다.

전역 규칙, 프로젝트 규칙 중 관련된 것을 다시 명시적으로 읽고 작업할 것.

## 선행 조건

tmux 세션 안에서만 동작한다. `$TMUX` 가 비어 있으면 중단하고 "tmux 세션 안에서만 사용할 수 있다"고 사용자에게 알린다.

아래 값을 확보한다.

| 값 | 확보 방법 |
| --- | --- |
| DRIVER_PANE | `tmux display-message -p -F '#{pane_id}'` |
| WINDOW_ID | `tmux display-message -p -F '#{window_id}'` |
| SESSION_ID | `tmux display-message -p -F '#{session_id}'` |
| REPO | `git rev-parse --show-toplevel` |
| DRIVER | 아래 드라이버 감지 절 |

tmux 명령은 항상 `-t` 로 대상을 명시한다. 대상 없이 두면 현재 세션의 현재 윈도우가 아니라 엉뚱한 세션을 가리킬 수 있다.

## 드라이버 감지

주 에이전트가 무엇인지 판별한다. 메시지 라벨과 상태 파일에만 쓰이며, 핵심 동작(메시지 전송, 커밋 감시)은 드라이버 종류와 무관하게 동일하다. 판별하지 못하면 `driver` 로 표시하고 그대로 진행한다.

```bash
detect_driver() {
  if [ -n "${PI_SESSION_ID:-}" ] || [ -n "${PI_CODING_AGENT:-}" ]; then echo "pi"; return; fi
  local p=$$ exe
  while [ -n "$p" ] && [ "$p" != "1" ]; do
    exe=$(readlink "/proc/$p/exe" 2>/dev/null)
    case "$exe" in
      *codex*) echo "codex"; return ;;
      *claude*) echo "claude"; return ;;
    esac
    p=$(ps -o ppid= -p "$p" 2>/dev/null | tr -d ' ')
  done
  echo "driver"
}
DRIVER=$(detect_driver)
```

## 어드바이저 모델 선택

어드바이저는 선임급 모델 중 주간 잔여 사용량이 더 많은 쪽으로 정한다. 이 스킬 디렉토리의 `pair-select-advisor.sh` 를 실행하면 `astra` 또는 `fable` 을 stdout 으로 출력한다.

- astra: GPT-6 Astra, low reasoning effort. codex 로 실행한다.
- fable: Claude Fable 5.1, low effort. claude 로 실행한다.

스크립트가 없거나 실패하면 기본값 `fable` 로 진행한다. 사용자가 특정 모델을 요구하거나 `PAIR_ADVISOR=astra|fable` 이 설정되어 있으면 그 모델로 고정한다.

```bash
# 이 스킬 디렉토리를 찾는다. 보통 ~/.agents/skills/pair 이다.
ADVISOR_SCRIPT=""
for cand in ~/.agents/skills/pair/pair-select-advisor.sh ~/.pi/agent/skills/pair/pair-select-advisor.sh; do
  [ -f "$cand" ] && ADVISOR_SCRIPT="$cand" && break
done
if [ -n "$ADVISOR_SCRIPT" ]; then
  ADVISOR=$(bash "$ADVISOR_SCRIPT" 2>/dev/null)
fi
case "$ADVISOR" in
  astra) ADVISOR_CMD="codex -m gpt-6-astra -c model_reasoning_effort=low" ;;
  *)     ADVISOR="fable"; ADVISOR_CMD="claude --model claude-fable-5-1 --effort low --permission-mode bypassPermissions" ;;
esac
```

선택 스크립트는 두 제공자의 주간 사용량을 비교한다.

- codex(astra): `~/.codex/auth.json` 의 토큰으로 `chatgpt.com/backend-api/wham/usage` 를 호출해 `rate_limit.primary_window.used_percent` 로부터 잔여량을 구한다. `gpt-6-astra` 가 특정 모델 사용 한도로 사용 불가면 astra 는 후보에서 제외한다.
- claude(fable): claude 를 분리 tmux 세션에서 띄워 `/usage` 를 실행하고 `Current week (all models)` 의 사용률로부터 잔여량을 구한다. 결과는 10분간 캐시한다. 공식 API 가 없어서 이 방식이 유일한 헤드리스 수단이며, claude 시작 시간만큼(~10~30초) 걸린다.

## 신뢰 사전 등록

어드바이저(클로드/코덱스)가 새 디렉토리에서 trust 대화상자로 멈추지 않도록, REPO 를 두 CLI 의 신뢰 목록에 등록한다. 이미 등록돼 있으면 쓰지 않는다. 최초 기동에서 어드바이저를 띄우기 전에 `trust_repo` 를 실행한다.

```bash
trust_repo() {
  # claude: ~/.claude.json 의 projects[REPO].hasTrustDialogAccepted
  if [ -f "$HOME/.claude.json" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$HOME/.claude.json" "$REPO" <<'PY'
import json, sys
p, repo = sys.argv[1], sys.argv[2]
d = json.load(open(p))
proj = d.setdefault("projects", {})
e = proj.setdefault(repo, {})
if not e.get("hasTrustDialogAccepted"):
    e["hasTrustDialogAccepted"] = True
    json.dump(d, open(p, "w"), indent=2)
PY
  fi
  # codex: ~/.codex/config.toml 의 [projects."REPO"] trust_level = "trusted"
  CFG="$HOME/.codex/config.toml"
  if [ -f "$CFG" ] && command -v python3 >/dev/null 2>&1; then
    python3 - "$CFG" "$REPO" <<'PY'
import sys
cfg, repo = sys.argv[1], sys.argv[2]
s = open(cfg).read()
key = '[projects."%s"]' % repo
if key not in s:
    open(cfg, "a").write('\n%s\ntrust_level = "trusted"\n' % key)
PY
  fi
}
```

## 상태 파일

페어 상태를 `${TMPDIR:-/tmp}/pair-$(id -u)/state/<SESSION_ID>_<WINDOW_ID>.json` 에 기록한다. 존재하면 재사용 판단에 쓴다. 이전 버전의 `pi_pane`/`claude_pane` 키가 있으면 각각 `driver_pane`/`advisor_pane` 으로 읽는다.

```json
{ "driver": "pi", "driver_pane": "%25", "advisor": "fable", "advisor_pane": "%42", "repo": "/path/to/repo" }
```

## 최초 기동

1. 작업 요약(TASK)을 정리한다. 사용자가 /pair 뒤에 준 말이 있으면 그것을 우선으로, 없으면 현재 대화에서 드라이버가 진행 중인 작업을 한두 문단으로 요약한다.
2. 상태 파일의 advisor_pane 이 살아 있으면 재사용한다. pane 존재 확인은 `tmux display-message -p -t <pane> '#{pane_id}'` 결과가 비어 있지 않은지로 판단한다. 살아 있으면 [메시지 전송]만 하고 끝낸다.
3. 어드바이저 모델을 선택한다.
4. REPO 를 두 CLI 의 신뢰 목록에 등록한다 (`trust_repo`).
5. 없으면 감시기 스크립트를 먼저 만들고, 초기 메시지를 임시 파일로 쓴 뒤, 어드바이저를 수평 분할로 띄운다. 초기 메시지를 어드바이저의 첫 프롬프트로 넘긴다.

```bash
D="${TMPDIR:-/tmp}/pair-$(id -u)"
mkdir -p "$D/state"
WATCHER_FILE="$D/watcher-$WINDOW_ID.sh"
WATCHER_LOG="$D/watcher-$WINDOW_ID.log"
INIT="$D/init-$(date +%s).md"
# 감시기 절의 스크립트를 <REPO>, <ADVISOR_PANE>, <DRIVER_PANE> 을 채워 WATCHER_FILE 로 쓴다.
# 초기 메시지 절의 템플릿을 값으로 채워 INIT 로 쓴다.
ADVISOR_PANE=$(tmux split-window -t "$DRIVER_PANE" -h -P -F '#{pane_id}' -c "$REPO" "$ADVISOR_CMD \"\$(cat '$INIT')\"")
```

5. 상태 파일을 쓴다.
6. 초기 메시지에는 어드바이저가 `WATCHER_FILE` 을 백그라운드로 실행해 모니터링을 만들도록 지시한다.

## 초기 메시지

아래를 실제 값으로 채워 초기 메시지로 보낸다.

```
너는 tmux pane <DRIVER_PANE> 의 드라이버 에이전트(<DRIVER>) 세션이 진행하는 작업의 페어 어드바이저다.

작업 저장소: <REPO>
작업 내용:
<TASK>

역할
- 드라이버 에이전트의 작업에 대해 계획과 조언을 준다.
- 드라이버가 만든 커밋의 방향을 검토하고 의견을 준다.
- 드라이버가 완료를 알리면 아래 기준으로 완료 여부를 검토한다.

응답 프로토콜
- 드라이버 세션에 답할 때는 답변을 /tmp/pair-reply.md 로 쓰고 아래 명령을 실행한다. 메시지는 명확하고 간결하게, 줄 첫머리에 슬래시(/)를 쓰지 않는다.
  tmux load-buffer -b pairreply - < /tmp/pair-reply.md
  tmux paste-buffer -b pairreply -t <DRIVER_PANE> -p
  tmux send-keys -t <DRIVER_PANE> Enter
- 첫 응답(작업에 대한 계획과 조언)을 완성한 뒤에도 위 방식으로 드라이버 pane 에 보낸다.

커밋 감시 생성
- 드라이버 세션의 새 커밋을 감지하는 감시기를 백그라운드로 만들어 실행한다.
  nohup bash <WATCHER_FILE> > <WATCHER_LOG> 2>&1 &
- 감시기가 이 pane 으로 새 커밋을 알리면 git show, git diff 로 작업 방향과 맞는지 검토하고 의견을 드라이버 pane 으로 보낸다.

완료 검토
- 드라이버가 작업 완료를 알리면 아래 기준으로 검토한다.
  - 사용자 전역 규칙(AGENTS.md 등 시스템 지시). 한국어 문체는 sucks 스킬 원칙, 주장·수치 검증은 osiri 원칙을 따른다. 가능하면 ~/.agents/skills/sucks/SKILL.md 와 ~/.agents/skills/osiri/SKILL.md 를 읽어 기준으로 삼는다.
  - 프로젝트 로컬 규칙 (저장소의 AGENTS.md, CLAUDE.md 등)
- 기준에 어긋나거나 남은 작업이 있으면 구체적인 재작업을 지시하고, 충분하면 완료를 확인한다. 결과를 드라이버 pane 으로 보낸다.

유지
- 페어가 끝나도 이 세션과 감시기를 종료하지 않는다. 실행 상태로 유지한다.
```

## 메시지 전송

어드바이저에게 메시지를 보낼 때. 대상 pane 에 bracketed paste 로 넣고 Enter 로 제출한다. 어드바이저의 답변도 같은 방식으로 드라이버 pane 에 도착한다. 상대 TUI 가 bracketed paste 를 지원하지 않아 `200~` 마커가 그대로 보이면 `tmux send-keys -t <pane> -l "<내용>"` 으로 대체한다.

```bash
MSG="${TMPDIR:-/tmp}/pair-$(id -u)/msg-$(date +%s).md"
cat > "$MSG" <<'EOF'
<보낼 메시지>
EOF
tmux load-buffer -b pairmsg - < "$MSG"
tmux paste-buffer -b pairmsg -t "$ADVISOR_PANE" -p
tmux send-keys -t "$ADVISOR_PANE" Enter
```

## 조언 요청

사용자가 어드바이저에게 조언·계획·검토를 요청하면, 현재 작업 맥락을 요약해 어드바이저 pane 으로 보낸다. 재분할하지 않는다.

## 완료 검토

사용자가 작업 완료를 알리면 어드바이저에게 완료 검토를 요청한다. 완료 판단 근거와 작업 요약을 담고, 전역 규칙·프로젝트 규칙·sucks 문체·osiri 검증 기준으로 검토해 재작업 지시 또는 완료 확인을 요청한다. 어드바이저의 응답이 도착하면 사용자에게 전달하고, 재작업 지시가 있으면 그대로 이어서 작업한다.

## 유지

페어가 끝나도 어드바이저와 감시기를 종료하지 않는다. 드라이버, 어드바이저, 감시기 모두 실행 상태로 유지한다.

## 감시기

아래 스크립트를 `<REPO>`, `<ADVISOR_PANE>`, `<DRIVER_PANE>` 을 채워 임시 파일로 만들고 실행 가능하게 만든다. 어드바이저가 이 파일을 백그라운드로 실행해 모니터링을 생성한다. 감시기는 어드바이저가 종료되어도 돌아가므로, 어드바이저를 다시 띄울 때는 감시기를 내리고 새 어드바이저의 pane id 로 다시 올린다.

```bash
#!/usr/bin/env bash
# 드라이버 세션의 새 커밋을 감지해 어드바이저 pane 으로 알린다
set -u
REPO="<REPO>"
ADVISOR_PANE="<ADVISOR_PANE>"
DRIVER_PANE="<DRIVER_PANE>"
INTERVAL=10
norm() { case "$1" in %*) printf '%s' "$1" ;; *) printf '%%%s' "$1" ;; esac; }
ADVISOR_PANE=$(norm "$ADVISOR_PANE")
DRIVER_PANE=$(norm "$DRIVER_PANE")
git -C "$REPO" rev-parse HEAD >/dev/null 2>&1 || { echo "not a git repo: $REPO"; exit 1; }
last=$(git -C "$REPO" rev-parse HEAD)
while true; do
  sleep "$INTERVAL"
  head=$(git -C "$REPO" rev-parse HEAD 2>/dev/null) || continue
  [ "$head" = "$last" ] && continue
  log=$(git -C "$REPO" log --oneline --no-merges "$last..$head" 2>/dev/null) || log=""
  if [ -n "$log" ]; then
    msg=$(printf '[pair] 드라이버 세션의 새 커밋이 감지되었다.\n%s\n방향이 작업과 맞는지 검토하고 의견을 드라이버 pane %s 로 보내라.\n' "$log" "$DRIVER_PANE")
    printf '%s' "$msg" | tmux load-buffer -b pairwatch -
    tmux paste-buffer -b pairwatch -t "$ADVISOR_PANE" -p
    tmux send-keys -t "$ADVISOR_PANE" Enter
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

`pair-select-advisor.sh` 는 이 스킬 디렉토리에 함께 배치된다. 원격 저장소로 배포할 때는 SKILL.md 와 함께 두 파일을 함께 올려야 한다.
