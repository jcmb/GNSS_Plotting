#!/bin/bash
#
# Manage free space on /mnt/GPS_Admin_Backup by pruning old GNSS backup data
# under /mnt/GPS_Admin_Backup/GNSS_Data.
#
# When free space drops below 300 MB, delete dated data older than 60 days from
# GRK, ROVERS, and TestSite using the same retention window. If space is still
# low, prune dated data under BASES except for protected base directories.
# Reduce the retention window by one day and repeat until space is recovered
# or the minimum one-day retention is reached.

set -euo pipefail

MOUNT="/mnt/GPS_Admin_Backup"
DATA_ROOT="${MOUNT}/GNSS_Data"
MIN_FREE_KB=$((300 * 1024))
INITIAL_RETENTION_DAYS=60
MIN_RETENTION_DAYS=1
LOG_FILE="${TRACKINGPLOT_CLEANUP_GNSS_LOG:-/var/log/trackingplot_cleanup_gnss_backup.log}"

PRIMARY_DIRS=(GRK ROVERS TestSite)
BASES_DIR="BASES"
PROTECTED_BASES=(BTN_R750_450 WCO_Base BTN_Base)

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

# Return age in whole days for a dated subdirectory. Prefer a date encoded
# in the directory name; fall back to the directory mtime.
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

is_protected_base() {
    local base_name="$1"
    local protected

    for protected in "${PROTECTED_BASES[@]}"; do
        if [[ "$base_name" == "$protected" ]]; then
            return 0
        fi
    done
    return 1
}

is_safe_primary_subdir() {
    local subdir="$1"
    local rel parent

    [[ -d "$subdir" ]] || return 1
    [[ "$subdir" == "${DATA_ROOT}/"* ]] || return 1

    rel="${subdir#${DATA_ROOT}/}"
    [[ "$rel" == */* ]] || return 1
    [[ "$rel" != */*/* ]] || return 1

    parent="${rel%%/*}"
    for primary in "${PRIMARY_DIRS[@]}"; do
        if [[ "$parent" == "$primary" ]]; then
            return 0
        fi
    done
    return 1
}

is_safe_bases_subdir() {
    local subdir="$1"
    local rel base_name

    [[ -d "$subdir" ]] || return 1
    [[ "$subdir" == "${DATA_ROOT}/${BASES_DIR}/"* ]] || return 1

    rel="${subdir#${DATA_ROOT}/${BASES_DIR}/}"
    [[ "$rel" == */* ]] || return 1
    [[ "$rel" != */*/* ]] || return 1

    base_name="${rel%%/*}"
    if is_protected_base "$base_name"; then
        return 1
    fi

    return 0
}

delete_subdir() {
    local subdir="$1"
    rm -rf -- "$subdir"
}

purge_primary_dirs() {
    local retention_days="$1"
    local primary sub age deleted

    deleted=0
    shopt -s nullglob
    for primary in "${PRIMARY_DIRS[@]}"; do
        for sub in "${DATA_ROOT}/${primary}"/*/; do
            [[ -d "$sub" ]] || continue
            if ! is_safe_primary_subdir "$sub"; then
                log "SKIP unsafe primary path: $sub"
                continue
            fi
            age="$(dir_age_days "$sub")"
            if (( age > retention_days )); then
                log "Deleting ${sub} (age ${age}d > ${retention_days}d retention)"
                delete_subdir "$sub"
                deleted=$((deleted + 1))
            fi
        done
    done
    shopt -u nullglob

    echo "$deleted"
}

purge_bases_dirs() {
    local retention_days="$1"
    local base sub base_name age deleted

    deleted=0
    shopt -s nullglob
    for base in "${DATA_ROOT}/${BASES_DIR}"/*/; do
        [[ -d "$base" ]] || continue
        base_name="$(basename "$base")"
        if is_protected_base "$base_name"; then
            continue
        fi
        for sub in "${base}"*/; do
            [[ -d "$sub" ]] || continue
            if ! is_safe_bases_subdir "$sub"; then
                log "SKIP unsafe BASES path: $sub"
                continue
            fi
            age="$(dir_age_days "$sub")"
            if (( age > retention_days )); then
                log "Deleting ${sub} (age ${age}d > ${retention_days}d retention)"
                delete_subdir "$sub"
                deleted=$((deleted + 1))
            fi
        done
    done
    shopt -u nullglob

    echo "$deleted"
}

main() {
    local free_kb retention primary_deleted bases_deleted total_deleted

    if [[ ! -d "$MOUNT" ]]; then
        log "Mount path missing: $MOUNT"
        exit 0
    fi

    if [[ ! -d "$DATA_ROOT" ]]; then
        log "Data directory missing: $DATA_ROOT"
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
        primary_deleted="$(purge_primary_dirs "$retention")"
        free_kb="$(get_free_kb)"
        log "Primary pass complete: retention=${retention}d deleted=${primary_deleted} free=${free_kb} KB"

        if (( free_kb >= MIN_FREE_KB )); then
            log "Space recovered after primary cleanup: ${free_kb} KB free on $MOUNT"
            exit 0
        fi

        bases_deleted="$(purge_bases_dirs "$retention")"
        total_deleted=$((primary_deleted + bases_deleted))
        free_kb="$(get_free_kb)"
        log "Pass complete: retention=${retention}d primary_deleted=${primary_deleted} bases_deleted=${bases_deleted} total_deleted=${total_deleted} free=${free_kb} KB"

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
