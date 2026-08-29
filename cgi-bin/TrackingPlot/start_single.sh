#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPLOAD_BASE="$(basename "${1:-unknown}")"
LOG="/run/shm/trackingplot_${UPLOAD_BASE}.log"

if ! touch "$LOG" 2>/dev/null; then
   LOG="/tmp/trackingplot_${UPLOAD_BASE}.log"
   touch "$LOG" 2>/dev/null || LOG="/tmp/trackingplot_$$.log"
fi

{
   echo "=== $(date -Is) queue plot_single_cgi.sh ==="
   echo "args: $*"
   echo "log: $LOG"
} >>"$LOG"

logger "Queuing tracking plot for ${1:-unknown} (log=$LOG)"

if command -v setsid >/dev/null 2>&1; then
   setsid nohup "${SCRIPT_DIR}/plot_single_cgi.sh" "$1" "$2" "$3" "$4" >>"$LOG" 2>&1 &
else
   nohup "${SCRIPT_DIR}/plot_single_cgi.sh" "$1" "$2" "$3" "$4" >>"$LOG" 2>&1 &
fi

disown -a 2>/dev/null || true
