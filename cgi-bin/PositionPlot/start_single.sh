#!/bin/bash
export GNSS_MEAN_SOL="${GNSS_MEAN_SOL:-${10:--1}}"
export GNSS_REPORT_URL="${GNSS_REPORT_URL:-${11:-}}"
exec stdbuf -o L ./plot_single_cgi.sh "$@"
