#!/bin/bash
# Deploy GNSS plotting CGI scripts and HTML upload forms to the web server.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
CGI_DEST="${CGI_DEST:-/usr/lib/cgi-bin}"
HTML_DEST="${HTML_DEST:-/var/www/html}"
TRACKING_HTML_DEST="${TRACKING_HTML_DEST:-$HTML_DEST/Tracking}"

POSITION_HTML="$ROOT/HTML/T02_2_PNG.html"
TRACKING_HTML="$ROOT/HTML/T02_2_TRACKING.html"

DRY_RUN=0
DELETE=0

usage() {
  cat <<EOF
Usage: sudo $0 [options]

Deploy from this repository to the production web paths:
  cgi-bin/                 -> ${CGI_DEST}/{PositionPlot,TrackingPlot,VoltagePlot}/
  HTML/T02_2_PNG.html      -> ${HTML_DEST}/T02_2_PNG.html
  HTML/T02_2_TRACKING.html -> ${TRACKING_HTML_DEST}/T02_2_TRACKING.html

Options:
  -n, --dry-run   Show what would be copied, without changing the server
  --delete        Remove CGI files on the server that are not in the repository
  -h, --help      Show this help

Environment:
  CGI_DEST            CGI root (default: /usr/lib/cgi-bin)
  HTML_DEST           Position upload form directory (default: /var/www/html)
  TRACKING_HTML_DEST  Tracking upload form directory (default: \$HTML_DEST/Tracking)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift ;;
    --delete) DELETE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo so files can be written to $CGI_DEST and $HTML_DEST." >&2
  exit 1
fi

if [[ ! -d "$ROOT/cgi-bin" ]] || [[ ! -d "$ROOT/HTML" ]]; then
  echo "Expected cgi-bin/ and HTML/ under $ROOT." >&2
  exit 1
fi

if [[ ! -f "$POSITION_HTML" ]] || [[ ! -f "$TRACKING_HTML" ]]; then
  echo "Expected HTML upload forms under $ROOT/HTML/." >&2
  exit 1
fi

RSYNC=(rsync -a --human-readable)
if [[ $DRY_RUN -eq 1 ]]; then
  RSYNC+=(--dry-run -v)
else
  RSYNC+=(-v)
fi
if [[ $DELETE -eq 1 ]]; then
  RSYNC+=(--delete)
fi

RSYNC_EXCLUDES=(
  --exclude '__pycache__/'
  --exclude '*.pyc'
  --exclude '*.bak'
  --exclude 'auth.htpasswd'
)

mark_executable() {
  local target="$1"
  find "$target" -type f \( -name '*.sh' -o -name '*.pl' \) -exec chmod +x {} +
  while IFS= read -r -d '' py; do
    if head -1 "$py" | grep -q '^#!'; then
      chmod +x "$py"
    fi
  done < <(find "$target" -type f -name '*.py' -print0)
}

VERSION="unknown"
if [[ -f "$ROOT/cgi-bin/TrackingPlot/VERSION" ]]; then
  VERSION="$(tr -d '\r\n' < "$ROOT/cgi-bin/TrackingPlot/VERSION")"
fi

echo "GNSS Plotting deploy (version $VERSION)"
echo "Source: $ROOT"
echo "CGI destination:           $CGI_DEST/"
echo "Position HTML destination: $HTML_DEST/T02_2_PNG.html"
echo "Tracking HTML destination: $TRACKING_HTML_DEST/T02_2_TRACKING.html"

mkdir -p "$CGI_DEST" "$HTML_DEST" "$TRACKING_HTML_DEST"

echo
echo "==> Syncing CGI scripts"
"${RSYNC[@]}" "${RSYNC_EXCLUDES[@]}" "$ROOT/cgi-bin/" "$CGI_DEST/"

echo
echo "==> Syncing HTML upload forms"
"${RSYNC[@]}" "$POSITION_HTML" "$HTML_DEST/"
"${RSYNC[@]}" "$TRACKING_HTML" "$TRACKING_HTML_DEST/"

if [[ $DRY_RUN -eq 0 ]]; then
  echo
  echo "==> Setting executable bits on CGI scripts"
  mark_executable "$CGI_DEST"
fi

echo
echo "Deploy complete."
echo "  CGI:  $CGI_DEST/PositionPlot/"
echo "        $CGI_DEST/TrackingPlot/"
echo "        $CGI_DEST/VoltagePlot/"
echo "  HTML: $HTML_DEST/T02_2_PNG.html"
echo "        $TRACKING_HTML_DEST/T02_2_TRACKING.html"
echo
echo "Reprocess existing reports to refresh result symlinks (index.shtml, JS)."
