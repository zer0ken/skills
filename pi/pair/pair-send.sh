#!/usr/bin/env bash
# Sends one message to a tmux pane running an agent TUI and confirms it was submitted.
#
# Usage: pair-send.sh <pane> <file>
#
# The paste and the Enter are two separate tmux commands, so the Enter can reach
# the TUI before the paste is committed to its editor; the keystroke then lands
# inside the pasted block instead of submitting it, and the message sits in the
# prompt. Both steps are therefore verified against the pane's input box rather
# than assumed, and the Enter is retried in three encodings, because a TUI that
# negotiated extended keys does not always accept the one tmux sends first.
set -u

PANE="${1:-}"
FILE="${2:-}"

if [ -z "$PANE" ] || [ -z "$FILE" ]; then
  echo "usage: pair-send.sh <pane> <file>" >&2
  exit 2
fi
if [ ! -s "$FILE" ]; then
  echo "pair-send: empty or missing message file: $FILE" >&2
  exit 2
fi
if [ -z "$(tmux display-message -p -t "$PANE" '#{pane_id}' 2>/dev/null)" ]; then
  echo "pair-send: no such pane: $PANE" >&2
  exit 3
fi

# Text sitting in the TUI's input box. Every agent TUI here draws that box
# between two horizontal rules at the bottom of the pane; a rule carrying a
# label, such as pi's "── Working ──", still counts as a boundary. U+00A0 is
# Claude Code's filler for an empty box, so it counts as whitespace.
input_box() {
  tmux capture-pane -p -t "$PANE" | tail -25 | awk '
    { line[NR] = $0 }
    /^[[:space:]]*─/ { prev = last; last = NR }
    END {
      if (!prev || !last) exit
      for (i = prev + 1; i < last; i++) print line[i]
    }
  ' | sed 's/[❯>]//g; s/\xc2\xa0//g' | tr -d '[:space:]'
}

wait_for() { # $1 = "filled" | "empty", $2 = deadline in seconds
  local want="$1" deadline=$((SECONDS + $2)) box
  while [ "$SECONDS" -lt "$deadline" ]; do
    box=$(input_box)
    if [ "$want" = "filled" ] && [ -n "$box" ]; then return 0; fi
    if [ "$want" = "empty" ] && [ -z "$box" ]; then return 0; fi
    sleep 0.2
  done
  return 1
}

# A pane in copy mode swallows every key, so leave it first.
[ "$(tmux display-message -p -t "$PANE" '#{pane_in_mode}')" = "1" ] && tmux send-keys -t "$PANE" -X cancel

tmux load-buffer -b pairmsg - < "$FILE"
tmux paste-buffer -b pairmsg -t "$PANE" -p

if ! wait_for filled 5; then
  echo "pair-send: paste never reached the input box of $PANE" >&2
  exit 4
fi

for attempt in 1 2 3 4; do
  case "$attempt" in
    2) tmux send-keys -t "$PANE" -H 0d ;;  # raw CR
    3) tmux send-keys -t "$PANE" C-m ;;
    *) tmux send-keys -t "$PANE" Enter ;;
  esac
  if wait_for empty 3; then
    exit 0
  fi
done

echo "pair-send: message still sits unsent in the prompt of $PANE" >&2
exit 5
