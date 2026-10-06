---
name: pair
description: "tmux 세션 안에서 드라이버 에이전트(pi/codex/claude 중 하나)와 어드바이저(선임급 모델)를 같은 윈도우에 수평 분할로 띄워 지속적 페어 하네스를 만든다. 어드바이저 모델은 GPT-6 Astra(low, codex)와 Claude Fable 5.1(low, claude) 중 주간 잔여 사용량이 더 많은 쪽을 선택한다. 계획·조언, 커밋 방향 검토, 완료 검토를 맡는다. tmux 밖에서는 동작하지 않는다. 사용자가 /pair 를 호출하거나, 페어, 클로드 페어, claude pair, 코드엑스 페어, codex pair, 검토 요청, 완료 검토, 커밋 리뷰, 어드바이저를 요청할 때 사용한다."
metadata:
  author: hrlee
  version: "1.7.0"
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

페어 기록은 `pair-state.sh` 로만 읽고 쓴다. 키는 드라이버 pane id 다. pane id 는 재사용되지 않고 pane 을 다른 윈도우로 옮겨도 그대로라, (세션, 윈도우) 키와 달리 어긋나지 않는다.

```bash
PAIR_STATE=""
for cand in ~/.agents/skills/pair/pair-state.sh ~/.pi/agent/skills/pair/pair-state.sh; do
  [ -f "$cand" ] && PAIR_STATE="$cand" && break
done

bash "$PAIR_STATE" write "$DRIVER_PANE" "$ADVISOR_PANE" "$DRIVER" "$ADVISOR" "$REPO"
bash "$PAIR_STATE" show "$DRIVER_PANE"          # 이 pane 이 속한 기록
bash "$PAIR_STATE" counterpart "$DRIVER_PANE"   # 상대 pane id
```

기록에는 양쪽 pane id 와 그 시점의 pane pid 가 들어간다. pid 는 pane 이 그대로 있는데 그 안의 프로세스만 갈린 경우를 잡는 데 쓴다.

```json
{ "driver": "pi", "driver_pane": "%25", "driver_pid": 12345, "advisor": "fable", "advisor_pane": "%42", "advisor_pid": 12346, "repo": "/path/to/repo", "updated": "2026-09-16T14:20:00" }
```

## 검토 메모

조언자가 커밋을 검토한 결과를 쌓아두는 파일이다. 드라이버가 보고나 요청을 보낼 때까지 여기 머무른다.

| 파일 | 내용 |
| --- | --- |
| `${TMPDIR:-/tmp}/pair-$(id -u)/notes-<드라이버 pane 번호>.md` | 아직 드라이버에게 전달하지 않은 검토 |
| `${TMPDIR:-/tmp}/pair-$(id -u)/notes-<드라이버 pane 번호>.delivered.md` | 전달을 마친 검토 |

조언자는 커밋 알림을 받을 때마다 앞 파일에 덧붙이고, 답변을 보낸 뒤 그 항목을 뒤 파일로 옮긴다. 두 파일 모두 이력이 목적이므로 계속 쌓인다.

## 최초 기동

1. 작업 요약(TASK)을 정리한다. 사용자가 /pair 뒤에 준 말이 있으면 그것을 우선으로, 없으면 현재 대화에서 드라이버가 진행 중인 작업을 한두 문단으로 요약한다.
2. `pair-state.sh show "$DRIVER_PANE"` 로 기존 기록을 찾는다. 기록의 advisor_pane 이 살아 있고 그 pane 의 pid 가 기록과 같으면 그 어드바이저를 재사용한다. 이때는 [메시지 전송]만 하고 끝낸다. pid 가 다르면 그 pane 의 세션은 이미 갈린 것이므로 재사용하지 않는다.
3. 어드바이저 모델을 선택한다.
4. REPO 를 두 CLI 의 신뢰 목록에 등록한다 (`trust_repo`).
5. 감시기 스크립트를 먼저 만들고, 초기 메시지를 임시 파일로 쓴 뒤, 어드바이저를 수평 분할로 띄운다. 초기 메시지를 어드바이저의 첫 프롬프트로 넘긴다.
6. `pair-state.sh write` 로 상태를 기록한다. 이 기록이 이후 모든 전송의 대상 검사 기준이 된다.
7. 초기 메시지에는 어드바이저가 `WATCHER_FILE` 을 백그라운드로 실행해 모니터링을 만들도록 지시한다.

