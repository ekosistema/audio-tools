# Audio Tools — Filesystem I/O (find, copy, rename, file resolution)

_audio_extensions_find() {
    local dir="$1" depth="${2:-${AUDIO_TOOLS_MAX_DEPTH:-}}"
    local -a depth_args=()
    [ -n "$depth" ] && depth_args=(-maxdepth "$depth")
    find "$dir" "${depth_args[@]}" -type f \( -iname "*.mp3" -o -iname "*.wav" -o -iname "*.ogg" \
        -o -iname "*.flac" -o -iname "*.aac" -o -iname "*.wma" -o -iname "*.m4a" \) -print0
}

find_audio_files_non_recursive() {
    local dir="$1"
    _audio_extensions_find "$dir" 1
}

find_audio_files_recursive() {
    local dir="$1"
    _audio_extensions_find "$dir"
}

_is_audio_extension() {
    local file="$1" ext="${1##*.}"
    case "${ext,,}" in
        mp3|wav|ogg|flac|aac|wma|m4a|opus|aiff|aif|webm) return 0 ;;
        *) return 1 ;;
    esac
}

_is_audio_file() {
    local file="$1"
    _is_audio_extension "$file" || return 1
    LD_LIBRARY_PATH="" ffprobe -v error -i "$file" \
        -show_entries format=format_name \
        -of default=noprint_wrappers=1:nokey=1 >/dev/null 2>&1
}

# Resolve audio files from multiple sources:
#   1. Explicit --directory
#   2. Positional args (files or directories)
#   3. --files-from (file list)
#   4. Fallback: passed dir or pwd
# Output: null-delimited paths on stdout
resolve_audio_files() {
    local dir="${1:-}"
    declare -A seen
    local -a result=()

    # Safely query AUDIO_TOOLS_FILES count (may not be declared if parse_args was not called)
    local _file_count=0
    if declare -p AUDIO_TOOLS_FILES &>/dev/null 2>&1; then
        _file_count=${#AUDIO_TOOLS_FILES[@]}
    fi

    local _find_fn="find_audio_files_non_recursive"
    [ "${AUDIO_TOOLS_RECURSIVE:-no}" = "yes" ] && _find_fn="find_audio_files_recursive"

    # 1. Explicit --directory (set by user) — accepts file or directory
    if [ -n "${AUDIO_TOOLS_DIRECTORY:-}" ]; then
        if [ -d "$AUDIO_TOOLS_DIRECTORY" ]; then
            while IFS= read -r -d '' f; do
                result+=("$f"); seen["$f"]=1
            done < <("$_find_fn" "$AUDIO_TOOLS_DIRECTORY")
        elif [ -f "$AUDIO_TOOLS_DIRECTORY" ] && _is_audio_file "$AUDIO_TOOLS_DIRECTORY"; then
            result+=("$AUDIO_TOOLS_DIRECTORY"); seen["$AUDIO_TOOLS_DIRECTORY"]=1
        fi
    fi

    # 2. Positional args (files & directories)
    if [ "$_file_count" -gt 0 ]; then
        for entry in "${AUDIO_TOOLS_FILES[@]}"; do
            [ -z "$entry" ] && continue
            if [ -d "$entry" ]; then
                while IFS= read -r -d '' f; do
                    [ -n "${seen[$f]:-}" ] && continue
                    result+=("$f"); seen["$f"]=1
                done < <("$_find_fn" "$entry")
            elif [ -f "$entry" ]; then
                if _is_audio_file "$entry"; then
                    [ -n "${seen[$entry]:-}" ] && continue
                    result+=("$entry"); seen["$entry"]=1
                else
                    log_warn "Not a valid audio file: $entry"
                fi
            else
                log_warn "Path not found: $entry"
            fi
        done
    fi

    # 3. --files-from (file list)
    if [ -n "${AUDIO_TOOLS_FILES_FROM:-}" ] && [ -f "$AUDIO_TOOLS_FILES_FROM" ]; then
        while IFS= read -r entry; do
            [ -z "$entry" ] && continue
            [ -n "${seen[$entry]:-}" ] && continue
            if [ -f "$entry" ] && _is_audio_file "$entry"; then
                result+=("$entry"); seen["$entry"]=1
            fi
        done < "$AUDIO_TOOLS_FILES_FROM"
    fi

    # 4. Fallback: nothing given → scan passed file, dir, or pwd
    if [ ${#result[@]} -eq 0 ] && [ "$_file_count" -eq 0 ] && [ -z "${AUDIO_TOOLS_DIRECTORY:-}" ] && [ -z "${AUDIO_TOOLS_FILES_FROM:-}" ]; then
        local scan_target="${dir:-$(pwd)}"
        if [ -f "$scan_target" ] && _is_audio_file "$scan_target"; then
            result+=("$scan_target")
        elif [ -d "$scan_target" ]; then
            while IFS= read -r -d '' f; do
                result+=("$f")
            done < <("$_find_fn" "$scan_target")
        fi
    fi

    [ ${#result[@]} -gt 0 ] && printf '%s\0' "${result[@]}"
}

resolve_audio_files_recursive() {
    local saved="${AUDIO_TOOLS_RECURSIVE:-no}"
    AUDIO_TOOLS_RECURSIVE=yes
    resolve_audio_files "$@"
    AUDIO_TOOLS_RECURSIVE="$saved"
}

copy_with_rename() {
    local src="$1" dest_dir="$2"
    local base_name; base_name=$(basename "$src")
    local dest="$dest_dir/$base_name"
    local counter=1
    while [ -e "$dest" ]; do
        local name="${base_name%.*}" extension="${base_name##*.}"
        dest="$dest_dir/${name}_${counter}.${extension}"
        counter=$((counter + 1))
    done
    cp "$src" "$dest"
    echo "Copied: $src -> $dest"
}

sanitize_filename() {
    local name="$1"
    echo "$name" | sed -e 's/ /_/g' -e 's/[^[:alnum:]\._-]//g'
}

_format_rename() {
    local pattern="$1" orig="$2" num="$3"
    local base="${orig%.*}" ext="${orig##*.}"
    local result="$pattern"
    result="${result//\{n\}/$num}"
    result="${result//\{orig\}/$base}"
    result="${result//\{ext\}/$ext}"
    result="${result//\{date\}/$(date +%Y%m%d)_$(LC_ALL=C tr -dc 'a-zA-Z0-9' < /dev/urandom 2>/dev/null | head -c6)}"
    echo "$result"
}
