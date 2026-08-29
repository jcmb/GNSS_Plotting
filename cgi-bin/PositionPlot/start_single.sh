#!/bin/bash
export GNSS_MEAN_SOL="${GNSS_MEAN_SOL:-${10:--1}}"
export GNSS_REPORT_URL="${GNSS_REPORT_URL:-${11:-}}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if command -v stdbuf >/dev/null 2>&1; then
   exec stdbuf -oL -eL "${SCRIPT_DIR}/plot_single_cgi.sh" "$@"
fi
exec "${SCRIPT_DIR}/plot_single_cgi.sh" "$@"
