#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG="/run/shm/trackingplot_$(basename "$1").log"
"${SCRIPT_DIR}/plot_single_cgi.sh" "$1" "$2" "$3" "$4" >>"$LOG" 2>&1 &
disown
