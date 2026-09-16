#!/usr/bin/env bash
# Pair records, keyed by the driver pane id.
#
# Usage:
#   pair-state.sh write <driver_pane> <advisor_pane> <driver> <advisor> <repo>
#   pair-state.sh show <pane>          record containing that pane, as JSON
#   pair-state.sh counterpart <pane>   the other pane of that pair
#   pair-state.sh pid <pane>           pane pid recorded for that pane
#
# The key is the driver pane id because pane ids are never reused and survive
# moving a pane to another window. A (session, window) key does neither, and a
# stale one points at whatever pane now sits there.
set -u

DIR="${TMPDIR:-/tmp}/pair-$(id -u)/state"
mkdir -p "$DIR"

norm() { case "$1" in %*) printf '%s' "$1" ;; *) printf '%%%s' "$1" ;; esac; }
pane_pid() { tmux display-message -p -t "$1" '#{pane_pid}' 2>/dev/null; }

cmd="${1:-}"
shift || true

case "$cmd" in
  write)
    [ $# -eq 5 ] || { echo "usage: pair-state.sh write <driver_pane> <advisor_pane> <driver> <advisor> <repo>" >&2; exit 2; }
    dp=$(norm "$1"); ap=$(norm "$2")
    dpid=$(pane_pid "$dp"); apid=$(pane_pid "$ap")
    [ -n "$dpid" ] || { echo "pair-state: no such pane: $dp" >&2; exit 3; }
    [ -n "$apid" ] || { echo "pair-state: no such pane: $ap" >&2; exit 3; }
    python3 - "$DIR/pair-${dp#%}.json" "$dp" "$dpid" "$ap" "$apid" "$3" "$4" "$5" <<'PY'
import json, sys, time
path, dp, dpid, ap, apid, driver, advisor, repo = sys.argv[1:9]
json.dump({
    "driver": driver, "driver_pane": dp, "driver_pid": int(dpid),
    "advisor": advisor, "advisor_pane": ap, "advisor_pid": int(apid),
    "repo": repo, "updated": time.strftime("%Y-%m-%dT%H:%M:%S"),
}, open(path, "w"), ensure_ascii=False, indent=1)
PY
    echo "$DIR/pair-${dp#%}.json"
    ;;
  show|counterpart|pid)
    [ $# -eq 1 ] || { echo "usage: pair-state.sh $cmd <pane>" >&2; exit 2; }
    python3 - "$DIR" "$(norm "$1")" "$cmd" <<'PY'
import json, glob, os, sys
d, pane, op = sys.argv[1:4]
for path in sorted(glob.glob(os.path.join(d, "pair-*.json")), key=os.path.getmtime, reverse=True):
    try:
        r = json.load(open(path))
    except Exception:
        continue
    if pane not in (r.get("driver_pane"), r.get("advisor_pane")):
        continue
    if op == "show":
        print(json.dumps(r, ensure_ascii=False))
    elif op == "counterpart":
        print(r["advisor_pane"] if pane == r["driver_pane"] else r["driver_pane"])
    else:
        print(r["driver_pid"] if pane == r["driver_pane"] else r["advisor_pid"])
    sys.exit(0)
sys.exit(1)
PY
    ;;
  *)
    echo "usage: pair-state.sh write|show|counterpart|pid ..." >&2
    exit 2
    ;;
esac
