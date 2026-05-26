# Audio Tools — Organizer core (no prompts, no exit, no stdout echo)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t init_progress)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/progress.sh"
fi

# Output: null-delimited copied file paths on stdout
scan_audios_subfolders() {
    local source_folder="$1"
    local dest_folder="${2:-${source_folder}/${AUDIO_TOOLS_SCAN_DIR:-ALL_AUDIOS}}"

    if [ ! -d "$source_folder" ]; then
        log_error "Folder does not exist: $source_folder"
        return 1
    fi

    mkdir -p "$dest_folder"
    log_info "Scanning for audio files in $source_folder..."

    local all_files=()
    while IFS= read -r -d '' file; do
        all_files+=("$file")
    done < <(find_audio_files_recursive "$source_folder")

    local total="${#all_files[@]}"
    if [ "$total" -eq 0 ]; then
        log_warn "No audio files found in $source_folder"
        return 0
    fi

    log_info "Found $total file(s). Copying to $dest_folder..."

    local count=0
    init_progress "$total" "Copying to $dest_folder"
    for file in "${all_files[@]}"; do
        count=$((count + 1))
        copy_with_rename "$file" "$dest_folder"
        update_progress "$(basename "$file")"
    done

    finish_progress "$count" 0 "copied to $dest_folder"
}

# Output: null-delimited matching file paths on stdout
search_audios() {
    local folder="$1"
    local query="$2"

    if [ -z "$query" ]; then
        log_error "Search query cannot be empty"
        return 1
    fi

    local _fc=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then _fc=${#AUDIO_TOOLS_FILES[@]}; fi
    if [ -n "$folder" ] && [ ! -d "$folder" ] && [ "$_fc" -eq 0 ] && [ -z "${AUDIO_TOOLS_FILES_FROM:-}" ]; then
        log_error "Folder does not exist: $folder"
        return 1
    fi

    local query_lower
    query_lower=$(echo "$query" | tr '[:upper:]' '[:lower:]')

    while IFS= read -r -d '' file; do
        local base
        base=$(basename "$file" | tr '[:upper:]' '[:lower:]')
        case "$base" in
            *"$query_lower"*) printf '%s\0' "$file" ;;
        esac
    done < <(resolve_audio_files_recursive "$folder")
}
