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

audio_find_dupes() {
    local dir="${1:-}"

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files_recursive "$dir")
    local total=${#files[@]}
    [ "$total" -lt 2 ] && { log_warn "Need at least 2 files to find duplicates."; return 0; }

    log_info "Hashing $total file(s)..."
    declare -A hash_groups
    local idx=0

    for file in "${files[@]}"; do
        idx=$((idx + 1))
        local hash=""
        hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1) || hash=""
        [ -z "$hash" ] && continue
        hash_groups["$hash"]="${hash_groups[$hash]-}${file}|"
    done

    local dupes_found=0
    echo ""
    for hash in "${!hash_groups[@]}"; do
        local IFS='|'
        local files_in_group=(${hash_groups[$hash]})
        unset IFS
        [ ${#files_in_group[@]} -lt 2 ] && continue
        dupes_found=$((dupes_found + ${#files_in_group[@]} - 1))
        echo ""
        styled_echo "$DARK_GRAY" "── Duplicate group ──"
        local i
        for i in "${!files_in_group[@]}"; do
            if [ "$i" -eq 0 ]; then
                echo -e "  ${BOLD}original:${NC} ${files_in_group[$i]}"
            else
                echo -e "  ${DIM}duplicate:${NC} ${files_in_group[$i]}"
            fi
        done
    done

    [ "$dupes_found" -eq 0 ] && echo "  No duplicates found."
    echo ""
    log_info "Found $dupes_found duplicate(s) in $total file(s)"
    return 0
}

audio_dedup() {
    local dir="${1:-}"

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files_recursive "$dir")
    local total=${#files[@]}
    [ "$total" -lt 2 ] && { log_warn "Need at least 2 files to deduplicate."; return 0; }

    declare -A hash_groups
    local idx=0

    init_progress "$total" "Hashing"
    for file in "${files[@]}"; do
        idx=$((idx + 1))
        local hash
        hash=$(sha256sum "$file" 2>/dev/null | cut -d' ' -f1)
        [ -z "$hash" ] && continue
        hash_groups["$hash"]="${hash_groups[$hash]-}${file}|"
        update_progress "$(basename "$file")"
    done

    local dupes_found=0
    echo ""
    for hash in "${!hash_groups[@]}"; do
        local IFS='|'
        local files_in_group=(${hash_groups[$hash]})
        unset IFS
        [ ${#files_in_group[@]} -lt 2 ] && continue
        dupes_found=$((dupes_found + ${#files_in_group[@]} - 1))
        echo ""
        styled_echo "$DARK_GRAY" "── Duplicate group ──"
        local i
        for i in "${!files_in_group[@]}"; do
            if [ "$i" -eq 0 ]; then
                echo -e "  ${BOLD}original:${NC} ${files_in_group[$i]}"
            else
                echo -e "  ${DIM}duplicate:${NC} ${files_in_group[$i]}"
            fi
        done
    done

    [ "$dupes_found" -eq 0 ] && echo "  No duplicates found."
    echo ""
    finish_progress 0 0 "found $dupes_found duplicate(s)"
    return 0
}
