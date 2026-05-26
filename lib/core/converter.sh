# Audio Tools — Converter core

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t media_convert_file)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/media.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t init_progress)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/progress.sh"
fi

convert_to_mp3() {
    local source_folder="$1"
    local custom_output="${2:-}"
    local fmt="${AUDIO_TOOLS_FORMAT:-mp3}"
    local bitrate="${AUDIO_TOOLS_BITRATE:-320k}"

    local _fc=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then _fc=${#AUDIO_TOOLS_FILES[@]}; fi
    if [ -n "$source_folder" ] && [ ! -d "$source_folder" ] && [ ! -f "$source_folder" ] && [ "$_fc" -eq 0 ] && [ -z "${AUDIO_TOOLS_FILES_FROM:-}" ]; then
        log_error "Path not found: $source_folder"; return 1
    fi

    local mapping ext
    mapping=$(media_format_map "$fmt")
    ext="${mapping%%:*}"

    local output_folder
    if [ -n "$custom_output" ]; then
        output_folder="$custom_output"
    elif [ -n "${AUDIO_TOOLS_CONVERTED_DIR:-}" ]; then
        output_folder="${source_folder:+${source_folder}/}${AUDIO_TOOLS_CONVERTED_DIR}"
    else
        output_folder="${source_folder:+${source_folder}/}converted_mp3"
    fi

    mkdir -p "$output_folder"

    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files "$source_folder")

    local total=${#files[@]}
    if [ "$total" -eq 0 ]; then
        log_warn "No audio files to process"; return 0
    fi
    log_info "Found $total file(s) to process"
    echo ""

    if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
        log_info "[DRY RUN] Would convert $total file(s) to $fmt in $output_folder"
        for file in "${files[@]}"; do
            local filename; filename=$(basename "$file")
            local output="${output_folder}/${filename%.*}$ext"
            echo "  would convert: $file -> $output"
        done
        return 0
    fi

    local count=0 errors=0 skipped=0
    init_progress "$total" "Converting to $fmt"
    for file in "${files[@]}"; do
        local filename; filename=$(basename "$file")
        local output="${output_folder}/${filename%.*}$ext"

        if [ -f "$output" ]; then
            skipped=$((skipped + 1)); continue
        fi

        update_progress "$filename"
        if media_convert_file "$file" "$output" "$fmt" "$bitrate"; then
            count=$((count + 1))
        else
            errors=$((errors + 1))
        fi
    done

    finish_progress "$count" "$errors" "converted to $output_folder"
    [ "$skipped" -gt 0 ] && log_info "  $skipped file(s) skipped (already exist)"
    [ "$errors" -gt 0 ] && { log_error "  $errors conversion(s) failed"; return 1; }
    return 0
}
