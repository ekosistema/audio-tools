# Audio Tools — Pre-flight validation
# Aborts before processing if any input file is unreadable

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t init_progress)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/progress.sh"
fi

# Validate that every file in the list is a readable audio file.
# On failure: prints which files are bad and returns 1.
validate_files_for_action() {
    local action="$1"
    shift
    local -a files=("$@")
    local total=${#files[@]}

    [ "$total" -eq 0 ] && return 0

    init_progress "$total" "Validating"
    local errors=0 bad_files=() idx=0

    for f in "${files[@]}"; do
        idx=$((idx + 1))
        if [ -f "$f" ] && _is_audio_file "$f" 2>/dev/null; then
            :
        else
            errors=$((errors + 1))
            bad_files+=("$f")
        fi
        update_progress "$(basename "$f")"
    done

    local ok=$((total - errors))
    finish_progress "$ok" "$errors" "ready"

    if [ "$errors" -gt 0 ]; then
        log_error "Aborting — $errors file(s) can't be read by ffprobe:"
        for bf in "${bad_files[@]}"; do
            echo "    $bf" >&2
        done
        return 1
    fi
    return 0
}

# Wrapper for dispatchers: resolve files + validate before processing
resolve_and_validate() {
    local dir="$1"
    local -a files=()
    while IFS= read -r -d '' f; do files+=("$f"); done < <(resolve_audio_files "$dir")
    validate_files_for_action "${FUNCNAME[1]:-action}" "${files[@]}" || return 1
    printf '%s\0' "${files[@]}"
}
