# Audio Tools — Cleaner core (no prompts, no exit, no stdout echo)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t media_get_duration)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/media.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t _format_rename)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi

# Output: null-delimited file paths on stdout (always returns 0; empty = no matches)
get_short_files() {
    local folder="$1"
    local threshold="$2"

    if ! [[ "$threshold" =~ ^[0-9]+$ ]]; then
        log_error "Threshold must be a positive integer, got: $threshold"
        return 1
    fi

    local _fc=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then _fc=${#AUDIO_TOOLS_FILES[@]}; fi
    if [ ! -d "$folder" ] && [ "$_fc" -eq 0 ] && [ -z "${AUDIO_TOOLS_FILES_FROM:-}" ]; then
        log_error "Folder does not exist: $folder"
        return 1
    fi

    while IFS= read -r -d '' file; do
        local duration
        duration=$(media_get_duration "$file")
        duration=${duration%.*}
        : "${duration:=0}"
        if [ "$duration" -lt "$threshold" ]; then
            printf '%s\0' "$file"
        fi
    done < <(resolve_audio_files "$folder")

    return 0
}

# Output: null-delimited file paths on stdout (always returns 0; empty = no matches)
get_long_files() {
    local folder="$1"
    local threshold="$2"

    if ! [[ "$threshold" =~ ^[0-9]+$ ]]; then
        log_error "Threshold must be a positive integer, got: $threshold"
        return 1
    fi

    local _fc=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then _fc=${#AUDIO_TOOLS_FILES[@]}; fi
    if [ ! -d "$folder" ] && [ "$_fc" -eq 0 ] && [ -z "${AUDIO_TOOLS_FILES_FROM:-}" ]; then
        log_error "Folder does not exist: $folder"
        return 1
    fi

    while IFS= read -r -d '' file; do
        local duration
        duration=$(media_get_duration "$file")
        duration=${duration%.*}
        : "${duration:=0}"
        if [ "$duration" -gt "$threshold" ]; then
            printf '%s\0' "$file"
        fi
    done < <(resolve_audio_files "$folder")

    return 0
}

# Output: each rename as "old -> new" on stdout
clean_filenames() {
    local directory="$1"

    local _fc=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then
        _fc=${#AUDIO_TOOLS_FILES[@]}
    fi
    local all_files=()
    if [ "$_fc" -gt 0 ] || [ -n "${AUDIO_TOOLS_FILES_FROM:-}" ]; then
        while IFS= read -r -d '' file; do
            all_files+=("$file")
        done < <(resolve_audio_files "$directory")
    else
        if [ -f "$directory" ]; then
            all_files+=("$directory")
        elif [ -d "$directory" ]; then
            log_info "Scanning files in $directory..."
            for file in "$directory"/*; do
                [ -f "$file" ] || continue
                all_files+=("$file")
            done
        else
            log_error "Path not found: $directory"; return 1
        fi
    fi

    local total="${#all_files[@]}"
    [ "$total" -eq 0 ] && { log_warn "No files found."; return 0; }

    local count=0 idx=0
    init_progress "$total" "Cleaning filenames"
    for file in "${all_files[@]}"; do
        idx=$((idx + 1))
        local dir
        dir=$(dirname "$file")
        local filename
        filename=$(basename "$file")
        local newname
        newname=$(sanitize_filename "$filename")

        if [ "$filename" != "$newname" ]; then
            if [ -e "$dir/$newname" ]; then
                update_progress "$filename (skipped)"
            else
                mv "$file" "$dir/$newname"
                echo "$filename -> $newname"
                count=$((count + 1))
                update_progress "$filename → $newname"
            fi
        else
            update_progress "$filename (clean)"
        fi
    done

    finish_progress "$count" 0 "cleaned $count file(s)"
}

# Output: each rename as "old -> new" on stdout
rename_files() {
    local directory="$1"
    local pattern="${AUDIO_TOOLS_PATTERN:-}"

    if [ -z "$pattern" ]; then
        log_error "Pattern (--pattern) is required. Use tokens: {n}, {orig}, {ext}, {date}"; return 1
    fi

    local _fc=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then
        _fc=${#AUDIO_TOOLS_FILES[@]}
    fi
    local all_files=()
    while IFS= read -r -d '' file; do
        all_files+=("$file")
    done < <(resolve_audio_files "$directory")

    local total="${#all_files[@]}"
    [ "$total" -eq 0 ] && { log_warn "No files found."; return 0; }

    log_info "Pattern: $pattern"
    local count=0 idx=0
    init_progress "$total" "Renaming"

    for file in "${all_files[@]}"; do
        idx=$((idx + 1))
        local dir; dir=$(dirname "$file")
        local filename; filename=$(basename "$file")
        local newname; newname=$(_format_rename "$pattern" "$filename" "$idx")

        if [[ "$newname" != *.* ]]; then
            newname="${newname}.${filename##*.}"
        fi

        if [ "$filename" != "$newname" ]; then
            if [ -e "$dir/$newname" ]; then
                update_progress "$filename (skipped)"
            else
                if [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ]; then
                    echo "  $filename -> $newname"
                else
                    mv "$file" "$dir/$newname"
                    echo "$filename -> $newname"
                fi
                count=$((count + 1))
                update_progress "$filename → $newname"
            fi
        else
            update_progress "$filename (unchanged)"
        fi
    done

    finish_progress "$count" 0 "renamed $count file(s)"
}