```bash
D="${TMPDIR:-/tmp}/pair-$(id -u)"
mkdir -p "$D/state"
KEY="${DRIVER_PANE#%}"
NOTES_FILE="$D/notes-$KEY.md"
NOTES_DELIVERED="$D/notes-$KEY.delivered.md"
WATCHER_FILE="$D/watcher-$KEY.sh"
WATCHER_LOG="$D/watcher-$KEY.log"
INIT="$D/init-$(date +%s).md"
# 감시기 절의 스크립트를 <REPO>, <ADVISOR_PANE>, <DRIVER_PANE>, <PAIR_SEND>, <NOTES_FILE> 을 채워 WATCHER_FILE 로 쓴다.
# 초기 메시지 절의 템플릿을 값으로 채워 INIT 로 쓴다. <PAIR_SEND>, <PAIR_STATE> 는 앞 절에서 찾은 경로다.
ADVISOR_PANE=$(tmux split-window -t "$DRIVER_PANE" -h -P -F '#{pane_id}' -c "$REPO" "$ADVISOR_CMD \"\$(cat '$INIT')\"")
bash "$PAIR_STATE" write "$DRIVER_PANE" "$ADVISOR_PANE" "$DRIVER" "$ADVISOR" "$REPO"
```

파일 이름의 키도 드라이버 pane id 다. 윈도우 번호로 이름을 지으면 pane 이 다른 윈도우로 옮겨갔을 때 남의 페어 파일을 집는다.

## 초기 메시지

아래를 실제 값으로 채워 초기 메시지로 보낸다.

```
너는 tmux pane <DRIVER_PANE> 의 드라이버 에이전트(<DRIVER>) 세션이 진행하는 작업의 페어 어드바이저다.

작업 저장소: <REPO>
작업 내용:
<TASK>

역할
- 드라이버 에이전트의 작업에 대해 계획과 조언을 준다.
- 드라이버가 만든 커밋을 그때그때 검토해 메모로 쌓아둔다.
- 드라이버가 완료를 알리면 아래 기준으로 완료 여부를 검토한다.

말 거는 시점
- 드라이버 pane 으로 메시지를 보내는 때는 드라이버가 보고하거나 조언을 구했을 때뿐이다. 그 외에는 먼저 말을 걸지 않는다.
- 커밋 검토, 중간에 발견한 문제, 하고 싶은 지적은 전부 검토 메모에 쌓아두고 다음 답변에 실어 보낸다.
- 예외는 정지 신호 하나다. 감시기가 드라이버 정지를 알리거나 네가 정지를 발견하면, 저장소와 드라이버 화면을 직접 점검한 뒤 먼저 말을 건다.
- 그 밖에 드라이버가 묻지 않았는데 보내면 드라이버의 작업 흐름을 끊는다.

검토 메모
- 파일: <NOTES_FILE>. 미전달 검토만 담는다.
- 전달한 검토는 <NOTES_DELIVERED> 로 옮기고 <NOTES_FILE> 은 비운다.
- 항목마다 커밋 해시와 시각을 남긴다. 심각도(막아야 함 / 고치는 게 좋음 / 참고)를 붙인다.

응답 프로토콜
- 드라이버가 보고나 요청을 보내면, 먼저 <NOTES_FILE> 을 읽어 미전달 검토를 모은다.
- 답변은 요청에 대한 답을 앞에 두고, 쌓아둔 커밋 검토를 뒤에 정리해 붙인다. 같은 지적이 여러 커밋에 걸쳐 있으면 하나로 합친다. 쌓인 것이 없으면 요청에 대한 답만 보낸다.
- 답변을 /tmp/pair-reply.md 로 쓰고 아래 명령을 실행한다. 메시지는 명확하고 간결하게, 줄 첫머리에 슬래시(/)를 쓰지 않는다.
  bash <PAIR_SEND> <DRIVER_PANE> /tmp/pair-reply.md
- 이 명령이 0 이 아닌 코드로 끝나면 메시지가 도착하지 않은 것이다. 같은 파일로 한 번 더 실행한다.
- 코드 6 은 대상 pane 확인에 걸린 것이다. 대상을 바꿔가며 다시 쏘지 마라. <PAIR_STATE> show 로 기록을 확인하고, 드라이버 pane 이 맞는지 tmux list-panes 로 확인한 뒤 <PAIR_STATE> write 로 다시 등록하고 보낸다.
- 전송이 성공하면 보낸 검토 항목을 <NOTES_DELIVERED> 로 옮긴다.
- 첫 응답(작업에 대한 계획과 조언)은 이 지시를 받은 직후 한 번 보낸다.

커밋 감시 생성
- 드라이버 세션의 새 커밋을 감지하는 감시기를 백그라운드로 만들어 실행한다.
  nohup bash <WATCHER_FILE> > <WATCHER_LOG> 2>&1 &
- 감시기가 이 pane 으로 새 커밋을 알리면 git show, git diff 로 작업 방향과 맞는지 검토하고 결과를 <NOTES_FILE> 에 덧붙인다. 드라이버에게는 보내지 않는다.

완료 검토
- 드라이버가 작업 완료를 알리면 아래 기준으로 검토한다.
  - 사용자 전역 규칙(AGENTS.md 등 시스템 지시). 한국어 문체는 sucks 스킬 원칙, 주장·수치 검증은 osiri 원칙을 따른다. 가능하면 ~/.agents/skills/sucks/SKILL.md 와 ~/.agents/skills/osiri/SKILL.md 를 읽어 기준으로 삼는다.
  - 프로젝트 로컬 규칙 (저장소의 AGENTS.md, CLAUDE.md 등)
  - 쌓아둔 커밋 검토 중 아직 반영되지 않은 지적
- 기준에 어긋나거나 남은 작업이 있으면 구체적인 재작업을 지시하고, 충분하면 완료를 확인한다. 결과를 드라이버 pane 으로 보낸다.

유지
- 페어가 끝나도 이 세션과 감시기를 종료하지 않는다. 실행 상태로 유지한다.
```

