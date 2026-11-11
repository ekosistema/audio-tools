# Audio Tools — Deduper core (dedup, find-dupes)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t init_progress)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/progress.sh"
fi
if [ -z "$(type -t move_to_trash)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/trash.sh"
fi
if [ -z "$(type -t confirm_prompt)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi

# Separator for the file list of a hash group. A control character cannot
# appear in a sensible file name, unlike '|'.
_DEDUP_SEP=$'\x1f'

# Hash every file and fill the global DUP_GROUPS (hash -> files joined by _DEDUP_SEP).
# Files are processed in sorted order so "the first file" is deterministic:
# the original is always the one whose path sorts first.
# Usage: _dedup_collect <dir> <label|"">   (label enables the progress bar)
_dedup_collect() {
    local dir="$1" label="$2"
    DUP_FILES_TOTAL=0
    DUP_GROUPS=()

    local files=() file
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files_recursive "$dir" | LC_ALL=C sort -z)
    DUP_FILES_TOTAL=${#files[@]}
    [ "$DUP_FILES_TOTAL" -lt 2 ] && return 1

    [ -n "$label" ] && init_progress "$DUP_FILES_TOTAL" "$label"
    local hash
    for file in "${files[@]}"; do
        hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
        [ -n "$label" ] && update_progress "$(basename "$file")"
        [ -z "$hash" ] && continue
        DUP_GROUPS["$hash"]="${DUP_GROUPS[$hash]-}${file}${_DEDUP_SEP}"
    done
    return 0
}

# Print every duplicate group; append the files to remove (all but the first
# of each group) to the global DUP_REMOVE array. Echoes nothing else.
_dedup_report() {
    DUP_REMOVE=()
    local hash i
    for hash in "${!DUP_GROUPS[@]}"; do
        local -a group=()
        IFS="$_DEDUP_SEP" read -r -a group <<< "${DUP_GROUPS[$hash]}"
        [ ${#group[@]} -lt 2 ] && continue
        echo ""
        styled_echo "$DARK_GRAY" "── Duplicate group ──"
        for i in "${!group[@]}"; do
            if [ "$i" -eq 0 ]; then
                echo -e "  ${BOLD}keep:${NC}      ${group[$i]}"
            else
                echo -e "  ${DIM}duplicate:${NC} ${group[$i]}"
                DUP_REMOVE+=("${group[$i]}")
            fi
        done
    done
}

audio_find_dupes() {
    local dir="${1:-}"
    declare -A DUP_GROUPS
    local DUP_FILES_TOTAL=0
    local -a DUP_REMOVE=()

    if ! _dedup_collect "$dir" ""; then
        log_warn "Need at least 2 files to find duplicates."
        return 0
    fi
    log_info "Hashed $DUP_FILES_TOTAL file(s)"

    echo ""
    _dedup_report
    [ ${#DUP_REMOVE[@]} -eq 0 ] && echo "  No duplicates found."
    echo ""
    log_info "Found ${#DUP_REMOVE[@]} duplicate(s) in $DUP_FILES_TOTAL file(s)"
    return 0
}

# Move exact duplicates to the trash. The first file of each group (by sorted
# path) is kept. Honours --dry-run and asks for confirmation unless --force.
audio_dedup() {
    local dir="${1:-}"
    declare -A DUP_GROUPS
    local DUP_FILES_TOTAL=0
    local -a DUP_REMOVE=()

    if ! _dedup_collect "$dir" "Hashing"; then
        log_warn "Need at least 2 files to deduplicate."
        return 0
    fi

    echo ""
    _dedup_report
    echo ""
    finish_progress "$DUP_FILES_TOTAL" 0 "found ${#DUP_REMOVE[@]} duplicate(s)"

    if [ ${#DUP_REMOVE[@]} -eq 0 ]; then
        echo "  No duplicates found."
        return 0
    fi

    confirm_prompt "Move ${#DUP_REMOVE[@]} duplicate file(s) to the trash?" || { log_info "Cancelled"; return 0; }

    local moved=0 failed=0 file rc
    for file in "${DUP_REMOVE[@]}"; do
        rc=0
        move_to_trash "$file" "${dir:-.}" || rc=$?
        # 0 = system trash, 2 = local to_delete/ fallback (both are recoverable)
        case "$rc" in
            0|2) moved=$((moved + 1)) ;;
            *)   failed=$((failed + 1)) ;;
        esac
    done
    log_info "$(delete_verb) $moved duplicate file(s)"
    [ "$failed" -gt 0 ] && { log_error "$failed file(s) could not be moved"; return 1; }
    return 0
}
