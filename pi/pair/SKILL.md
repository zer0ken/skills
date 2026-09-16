---
name: pair
description: "tmux 세션 안에서 드라이버 에이전트(pi/codex/claude 중 하나)와 어드바이저(선임급 모델)를 같은 윈도우에 수평 분할로 띄워 지속적 페어 하네스를 만든다. 어드바이저 모델은 GPT-6 Astra(low, codex)와 Claude Fable 5.1(low, claude) 중 주간 잔여 사용량이 더 많은 쪽을 선택한다. 계획·조언, 커밋 방향 검토, 완료 검토를 맡는다. tmux 밖에서는 동작하지 않는다. 사용자가 /pair 를 호출하거나, 페어, 클로드 페어, claude pair, 코드엑스 페어, codex pair, 검토 요청, 완료 검토, 커밋 리뷰, 어드바이저를 요청할 때 사용한다."
metadata:
  author: hrlee
  version: "1.5.0"
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
# 감시기 절의 스크립트를 <REPO>, <ADVISOR_PANE>, <DRIVER_PANE>, <PAIR_SEND> 를 채워 WATCHER_FILE 로 쓴다.
# 초기 메시지 절의 템플릿을 값으로 채워 INIT 로 쓴다. <PAIR_SEND> 는 메시지 전송 절에서 찾은 경로다.
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
  bash <PAIR_SEND> <DRIVER_PANE> /tmp/pair-reply.md
- 이 명령이 0 이 아닌 코드로 끝나면 메시지가 도착하지 않은 것이다. 같은 파일로 한 번 더 실행하고, 그래도 실패하면 pane 상태를 확인한다.
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

속도
- 이 스킬의 "속도 방침" 절을 읽고 드라이버 규칙을 첫 응답에 넣어 보내며, 어드바이저 규칙대로 goal 갱신과 정지 감시를 한다.

유지
- 페어가 끝나도 이 세션과 감시기를 종료하지 않는다. 실행 상태로 유지한다.
```

## 메시지 전송

어드바이저에게 메시지를 보낼 때. 이 스킬 디렉토리의 `pair-send.sh` 를 쓴다. 붙여넣기와 Enter 를 각각 확인하고, 제출이 안 되면 Enter 를 다른 인코딩으로 다시 눌러 본다.

```bash
PAIR_SEND=""
for cand in ~/.agents/skills/pair/pair-send.sh ~/.pi/agent/skills/pair/pair-send.sh; do
  [ -f "$cand" ] && PAIR_SEND="$cand" && break
done

