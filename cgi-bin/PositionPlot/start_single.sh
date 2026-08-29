#!/bin/bash
export GNSS_MEAN_SOL="${GNSS_MEAN_SOL:-${10:--1}}"
export GNSS_REPORT_URL="${GNSS_REPORT_URL:-${11:-}}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="/run/shm/positionplot_$(basename "$1").log"
"${SCRIPT_DIR}/plot_single_cgi.sh" "$@" >>"$LOG" 2>&1 &
disown
