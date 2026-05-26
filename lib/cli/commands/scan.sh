# Audio Tools — Scan subcommand
# Consolidate audio files from subfolders into one directory

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t scan_audios_subfolders)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/organizer.sh"
fi

cmd_scan() {
    local dir="."
    local output=""
    local max_depth=""
    local preview="yes"

    # Check for help
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
Consolidate audio files from subfolders into one directory

USAGE:
  audio-tools scan [options] [directory]

OPTIONS:
  -d, --directory PATH    Source directory [default: current]
  -o, --output PATH       Output directory [default: ALL_AUDIOS]
  --max-depth N           Maximum recursion depth
  --no-preview            Don't show files before consolidating
  -h, --help              Show this help message

EXAMPLES:
  audio-tools scan
  audio-tools scan /path/to/library --output all_audio
  audio-tools scan --max-depth 2
EOF
        return 0
    fi

    # Parse arguments
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
            --max-depth)
                max_depth="$2"
                shift 2
                ;;
            --no-preview)
                preview="no"
                shift
                ;;
            -f|--force)
                # Force already in global AUDIO_TOOLS_FORCE
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
                dir="$1"
                shift
                ;;
        esac
    done

    # Validate directory
    [ -d "$dir" ] || { log_error "Directory not found: $dir"; return "$EX_IOERR"; }

    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "Scan command"
        log_info "  Directory:   $dir"
        log_info "  Output:      ${output:-ALL_AUDIOS}"
        if [ -n "$max_depth" ]; then
            log_info "  Max depth:   $max_depth"
        fi
    fi

    export AUDIO_TOOLS_DIRECTORY="$dir"
    if [ -n "$output" ]; then
        export AUDIO_TOOLS_SCAN_DIR="$output"
    fi
    if [ -n "$max_depth" ]; then
        export AUDIO_TOOLS_MAX_DEPTH="$max_depth"
    fi

    # Run scan
    scan_audios_subfolders "$dir"
    local status=$?

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"command":"scan","status":"%s","directory":"%s"}\n' \
            "$([ $status -eq 0 ] && echo 'success' || echo 'error')" "$dir"
    fi

    return $status
}

export -f cmd_scan
