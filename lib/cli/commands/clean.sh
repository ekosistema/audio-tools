# Audio Tools — Clean subcommand
# Sanitizes filenames (remove spaces, special chars)

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t clean_filenames)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/cleaner.sh"
fi

cmd_clean() {
    local dir="."
    local pattern="[^a-zA-Z0-9._-]"
    local replacement="_"
    local preview="yes"

    # Check for help
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
Sanitize filenames (remove spaces, special characters)

USAGE:
  audio-tools clean [options] [directory]

OPTIONS:
  -d, --directory PATH    Target directory [default: current]
  -p, --pattern REGEX     Characters to remove [default: [^a-zA-Z0-9._-]]
  --replacement CHAR      Replacement character [default: _]
  --no-preview            Don't show changes before applying
  -h, --help              Show this help message

EXAMPLES:
  audio-tools clean /path/to/files
  audio-tools clean --pattern '[^a-zA-Z0-9]'
  audio-tools clean --replacement '-'
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
            -p|--pattern)
                pattern="$2"
                shift 2
                ;;
            --replacement)
                replacement="$2"
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

    if [ ! -d "$dir" ] && [ ! -f "$dir" ]; then
        log_error "Path not found: $dir"
        return "$EX_IOERR"
    fi

    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "Clean command"
        log_info "  Directory:    $dir"
        log_info "  Pattern:      $pattern"
        log_info "  Replacement:  '$replacement'"
    fi

    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi
    export AUDIO_TOOLS_PATTERN="$pattern"

    clean_filenames "$dir"
    local status=$?

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"command":"clean","status":"%s","directory":"%s"}\n' \
            "$([ $status -eq 0 ] && echo 'success' || echo 'error')" "$dir"
    fi

    return $status
}

export -f cmd_clean