## 메시지 전송

메시지는 `pair-send.sh` 로만 보낸다. 직접 `tmux paste-buffer` 와 `send-keys` 를 부르지 않는다. 이 스크립트가 보내기 전에 대상 pane 이 맞는지 확인하고, 보낸 뒤 제출됐는지 확인한다.

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

보내기 전 확인 네 가지다. 사람이 기억할 필요가 없도록 스크립트가 막는다.

| 확인 | 막는 사고 |
| --- | --- |
| 대상이 내 pane 이 아닐 것 | 자기 자신에게 보내기 |
| 대상이 pi, claude, codex 중 하나를 돌리고 있을 것 | 셸이나 로그 pane 에 붙여넣기 |
| 기록상 내 상대와 대상이 같을 것 | 남의 페어 pane 으로 보내기 |
| 기록된 pane pid 와 지금 pid 가 같을 것 | pane 은 그대로인데 안의 세션이 갈린 뒤 옛 상대로 보내기 |

종료 코드는 3이면 pane 이 없는 것, 4면 붙여넣기가 입력창에 닿지 못한 것, 5면 메시지가 입력창에 남아 제출되지 않은 것, 6이면 대상 pane 확인에 걸린 것이다. 0이 아니면 전송된 것으로 간주하지 않는다. 특히 6은 대상을 바꿔 다시 쏘지 말고, `pair-state.sh show` 로 지금 기록을 확인한 뒤 `pair-state.sh write` 로 다시 등록하고 보낸다.

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

사용자가 어드바이저에게 조언·계획·검토를 요청하면, 현재 작업 맥락을 요약해 어드바이저 pane 으로 보낸다. 재분할하지 않는다. 어드바이저는 요청에 대한 답과 함께 그동안 쌓아둔 커밋 검토를 정리해 돌려준다.

## 보고 시점

어드바이저는 드라이버가 말을 걸 때만 답한다. 커밋만 쌓이고 드라이버가 아무 말도 하지 않으면 검토는 메모에 머무른다. 따라서 드라이버는 다음 시점에 어드바이저에게 보고한다.

- 한 덩어리의 작업을 끝냈을 때
- 방향을 고르기 어려울 때
- 커밋을 여러 개 쌓은 뒤, 쌓인 검토를 받아보고 싶을 때
- 작업 완료를 선언할 때

## 완료 검토

사용자가 작업 완료를 알리면 어드바이저에게 완료 검토를 요청한다. 완료 판단 근거와 작업 요약을 담고, 전역 규칙·프로젝트 규칙·sucks 문체·osiri 검증 기준으로 검토해 재작업 지시 또는 완료 확인을 요청한다. 어드바이저의 응답에는 아직 전달되지 않은 커밋 검토가 함께 담겨 온다. 응답이 도착하면 사용자에게 전달하고, 재작업 지시가 있으면 그대로 이어서 작업한다.

## 유지

페어가 끝나도 어드바이저와 감시기를 종료하지 않는다. 드라이버, 어드바이저, 감시기 모두 실행 상태로 유지한다.

## 감시기

아래 스크립트를 `<REPO>`, `<ADVISOR_PANE>`, `<DRIVER_PANE>`, `<PAIR_SEND>`, `<NOTES_FILE>` 을 채워 임시 파일로 만들고 실행 가능하게 만든다. 어드바이저가 이 파일을 백그라운드로 실행해 모니터링을 생성한다. 감시기는 어드바이저가 종료되어도 돌아가므로, 어드바이저를 다시 띄울 때는 감시기를 내리고 새 어드바이저의 pane id 로 다시 올린다.

