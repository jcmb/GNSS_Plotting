TrimbleTools=0

gnss_sanitize_path_segment() {
  local s="${1:-}"
  s="${s//[^a-zA-Z0-9_.-]/}"
  printf '%s' "$s"
}

gnss_normalize_project_path() {
  local raw="${1:-}"
  raw="${raw#/}"
  if [ -z "$raw" ]; then
    printf '/General'
    return
  fi
  local IFS='/'
  local -a parts=($raw)
  local -a clean=()
  local part seg result=""
  for part in "${parts[@]}"; do
    seg="$(gnss_sanitize_path_segment "$part")"
    if [ -n "$seg" ]; then
      clean+=("$seg")
    fi
  done
  if [ ${#clean[@]} -eq 0 ]; then
    printf '/General'
    return
  fi
  for seg in "${clean[@]}"; do
    result="${result}/${seg}"
  done
  printf '%s' "$result"
}

gnss_resolve_session_name() {
  local file_full="$1"
  local ext="$2"
  local name=""
  name="$(basename "$file_full" "$ext" 2>/dev/null || true)"
  name="$(gnss_sanitize_path_segment "$name")"
  if [ -z "$name" ]; then
    name="$(basename "$file_full")"
    name="${name%$ext}"
    name="$(gnss_sanitize_path_segment "$name")"
  fi
  if [ -z "$name" ] || [ "$name" = "$ext" ] || [ "$name" = "${ext#.}" ]; then
    name=""
  fi
  if [ -z "$name" ]; then
    name="session_$(date +%Y%m%d_%H%M%S)_$$"
    logger "GNSS plot: empty session name; using fallback $name" 2>/dev/null || true
  fi
  printf '%s' "$name"
}