MSG="${TMPDIR:-/tmp}/pair-$(id -u)/msg-$(date +%s).md"
cat > "$MSG" <<'EOF'
<보낼 메시지>
EOF
bash "$PAIR_SEND" "$ADVISOR_PANE" "$MSG"
```

종료 코드는 3이면 pane 이 없는 것이고, 4면 붙여넣기가 입력창에 도달하지 못한 것이고, 5면 메시지가 입력창에 남아 제출되지 않은 것이다. 0이 아니면 전송된 것으로 간주하지 말고 사용자에게 알린다.

붙여넣기와 Enter 는 별개의 tmux 명령이라, 붙여넣기가 상대 TUI 의 편집기에 반영되기 전에 Enter 가 도착하면 그 Enter 가 붙여넣은 덩어리 안쪽으로 들어가 개행이 되고 메시지는 프롬프트에 그대로 남는다. `pair-send.sh` 는 입력창 상태를 직접 확인해 이 경합을 닫는다. 상대 TUI 가 bracketed paste 를 지원하지 않아 `200~` 마커가 그대로 보이면 `tmux send-keys -t <pane> -l "<내용>"` 으로 대체한다.

## 속도 방침

페어의 목적은 검토만이 아니라 드라이버가 빠르게 끝내게 하는 것이다. 어드바이저는 아래 방침을 초기 메시지와 goal 에 넣고, 어긋나면 바로 개입한다.

### 드라이버 규칙

| 규칙 | 이유 |
| --- | --- |
| import 가 되는 지점마다 20분 안에 커밋하고 바로 push 한다. 완벽한 마감을 기다리지 않는다 | 압축이나 중단으로 미커밋 변경이 사라지는 것을 막고, 어드바이저가 검토를 시작할 수 있다 |
| 중간 검증은 import 스모크, lint-imports, `-k` 로 좁힌 시험만 한다. 단위 전체와 통합 전체는 어드바이저가 돌린다 | 10분짜리 전체 시험을 작업 중간에 돌리면 그 시간 동안 드라이버가 멈춘다 |
| 하위 에이전트는 목표 상태(파일, 줄, 해야 할 동작)가 전부 적힌 일에만, 별도 워크트리 하나에 하나만 쓴다. 하위 에이전트는 git 명령을 하지 않는다 | 위임 지시 작성과 결과 재확인이 직접 편집보다 오래 걸리고, 같은 워크트리의 하위 에이전트 둘은 서로 파일을 덮어쓴다 |
| 커밋 메시지를 열 수 있는 git 명령(rebase --continue, merge, cherry-pick, commit --amend)에는 `-c core.editor=true` 를 붙인다 | 편집기가 tty 없이 열려 도구 호출이 수 분 동안 멈춘다 |
| 시험이 setup 에서 실패하면 같은 명령을 다시 치지 않고 setup 로그를 먼저 읽는다 | 같은 명령의 세 번 반복은 원인을 읽지 않았다는 뜻이다 |
| 탐색용 cat, grep, sed 는 한 호출에 묶는다 | 호출 하나가 한 턴이라 열 번 나눠 치면 열 턴이 든다 |
| 보고는 커밋마다 한 줄이다. 어드바이저의 검토는 반영하되 기다리지 않는다 | 검토 대기가 작업 사이의 빈 시간을 만든다 |

### 어드바이저 규칙

| 규칙 | 이유 |
| --- | --- |
| 검토는 "조건부 통과" 로 낸다. 고칠 항목을 번호로 적고 다음 커밋에 넣게 하며, 드라이버를 세우지 않는다 | 막는 검토는 드라이버를 기다리게 하고, 항목 목록은 다음 커밋으로 흡수된다 |
| 드라이버가 탐색할 것을 어드바이저가 먼저 찾아 파일과 줄 번호로 넘긴다. 이미 있는 구현이 있으면 그 위치를 알린다 | 어드바이저가 한 번 읽는 것이 드라이버가 열 턴 탐색하는 것보다 빠르다 |
| 단계가 끝날 때마다 드라이버의 goal 을 갱신한다(pi 는 `/goal <새 목표>` 를 pane 에 입력하고 바꾸기 확인). 끝난 것, 남은 순서, 완료 기준, 작업 규칙을 담는다 | 낡은 goal 은 드라이버를 지난 단계의 기준으로 되돌린다 |
| 정지 신호를 감시하고 바로 개입한다. 같은 화면이 5분 넘게 그대로인 것, 편집기 프로세스(`ps -eo pid,etimes,args \| grep editor`), 상태줄의 `Goal paused`, 같은 명령의 세 번 반복이 신호다 | 드라이버는 스스로 멈춘 것을 알리지 않는다 |
| 독립된 이슈는 각각 워크트리와 브랜치를 따서 병렬로 진행시킨다. 커밋과 push 는 드라이버가 한다 | 파일이 겹치지 않는 일은 동시에 끝난다 |
| 커밋마다 어드바이저가 직접 확인하는 것: push 여부, 커밋 메시지의 금지 문자와 AI 흔적, import, lint, 옛 이름 잔존. 전체 시험은 어드바이저가 분리 프로세스(`setsid nohup`)로 돌리고 결과를 한 줄로 알린다 | 드라이버의 "통과" 보고와 실제 결과가 다른 일이 잦다 |

## 조언 요청

사용자가 어드바이저에게 조언·계획·검토를 요청하면, 현재 작업 맥락을 요약해 어드바이저 pane 으로 보낸다. 재분할하지 않는다.

## 완료 검토

사용자가 작업 완료를 알리면 어드바이저에게 완료 검토를 요청한다. 완료 판단 근거와 작업 요약을 담고, 전역 규칙·프로젝트 규칙·sucks 문체·osiri 검증 기준으로 검토해 재작업 지시 또는 완료 확인을 요청한다. 어드바이저의 응답이 도착하면 사용자에게 전달하고, 재작업 지시가 있으면 그대로 이어서 작업한다.

## 유지

페어가 끝나도 어드바이저와 감시기를 종료하지 않는다. 드라이버, 어드바이저, 감시기 모두 실행 상태로 유지한다.

## 감시기

아래 스크립트를 `<REPO>`, `<ADVISOR_PANE>`, `<DRIVER_PANE>`, `<PAIR_SEND>` 을 채워 임시 파일로 만들고 실행 가능하게 만든다. 어드바이저가 이 파일을 백그라운드로 실행해 모니터링을 생성한다. 감시기는 어드바이저가 종료되어도 돌아가므로, 어드바이저를 다시 띄울 때는 감시기를 내리고 새 어드바이저의 pane id 로 다시 올린다.

```bash
#!/usr/bin/env bash
# 드라이버 세션의 새 커밋을 감지해 어드바이저 pane 으로 알린다
set -u
REPO="<REPO>"
ADVISOR_PANE="<ADVISOR_PANE>"
DRIVER_PANE="<DRIVER_PANE>"
PAIR_SEND="<PAIR_SEND>"
INTERVAL=10
norm() { case "$1" in %*) printf '%s' "$1" ;; *) printf '%%%s' "$1" ;; esac; }
ADVISOR_PANE=$(norm "$ADVISOR_PANE")
DRIVER_PANE=$(norm "$DRIVER_PANE")
git -C "$REPO" rev-parse HEAD >/dev/null 2>&1 || { echo "not a git repo: $REPO"; exit 1; }
last=$(git -C "$REPO" rev-parse HEAD)
while true; do
  sleep "$INTERVAL"
  # 감시 대상 pane 이 사라지면 종료한다. 남겨두면 없는 pane 으로 계속 전송을 시도한다.
  [ -z "$(tmux display-message -p -t "$ADVISOR_PANE" '#{pane_id}' 2>/dev/null)" ] && exit 0
  head=$(git -C "$REPO" rev-parse HEAD 2>/dev/null) || continue
  [ "$head" = "$last" ] && continue
  log=$(git -C "$REPO" log --oneline --no-merges "$last..$head" 2>/dev/null) || log=""
  if [ -n "$log" ]; then
    msg=$(mktemp)
    printf '[pair] 드라이버 세션의 새 커밋이 감지되었다.\n%s\n방향이 작업과 맞는지 검토하고 의견을 드라이버 pane %s 로 보내라.\n' "$log" "$DRIVER_PANE" > "$msg"
    bash "$PAIR_SEND" "$ADVISOR_PANE" "$msg" || echo "watcher: send failed for $head"
    rm -f "$msg"
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

`pair-select-advisor.sh` 와 `pair-send.sh` 는 이 스킬 디렉토리에 함께 배치된다. 원격 저장소로 배포할 때는 SKILL.md 와 함께 세 파일을 올려야 한다.
