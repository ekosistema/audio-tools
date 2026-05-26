# Audio Tools — Convert subcommand
# Converts audio files to MP3 (or other formats) using ffmpeg

# Self-source dependencies (allow standalone testing)
if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t convert_to_mp3)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/converter.sh"
fi
if [ -z "$(type -t init_output)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../ui/output.sh"
fi

# ── Command: convert ──
#
# Usage:
#   audio-tools convert [options] [directory]
#
# Options:
#   -d, --directory PATH    Source directory [default: current]
#   -o, --output PATH       Output subdirectory [default: converted_mp3]
#   -f, --format FORMAT     Output format [default: mp3]
#   -b, --bitrate RATE      Audio bitrate [default: 320k]
#   --recursive             Scan subdirectories [default: true]
#   -p, --preview           Show files before converting
#   --force                 Skip confirmation

cmd_convert() {
    local dir="."
    local output=""
    local format="mp3"
    local bitrate="320k"
    local recursive="yes"
    local preview="no"

    # Check for help
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
Convert audio files to MP3 (or other formats)

USAGE:
  audio-tools convert [options] [directory]

OPTIONS:
  -d, --directory PATH    Source directory [default: current]
  -o, --output PATH       Output subdirectory [default: converted_mp3]
  -f, --format FORMAT     Output format [default: mp3]
                          Options: mp3, ogg, aac, flac
  -b, --bitrate RATE      Audio bitrate [default: 320k]
                          Examples: 192k, 256k, 320k
  --no-recursive          Don't scan subdirectories
  -p, --preview           Show before/after files before converting
  -h, --help              Show this help message

EXAMPLES:
  audio-tools convert /path/to/audio
  audio-tools convert -f ogg -b 192k /path
  audio-tools convert --output mp3_low
EOF
        return 0
    fi

    # Parse command-specific arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory)
                dir="$2"
                shift 2
                ;;
            -o|--output)
                output="$2"
                shift 2
                ;;
            -f|--format)
                format="$2"
                shift 2
                ;;
            -b|--bitrate)
                bitrate="$2"
                shift 2
                ;;
            --no-recursive)
                recursive="no"
                shift
                ;;
            -p|--preview)
                preview="yes"
                shift
                ;;
            --)
                shift
                break
                ;;
            -*)
                log_error "Unknown option: $1"
                return "$EX_USAGE"
                ;;
            *)
                # Positional argument (directory)
                dir="$1"
                shift
                ;;
        esac
    done

    # Validate path (file or directory)
    if [ ! -d "$dir" ] && [ ! -f "$dir" ]; then
        log_error "Path not found: $dir"
        return "$EX_IOERR"
    fi

    # Verbose output
    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "Convert command"
        log_info "  Directory:  $dir"
        log_info "  Format:     $format"
        log_info "  Bitrate:    $bitrate"
        log_info "  Output:     ${output:-converted_mp3}"
    fi

    # Set environment variables for core function
    export AUDIO_TOOLS_FORMAT="$format"
    export AUDIO_TOOLS_BITRATE="$bitrate"
    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir")
        dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi

    if [ -n "$output" ]; then
        export AUDIO_TOOLS_CONVERTED_DIR="$output"
    fi

    # Initialize output system
    init_output

    # Run the conversion (from lib/core/converter.sh)
    convert_to_mp3 "$dir" "$output"
    local status=$?

    # Output result
    if [ $status -eq 0 ]; then
        if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
            output_json "convert" "status=success" "directory=$dir" "format=$format" "bitrate=$bitrate"
        elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
            output_success "Audio conversion complete"
        fi
    else
        if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
            output_json "convert" "status=error" "directory=$dir"
        else
            output_error "Audio conversion failed"
        fi
    fi

    return $status
}

export -f cmd_convert
