# Audio Tools — File Browser with fzf Integration
# Enhanced file selection and preview

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi

# ── File Browser with fzf ──

browse_files() {
    local dir="${1:-.}"
    local title="${2:-Select files}"
    local multi="${3:-yes}"

    [ ! -d "$dir" ] && { log_error "Directory not found: $dir"; return 1; }

    # Check if fzf is available
    if ! command -v fzf >/dev/null 2>&1; then
        log_warning "fzf not found. Using simple file selection."
        browse_files_simple "$dir" "$title" "$multi"
        return $?
    fi

    # Build file list
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(resolve_audio_files "$dir")

    if [ ${#files[@]} -eq 0 ]; then
        log_warning "No audio files found in $dir"
        return 1
    fi

    # Prepare fzf options
    local fzf_opts=(
        --multi
        --preview "ffprobe -v error -select_streams a:0 -show_entries stream=duration,bit_rate,channels,sample_rate -of default=noprint_wrappers=1:nokey=1 {} 2>/dev/null | tr '\n' ' ' || echo 'metadata unavailable'"
        --preview-window="right:30%"
        --bind "change:last-100"
        --header "Total: ${#files[@]} files | Preview: select files with Tab"
    )

    if [ "$multi" != "yes" ]; then
        # Single selection mode
        unset 'fzf_opts[0]'  # Remove --multi
    fi

    # Display fzf browser
    local selected=()
    while IFS= read -r file; do
        selected+=("$file")
    done < <(printf '%s\n' "${files[@]}" | fzf "${fzf_opts[@]}")

    if [ ${#selected[@]} -eq 0 ]; then
        log_info "No files selected"
        return 1
    fi

    # Export selected files
    BROWSER_SELECTED=("${selected[@]}")
    echo "${#selected[@]} file(s) selected"
    return 0
}

# ── Simple File Browser (fallback) ──

browse_files_simple() {
    local dir="${1:-.}"
    local title="${2:-Select files}"
    local multi="${3:-yes}"

    # Build file list
    local files=()
    local file_names=()
    local idx=0

    while IFS= read -r -d '' file; do
        files+=("$file")
        file_names+=("$idx) $(basename "$file")")
        idx=$((idx + 1))
    done < <(resolve_audio_files "$dir")

    if [ ${#files[@]} -eq 0 ]; then
        log_warning "No audio files found in $dir"
        return 1
    fi

    # Display menu
    clear
    echo "$title"
    echo "Directory: $dir"
    echo ""

    for name in "${file_names[@]}"; do
        echo "  $name"
    done

    echo ""

    if [ "$multi" = "yes" ]; then
        read -p "Enter file numbers (space-separated) or 'all' for all: " selection
    else
        read -p "Enter file number: " selection
    fi

    # Parse selection
    local selected=()

    if [ "$selection" = "all" ]; then
        selected=("${files[@]}")
    else
        for num in $selection; do
            if [ "$num" -lt ${#files[@]} ] && [ "$num" -ge 0 ]; then
                selected+=("${files[$num]}")
            fi
        done
    fi

    if [ ${#selected[@]} -eq 0 ]; then
        log_info "No files selected"
        return 1
    fi

    BROWSER_SELECTED=("${selected[@]}")
    echo ""
    echo "${#selected[@]} file(s) selected"
    return 0
}

# ── Directory Browser ──

browse_directories() {
    local root="${1:-.}"
    local title="${2:-Select directory}"

    if ! command -v fzf >/dev/null 2>&1; then
        # Fallback: simple input
        read -p "$title [$root]: " dir
        echo "${dir:-$root}"
        return 0
    fi

    # Use find to list directories, then select with fzf
    local selected=$(find "$root" -type d -maxdepth 3 2>/dev/null | \
        fzf --preview 'ls -la {}' --preview-window="right:40%")

    if [ -z "$selected" ]; then
        echo "$root"
        return 1
    fi

    echo "$selected"
    return 0
}

# ── File Preview ──

preview_file() {
    local file="$1"

    [ ! -f "$file" ] && { log_error "File not found"; return 1; }

    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  File Preview: $(basename "$file")"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""

    # Display metadata if ffprobe available
    if command -v ffprobe >/dev/null 2>&1; then
        echo "Metadata:"
        echo ""

        local duration=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "?")
        local bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "?")
        [ -z "$bitrate" ] && bitrate="?"
        local channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "?")
        local sample_rate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "?")

        echo "  File:        $(basename "$file")"
        echo "  Size:        $(du -h "$file" 2>/dev/null | cut -f1)"
        echo "  Duration:    ${duration%.*}s"
        if [ "$bitrate" != "?" ]; then
            echo "  Bitrate:     $((bitrate / 1000))k"
        fi
        echo "  Channels:    $channels"
        echo "  Sample Rate: $sample_rate Hz"
    fi

    echo ""
    echo "Press Enter to close..."
    read
}

# ── Export ──

export -f browse_files browse_files_simple browse_directories preview_file
