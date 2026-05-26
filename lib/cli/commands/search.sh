# Audio Tools — Search subcommand
# Find and extract/delete files by keyword

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t move_to_trash)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/trash.sh"
fi

cmd_search() {
    local query=""
    local operation="list"
    local dir="."
    local output=""

    # Check for help
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
Find and extract/delete files by keyword

USAGE:
  audio-tools search [options] <query>

OPTIONS:
  -q, --query STRING      Filename keyword (required)
  -o, --operation OP      list, extract, or delete [default: list]
  -d, --directory PATH    Target directory [default: current]
  --output PATH           Output directory for extract [default: <query>_extracted]
  -i, --ignore-case       Case-insensitive matching
  -h, --help              Show this help message

EXAMPLES:
  audio-tools search kick
  audio-tools search kick --operation extract
  audio-tools search kick --operation delete --force
EOF
        return 0
    fi

    # Parse arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -q|--query)
                query="$2"
                shift 2
                ;;
            -o|--operation)
                operation="$2"
                shift 2
                ;;
            -d|--directory)
                dir="$2"
                shift 2
                ;;
            --output)
                output="$2"
                shift 2
                ;;
            -i|--ignore-case)
                export AUDIO_TOOLS_IGNORE_CASE="yes"
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
                # Positional argument (query if not set)
                if [ -z "$query" ]; then
                    query="$1"
                else
                    dir="$1"
                fi
                shift
                ;;
        esac
    done

    # Validate required arguments
    [ -n "$query" ] || { log_error "Query is required (use: audio-tools search <query>)"; return "$EX_USAGE"; }
    [ -d "$dir" ] || { log_error "Directory not found: $dir"; return "$EX_IOERR"; }

    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "Search command"
        log_info "  Query:      $query"
        log_info "  Directory:  $dir"
        log_info "  Operation:  $operation"
    fi

    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi
    export AUDIO_TOOLS_QUERY="$query"

    # Find matching files
    local files=()
    while IFS= read -r -d '' file; do
        files+=("$file")
    done < <(search_audios "$dir" "$query" 2>/dev/null || echo "")

    if [ ${#files[@]} -eq 0 ]; then
        [ "$AUDIO_TOOLS_QUIET" != "yes" ] && log_info "No files matching '$query' found"
        return 0
    fi

    # Execute operation
    case "$operation" in
        list)
            [ "$AUDIO_TOOLS_QUIET" != "yes" ] && log_info "Found ${#files[@]} file(s) matching '$query'"
            for file in "${files[@]}"; do
                echo "  • $(basename "$file")"
            done
            if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
                printf '{"command":"search","query":"%s","operation":"list","count":%d}\n' "$query" ${#files[@]}
            fi
            ;;
        extract)
            local dest="${output:-${dir}/${query}_extracted}"
            mkdir -p "$dest"

            local extracted=0
            for file in "${files[@]}"; do
                cp "$file" "$dest/" 2>/dev/null && ((extracted++)) || true
            done

            if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
                printf '{"command":"search","query":"%s","operation":"extract","extracted":%d,"output":"%s"}\n' \
                    "$query" $extracted "$dest"
            elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
                log_info "Extracted $extracted file(s) to $dest"
            fi
            ;;
        delete)
            # Confirmation
            if [ "$AUDIO_TOOLS_FORCE" != "yes" ] && [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
                read -p "Delete ${#files[@]} file(s)? (yes/no): " response
                [ "$response" = "yes" ] || { log_info "Cancelled"; return 0; }
            fi

            local deleted=0
            for file in "${files[@]}"; do
                move_to_trash "$file" "$dir" && ((deleted++)) || true
            done

            if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
                printf '{"command":"search","query":"%s","operation":"delete","deleted":%d}\n' "$query" $deleted
            elif [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
                log_info "Deleted $deleted file(s)"
            fi
            ;;
        *)
            log_error "Invalid operation: $operation (use: list, extract, delete)"
            return "$EX_USAGE"
            ;;
    esac

    return 0
}

export -f cmd_search
