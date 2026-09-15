#!/usr/bin/env bash
# Select the pair advisor model between "astra" (GPT-6 Astra, low effort, via codex)
# and "fable" (Claude Fable 5.1, low effort, via claude) by whichever provider has
# more weekly usage remaining. Prints "astra" or "fable" on stdout.
# Force a choice with PAIR_ADVISOR=astra|fable. Diagnostics go to stderr.
set -u
DEFAULT=fable
log(){ echo "[pair-select] $*" >&2; }

if [ -n "${PAIR_ADVISOR:-}" ]; then
  case "$PAIR_ADVISOR" in astra|fable) log "PAIR_ADVISOR override: $PAIR_ADVISOR"; echo "$PAIR_ADVISOR"; exit 0;; esac
fi

D="${TMPDIR:-/tmp}/pair-$(id -u)"
mkdir -p "$D/state"
CACHE="$D/state/usage-claude.txt"

# ---------- Codex / astra : weekly window from live endpoint ----------
codex_remaining=""
if [ -f "$HOME/.codex/auth.json" ] && command -v python3 >/dev/null 2>&1; then
  out=$(python3 - 2>/dev/null <<'PY' || true
import json, os, urllib.request
try:
    auth = json.load(open(os.path.expanduser("~/.codex/auth.json")))
    tok = (auth.get("tokens") or {}).get("access_token", "")
    acct = (auth.get("tokens") or {}).get("account_id", "")
    req = urllib.request.Request("https://chatgpt.com/backend-api/wham/usage",
        headers={"Authorization": "Bearer " + tok, "Content-Type": "application/json"})
    if acct: req.add_header("ChatGPT-Account-Id", acct)
    with urllib.request.urlopen(req, timeout=15) as r:
        d = json.load(r)
    pw = (d.get("rate_limit") or {}).get("primary_window") or {}
    used = pw.get("used_percent")
    if used is not None:
        print("rem=%d" % (100 - int(used)))
    else:
        print("rem=")
    a = ((d.get("model_usage") or {}).get("gpt-6-astra") or {}).get("available")
    print("avail=" + ("1" if a else ("0" if a is not None else "")))
except Exception:
    pass
PY
)
  codex_remaining=$(printf '%s\n' "$out" | sed -n 's/^rem=//p')
  codex_available=$(printf '%s\n' "$out" | sed -n 's/^avail=//p')
  if [ -n "$codex_remaining" ]; then
    if [ "$codex_available" = "0" ]; then
      codex_remaining=0
      log "codex: gpt-6-astra unavailable -> remaining 0%"
    else
      log "codex: weekly remaining=${codex_remaining}%"
    fi
  else
    log "codex: usage probe failed"
  fi
else
  log "codex: not configured (~/.codex/auth.json missing)"
fi

# ---------- Claude / fable : weekly "Current week (all models)" via /usage ----------
claude_remaining=""
if command -v claude >/dev/null 2>&1 && command -v tmux >/dev/null 2>&1; then
  if [ -f "$CACHE" ]; then
    age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
    if [ "$age" -lt 600 ]; then
      claude_remaining=$(cat "$CACHE")
      log "claude: weekly remaining=${claude_remaining}% (cached ${age}s old)"
    fi
  fi
  if [ -z "$claude_remaining" ]; then
    S="pairprobe-$$"
    OUT=$(mktemp /tmp/pairprobe-XXXX.txt)
    cleanup(){ tmux kill-session -t "$S" 2>/dev/null; rm -f "$OUT"; }
    trap cleanup EXIT
    if tmux new-session -d -s "$S" -x 220 -y 200 claude 2>/dev/null; then
      for i in $(seq 1 240); do
        tmux capture-pane -t "$S" -p 2>/dev/null | grep -qE "Claude Code" && break
        sleep 0.5
      done
      sleep 2
      tmux send-keys -t "$S" "/usage"; sleep 0.8
      tmux send-keys -t "$S" Escape; sleep 0.5
      tmux send-keys -t "$S" Enter
      for i in $(seq 1 200); do
        tmux capture-pane -t "$S" -p 2>/dev/null | grep -q "Current week" && break
        sleep 0.5
      done
      sleep 1
      tmux send-keys -t "$S" PageDown; sleep 0.4
      tmux send-keys -t "$S" PageDown; sleep 0.4
      tmux capture-pane -t "$S" -p -S -200 2>/dev/null | sed 's/\r//g' > "$OUT"
      pct=$(awk '/Current week \(all models\)/{f=1;next} f&&NF{gsub(/[^0-9%]/,"");gsub(/%/,"");if($0!=""){print;exit}}' "$OUT" | head -1)
      if [ -n "$pct" ]; then
        claude_remaining=$((100 - pct))
        printf '%s' "$claude_remaining" > "$CACHE"
        log "claude: weekly used=${pct}% remaining=${claude_remaining}%"
      else
        log "claude: usage parse failed"
      fi
    else
      log "claude: probe tmux session failed"
    fi
    cleanup
  fi
else
  log "claude: claude/tmux not available"
fi

# ---------- decide ----------
log "codex remaining=${codex_remaining:-?} claude remaining=${claude_remaining:-?}"
if [ -z "$codex_remaining" ] && [ -z "$claude_remaining" ]; then log "both probes failed -> $DEFAULT"; echo "$DEFAULT"; exit 0; fi
if [ -z "$claude_remaining" ]; then log "claude unknown -> astra"; echo "astra"; exit 0; fi
if [ -z "$codex_remaining" ]; then log "codex unknown -> $DEFAULT"; echo "$DEFAULT"; exit 0; fi
if [ "$codex_remaining" -gt "$claude_remaining" ]; then echo "astra"; else echo "fable"; fi