감시기가 보는 것은 둘이다. 새 커밋과 드라이버의 정지다. 커밋은 조용히 검토하게 하고, 정지는 즉시 개입하게 한다.

```bash
#!/usr/bin/env bash
# 드라이버 세션의 새 커밋과 정지를 감지해 어드바이저 pane 으로 알린다
set -u
REPO="<REPO>"
ADVISOR_PANE="<ADVISOR_PANE>"
DRIVER_PANE="<DRIVER_PANE>"
PAIR_SEND="<PAIR_SEND>"
NOTES_FILE="<NOTES_FILE>"
INTERVAL=10
STALL_SECONDS=300
norm() { case "$1" in %*) printf '%s' "$1" ;; *) printf '%%%s' "$1" ;; esac; }
ADVISOR_PANE=$(norm "$ADVISOR_PANE")
DRIVER_PANE=$(norm "$DRIVER_PANE")
git -C "$REPO" rev-parse HEAD >/dev/null 2>&1 || { echo "not a git repo: $REPO"; exit 1; }
last=$(git -C "$REPO" rev-parse HEAD)
last_screen=""
last_change=$SECONDS
stall_reported=0
while true; do
  sleep "$INTERVAL"
  # 감시 대상 pane 이 사라지면 종료한다. 남겨두면 없는 pane 으로 계속 전송을 시도한다.
  [ -z "$(tmux display-message -p -t "$ADVISOR_PANE" '#{pane_id}' 2>/dev/null)" ] && exit 0

  # 정지 감지: 드라이버 화면이 STALL_SECONDS 동안 한 글자도 안 바뀌면 멈춘 것이다.
  # 작업 중이면 스피너와 출력이 계속 바뀌므로 정지와 구분된다.
  screen=$(tmux capture-pane -p -t "$DRIVER_PANE" 2>/dev/null | md5sum)
  if [ "$screen" != "$last_screen" ]; then
    last_screen="$screen"; last_change=$SECONDS; stall_reported=0
  elif [ "$stall_reported" -eq 0 ] && [ $((SECONDS - last_change)) -ge "$STALL_SECONDS" ]; then
    msg=$(mktemp)
    {
      printf '[pair] 드라이버 pane %s 화면이 %d분 넘게 그대로다. 정지 신호다.\n\n' "$DRIVER_PANE" $((STALL_SECONDS / 60))
      printf -- '--- 드라이버 화면 끝부분\n'
      tmux capture-pane -p -t "$DRIVER_PANE" 2>/dev/null | tail -20
      printf -- '---\n\n'
      printf '무엇이 막혀 있는지 네가 직접 점검해라. 저장소 상태(git status, git log, 최근 변경 파일), 열린 편집기 프로세스(ps -eo pid,etimes,args | grep -i editor), 드라이버 입력창에 제출되지 않고 남은 메시지를 본다.\n'
      printf '점검 결과를 가지고 드라이버에게 말을 걸어라. 정지일 때는 드라이버가 묻지 않아도 먼저 보내는 것이 맞다.\n'
    } > "$msg"
    bash "$PAIR_SEND" "$ADVISOR_PANE" "$msg" || echo "watcher: stall notice failed"
    rm -f "$msg"
    stall_reported=1
  fi

  head=$(git -C "$REPO" rev-parse HEAD 2>/dev/null) || continue
  [ "$head" = "$last" ] && continue
  log=$(git -C "$REPO" log --oneline --no-merges "$last..$head" 2>/dev/null) || log=""
  if [ -n "$log" ]; then
    msg=$(mktemp)
    printf '[pair] 드라이버 세션의 새 커밋이 감지되었다.\n%s\n방향이 작업과 맞는지 지금 검토하고 결과를 %s 에 덧붙여라. 드라이버에게는 보내지 마라.\n' "$log" "$NOTES_FILE" > "$msg"
    bash "$PAIR_SEND" "$ADVISOR_PANE" "$msg" || echo "watcher: send failed for $head"
    rm -f "$msg"
  fi
  last="$head"
done
```

정지 알림은 한 번의 정지마다 한 번만 간다. 드라이버 화면이 다시 바뀌면 다음 정지를 위해 재무장한다.

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

`pair-select-advisor.sh`, `pair-send.sh`, `pair-state.sh` 는 이 스킬 디렉토리에 함께 배치된다. 원격 저장소로 배포할 때는 SKILL.md 와 함께 네 파일을 올려야 한다.
