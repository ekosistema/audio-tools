# Audio Tools — Remove subcommand
# Remove short or long audio files

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t move_to_trash)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/trash.sh"
fi

cmd_remove() {
    local subcommand="${1:-}"

    # Check for help on main command
    if [ "$subcommand" = "-h" ] || [ "$subcommand" = "--help" ]; then
        cat << 'EOF'
Remove short or long audio files

USAGE:
  audio-tools remove <short|long> [options] [directory]

SUBCOMMANDS:
  short          Remove files shorter than threshold
  long           Remove files longer than threshold

OPTIONS:
  -t, --threshold SECONDS Minimum/maximum duration (required)
  -d, --directory PATH    Target directory [default: current]
  -h, --help              Show this help message

EXAMPLES:
  audio-tools remove short --threshold 2
  audio-tools remove long --threshold 30 /path/to/audio
  audio-tools remove short --threshold 1 --force
EOF
        return 0
    fi

    shift || true

    case "$subcommand" in
        short)
            _remove_short "$@"
            ;;
        long)
            _remove_long "$@"
            ;;
        *)
            log_error "Usage: audio-tools remove <short|long> [options] [directory]"
            return "$EX_USAGE"
            ;;
    esac
}

_remove_short() {
    local dir="."
    local threshold=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -t|--threshold)
                threshold="$2"
                shift 2
                ;;
            -d|--directory)
                dir="$2"
                shift 2
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

    [ -n "$threshold" ] || { log_error "Threshold (--threshold) is required"; return "$EX_USAGE"; }
    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    fi
    [ -d "$dir" ] || { log_error "Directory not found: $dir"; return "$EX_IOERR"; }

    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "Remove short command"
        log_info "  Directory:  $dir"
        log_info "  Threshold:  $threshold seconds"
    fi

    export AUDIO_TOOLS_DIRECTORY="$dir"
    export AUDIO_TOOLS_THRESHOLD="$threshold"

    # Find short files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(get_short_files "$dir" "$threshold" 2>/dev/null || echo "")

    if [ ${#files[@]} -eq 0 ]; then
        [ "$AUDIO_TOOLS_QUIET" != "yes" ] && log_info "No short files found"
        return 0
    fi

    # Confirmation
    if [ "$AUDIO_TOOLS_FORCE" != "yes" ] && [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        read -p "Delete ${#files[@]} short files? (yes/no): " response
        [ "$response" = "yes" ] || { log_info "Cancelled"; return 0; }
    fi

    # Delete files
    local deleted=0
    for file in "${files[@]}"; do
        move_to_trash "$file" "$dir" && ((deleted++)) || true
    done

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"command":"remove","type":"short","files":%d,"deleted":%d}\n' ${#files[@]} $deleted
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        log_info "Deleted $deleted short files"
    fi

    return 0
}

_remove_long() {
    local dir="."
    local threshold=""

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -t|--threshold)
                threshold="$2"
                shift 2
                ;;
            -d|--directory)
                dir="$2"
                shift 2
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

    [ -n "$threshold" ] || { log_error "Threshold (--threshold) is required"; return "$EX_USAGE"; }
    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    fi
    [ -d "$dir" ] || { log_error "Directory not found: $dir"; return "$EX_IOERR"; }

    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "Remove long command"
        log_info "  Directory:  $dir"
        log_info "  Threshold:  $threshold seconds"
    fi

    export AUDIO_TOOLS_DIRECTORY="$dir"
    export AUDIO_TOOLS_THRESHOLD="$threshold"

    # Find long files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(get_long_files "$dir" "$threshold" 2>/dev/null || echo "")

    if [ ${#files[@]} -eq 0 ]; then
        [ "$AUDIO_TOOLS_QUIET" != "yes" ] && log_info "No long files found"
        return 0
    fi

    # Confirmation
    if [ "$AUDIO_TOOLS_FORCE" != "yes" ] && [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        read -p "Delete ${#files[@]} long files? (yes/no): " response
        [ "$response" = "yes" ] || { log_info "Cancelled"; return 0; }
    fi

    # Delete files
    local deleted=0
    for file in "${files[@]}"; do
        move_to_trash "$file" "$dir" && ((deleted++)) || true
    done

    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        printf '{"command":"remove","type":"long","files":%d,"deleted":%d}\n' ${#files[@]} $deleted
    elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
        log_info "Deleted $deleted long files"
    fi

    return 0
}

export -f cmd_remove _remove_short _remove_long
