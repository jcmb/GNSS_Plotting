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

RESULT_DIR="${GNSS_RESULT_DIR:-}"
WEB_LOG=""
if [ -n "$RESULT_DIR" ]; then
   mkdir -p "$RESULT_DIR"
   WEB_LOG="$RESULT_DIR/processing_output.txt"
   echo "Worker launching $(date)" > "$RESULT_DIR/processing.txt"
fi

OUT="${WEB_LOG:-$LOG}"

{
   echo "=== $(date -Is) queue plot_single_cgi.sh ==="
   echo "upload: ${1:-unknown}"
   echo "result dir: ${RESULT_DIR:-none}"
   echo "log: $OUT"
} >>"$OUT"

if [ "$OUT" != "$LOG" ]; then
   echo "=== $(date -Is) also logging to $OUT ===" >>"$LOG"
fi

logger "Queuing position plot for ${1:-unknown} (log=$OUT)"

PLOT_CMD=("${SCRIPT_DIR}/plot_single_cgi.sh" "$@")
if command -v stdbuf >/dev/null 2>&1; then
   PLOT_CMD=(stdbuf -oL -eL "${PLOT_CMD[@]}")
fi

if command -v setsid >/dev/null 2>&1; then
   setsid nohup "${PLOT_CMD[@]}" >>"$OUT" 2>&1 &
else
   nohup "${PLOT_CMD[@]}" >>"$OUT" 2>&1 &
fi
WORKER_PID=$!

{
   echo "Background worker PID $WORKER_PID started $(date -Is)"
} >>"$OUT"

if [ -n "$RESULT_DIR" ]; then
   echo "Worker started (pid $WORKER_PID) $(date)" > "$RESULT_DIR/processing.txt"
fi

logger "Position plot worker pid=$WORKER_PID for ${1:-unknown}"

disown -a 2>/dev/null || true
exit 0
