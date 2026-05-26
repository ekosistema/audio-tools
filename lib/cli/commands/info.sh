# Audio Tools — Info subcommand
# Display audio file metadata

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t init_output)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../ui/output.sh"
fi

cmd_info() {
    local file=""

    # Check for help
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
Display audio file metadata

USAGE:
  audio-tools info [file]

OPTIONS:
  -h, --help              Show this help message

EXAMPLES:
  audio-tools info sample.wav
  audio-tools info /path/to/audio.mp3
EOF
        return 0
    fi

    # Get file from argument or AUDIO_TOOLS_FILES
    if [ -n "$1" ] && [ -f "$1" ]; then
        file="$1"
    elif [ -n "${AUDIO_TOOLS_FILES[0]:-}" ]; then
        file="${AUDIO_TOOLS_FILES[0]}"
    fi

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        log_error "No file specified or file not found"
        return "$EX_USAGE"
    fi

    # Initialize output
    init_output

    # Display info
    display_file_info "$file"
}

display_file_info() {
    local file="$1"
    local filename=$(basename "$file")
    local filepath="$file"
    local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
    local ext="${filename##*.}"

    # Try to get audio metadata from ffprobe
    local duration=0
    local bitrate=0
    local channels=0
    local sample_rate=0
    local codec=""

    if command -v ffprobe >/dev/null 2>&1; then
        # Get duration
        duration=$(ffprobe -v error -show_entries format=duration \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo 0)

        # Get bitrate (in bits/second)
        bitrate=$(ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo 0)
        [ -z "$bitrate" ] && bitrate=0
        bitrate=$((bitrate / 1000))  # Convert to kbps

        # Get channels
        channels=$(ffprobe -v error -select_streams a:0 -show_entries stream=channels \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo 0)

        # Get sample rate
        sample_rate=$(ffprobe -v error -select_streams a:0 -show_entries stream=sample_rate \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo 0)

        # Get codec
        codec=$(ffprobe -v error -select_streams a:0 -show_entries stream=codec_name \
            -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "unknown")
    fi

    # Format output
    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{'
        printf '"file":"%s",' "$file"
        printf '"filename":"%s",' "$filename"
        printf '"format":"%s",' "$ext"
        printf '"size":%d,' "$size"
        printf '"duration":%.2f,' "$duration"
        printf '"bitrate":%d,' "$bitrate"
        printf '"channels":%d,' "$channels"
        printf '"sample_rate":%d,' "$sample_rate"
        printf '"codec":"%s"' "$codec"
        printf '}\n'
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        output_table_header "Property" "Value"
        output_table_row "Filename" "$filename"
        output_table_row "Path" "$filepath"
        output_table_row "Format" "$ext"
        output_table_row "Size" "$(format_size "$size")"
        output_table_row "Duration" "$(format_duration "${duration%.*}")"
        output_table_row "Bitrate" "${bitrate}k"
        output_table_row "Channels" "$channels"
        output_table_row "Sample Rate" "${sample_rate}Hz"
        output_table_row "Codec" "$codec"
        output_table_footer
    fi

    return 0
}

export -f cmd_info display_file_info
