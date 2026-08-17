#!/bin/bash
#
# Manage free space on /mnt/Data by pruning old results under
# /mnt/Data/results. Top-level directories under results are kept;
# only dated subdirectories inside each project directory are removed.
#
# When free space drops below 300 MB, delete subdirectories older than
# 60 days, then reduce the retention window by one day and repeat until
# space is recovered or the minimum one-day retention is reached.

set -euo pipefail

MOUNT="/mnt/Data"
RESULTS_ROOT="${MOUNT}/results"
MIN_FREE_KB=$((300 * 1024))
INITIAL_RETENTION_DAYS=60
MIN_RETENTION_DAYS=1
LOG_FILE="${TRACKINGPLOT_CLEANUP_LOG:-/var/log/trackingplot_cleanup_data.log}"

log() {
    local ts msg
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    msg="$ts $*"
    echo "$msg"
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
    echo "$msg" >>"$LOG_FILE" 2>/dev/null || true
}

get_free_kb() {
    df -P "$MOUNT" 2>/dev/null | awk 'NR==2 {print $4}'
}

# Return age in whole days for a results subdirectory. Prefer a date
# encoded in the directory name; fall back to the directory mtime.
dir_age_days() {
    local dir="$1"
    local name epoch now

    name="$(basename "$dir")"
    now="$(date +%s)"

    if [[ $name =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
        epoch="$(date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}" +%s 2>/dev/null || true)"
    elif [[ $name =~ ^([0-9]{4})([0-9]{2})([0-9]{2})$ ]]; then
        epoch="$(date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}" +%s 2>/dev/null || true)"
    elif [[ $name =~ ^([0-9]{4})_([0-9]{2})_([0-9]{2})$ ]]; then
        epoch="$(date -d "${BASH_REMATCH[1]}-${BASH_REMATCH[2]}-${BASH_REMATCH[3]}" +%s 2>/dev/null || true)"
    fi

    if [[ -n "${epoch:-}" && "$epoch" =~ ^[0-9]+$ ]]; then
        echo $(( (now - epoch) / 86400 ))
        return 0
    fi

    epoch="$(stat -c %Y "$dir" 2>/dev/null || stat -f %m "$dir")"
    echo $(( (now - epoch) / 86400 ))
}

is_safe_subdir() {
    local subdir="$1"
    local rel

    [[ -d "$subdir" ]] || return 1
    [[ "$subdir" == "${RESULTS_ROOT}/"* ]] || return 1

    rel="${subdir#${RESULTS_ROOT}/}"
    [[ "$rel" == */*/* ]] || return 1
    [[ "$rel" != */*/*/* ]] || return 1

    return 0
}

delete_subdir() {
    local subdir="$1"

    if ! is_safe_subdir "$subdir"; then
        log "SKIP unsafe path: $subdir"
        return 1
    fi

    rm -rf -- "$subdir"
}

purge_older_than() {
    local retention_days="$1"
    local top project sub age deleted

    deleted=0

    shopt -s nullglob
    for top in "${RESULTS_ROOT}"/*/; do
        [[ -d "$top" ]] || continue
        for project in "${top}"*/; do
            [[ -d "$project" ]] || continue
            for sub in "${project}"*/; do
                [[ -d "$sub" ]] || continue
                age="$(dir_age_days "$sub")"
                if (( age > retention_days )); then
                    log "Deleting ${sub} (age ${age}d > ${retention_days}d retention)"
                    if delete_subdir "$sub"; then
                        deleted=$((deleted + 1))
                    fi
                fi
            done
        done
    done
    shopt -u nullglob

    echo "$deleted"
}

main() {
    local free_kb retention deleted

    if [[ ! -d "$MOUNT" ]]; then
        log "Mount path missing: $MOUNT"
        exit 0
    fi

    if [[ ! -d "$RESULTS_ROOT" ]]; then
        log "Results directory missing: $RESULTS_ROOT"
        exit 0
    fi

    free_kb="$(get_free_kb)"
    if [[ -z "$free_kb" || ! "$free_kb" =~ ^[0-9]+$ ]]; then
        log "Unable to read free space for $MOUNT"
        exit 1
    fi

    if (( free_kb >= MIN_FREE_KB )); then
        log "OK: ${free_kb} KB free on $MOUNT (minimum ${MIN_FREE_KB} KB)"
        exit 0
    fi

    log "LOW SPACE: ${free_kb} KB free on $MOUNT (minimum ${MIN_FREE_KB} KB); starting cleanup"

    retention="$INITIAL_RETENTION_DAYS"
    while true; do
        deleted="$(purge_older_than "$retention")"
        free_kb="$(get_free_kb)"

        log "Pass complete: retention=${retention}d deleted=${deleted} free=${free_kb} KB"

        if (( free_kb >= MIN_FREE_KB )); then
            log "Space recovered: ${free_kb} KB free on $MOUNT"
            exit 0
        fi

        if (( retention <= MIN_RETENTION_DAYS )); then
            log "Still low on space (${free_kb} KB) but minimum retention (${MIN_RETENTION_DAYS}d) reached; stopping"
            exit 1
        fi

        retention=$((retention - 1))
        log "Still below minimum free space; reducing retention to ${retention} days"
    done
}

main "$@"
