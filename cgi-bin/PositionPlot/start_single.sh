#!/bin/bash
export GNSS_MEAN_SOL="${GNSS_MEAN_SOL:-${10:--1}}"
export GNSS_REPORT_URL="${GNSS_REPORT_URL:-${11:-}}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UPLOAD_BASE="$(basename "${1:-unknown}")"
LOG="/run/shm/positionplot_${UPLOAD_BASE}.log"

if ! touch "$LOG" 2>/dev/null; then
   LOG="/tmp/positionplot_${UPLOAD_BASE}.log"
   touch "$LOG" 2>/dev/null || LOG="/tmp/positionplot_$$.log"
fi

{
   echo "=== $(date -Is) queue plot_single_cgi.sh ==="
   echo "args: $*"
   echo "log: $LOG"
} >>"$LOG"

logger "Queuing position plot for ${1:-unknown} (log=$LOG)"

if command -v setsid >/dev/null 2>&1; then
   setsid nohup "${SCRIPT_DIR}/plot_single_cgi.sh" "$@" >>"$LOG" 2>&1 &
else
   nohup "${SCRIPT_DIR}/plot_single_cgi.sh" "$@" >>"$LOG" 2>&1 &
fi

disown -a 2>/dev/null || true
exit 0
