# Audio Tools — List subcommand
# List audio files with metadata and optional formatting

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t resolve_audio_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../io/filesystem.sh"
fi
if [ -z "$(type -t init_output)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../ui/output.sh"
fi

cmd_list() {
    local dir="."
    local format="simple"
    local recursive="yes"
    local preview="no"

    # Check for help
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
List audio files in a directory

USAGE:
  audio-tools list [options] [directory]

OPTIONS:
  -d, --directory PATH    Directory to scan [default: current]
  --format FMT           Output format [default: simple]
                        Options: simple, table, tree, json
  --no-recursive         Don't scan subdirectories
  -p, --preview          Show detailed metadata
  -h, --help             Show this help message

EXAMPLES:
  audio-tools list
  audio-tools list /path/to/audio --format table
  audio-tools list --json | jq '.files[] | select(.size > 1000000)'
EOF
        return 0
    fi

    # Parse arguments
    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--directory)
                dir="$2"
                shift 2
                ;;
            --format)
                format="$2"
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

    # Initialize output
    init_output

    if [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_info "List command"
        log_info "  Directory:  $dir"
        log_info "  Format:     $format"
    fi

    # Collect files
    local files=()
    local total_size=0
    local total_duration=0

    while IFS= read -r -d '' file; do
        files+=("$file")

        # Get file size
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
        total_size=$((total_size + size))

        # Get duration (if ffprobe available)
        if command -v ffprobe >/dev/null 2>&1; then
            local duration=$(ffprobe -v error -show_entries format=duration \
                -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo 0)
            total_duration=$(echo "$total_duration + ${duration%.*}" | bc)
        fi
    done < <(resolve_audio_files "$dir")

    # Output results
    case "$format" in
        simple)
            if [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
                echo "Audio files in: $dir"
                echo ""
            fi
            for file in "${files[@]}"; do
                echo "  • $(basename "$file")"
            done
            if [ "$AUDIO_TOOLS_QUIET" != "yes" ]; then
                echo ""
                echo "Total: ${#files[@]} files | Size: $(format_size "$total_size") | Duration: $(format_duration "$total_duration")"
            fi
            ;;

        table)
            if [ "$preview" = "yes" ]; then
                output_table_header "FILENAME" "FORMAT" "SIZE" "DURATION" "BITRATE" "CODEC"
            else
                output_table_header "FILENAME" "FORMAT" "SIZE" "DURATION"
            fi
            for file in "${files[@]}"; do
                local name=$(basename "$file")
                local ext="${name##*.}"
                local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)

                local duration="?"
                local bitrate=""
                local codec=""
                if command -v ffprobe >/dev/null 2>&1; then
                    local info=$(ffprobe -v error -show_entries \
                        "format=duration,bit_rate stream=codec_name" \
                        -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
                    local dur_line bit_line codec_line
                    dur_line=$(echo "$info" | head -1)
                    bit_line=$(echo "$info" | sed -n '2p')
                    codec_line=$(echo "$info" | sed -n '5p')
                    duration=$(format_duration "${dur_line%.*}")
                    [ -n "$bit_line" ] && [ "$bit_line" != "N/A" ] && bitrate="$((bit_line / 1000))k" || bitrate="?"
                    codec="${codec_line:-?}"
                fi

                if [ "$preview" = "yes" ]; then
                    output_table_row "$name" "$ext" "$(format_size "$size")" "$duration" "$bitrate" "$codec"
                else
                    output_table_row "$name" "$ext" "$(format_size "$size")" "$duration"
                fi
            done
            output_table_footer
            ;;

        tree)
            echo "$(basename "$dir")/"
            for file in "${files[@]}"; do
                local rel_path="${file#$dir/}"
                echo "  ├── $rel_path"
            done
            echo ""
            ;;

        json)
            printf '{'
            printf '"directory":"%s",' "$dir"
            printf '"files":['
            local first=true
            for file in "${files[@]}"; do
                local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo 0)
                local duration=0
                local bitrate=""
                local codec=""
                local format_name=""
                if command -v ffprobe >/dev/null 2>&1; then
                    local info=$(ffprobe -v error -show_entries \
                        "format=duration,bit_rate,format_name stream=codec_name" \
                        -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null)
                    duration=$(echo "$info" | sed -n '1p' || echo 0)
                    bitrate=$(echo "$info" | sed -n '2p' || echo "")
                    format_name=$(echo "$info" | sed -n '3p' || echo "")
                    codec=$(echo "$info" | sed -n '5p' || echo "")
                fi

                if [ "$first" = true ]; then
                    first=false
                else
                    printf ','
                fi

                printf '{"path":"%s","name":"%s","size":%d,"duration":%.2f,"bitrate":"%s","codec":"%s","format":"%s"}' \
                    "$file" "$(basename "$file")" "$size" "$duration" \
                    "$bitrate" "$codec" "$format_name"
            done
            printf '],'
            printf '"summary":{"total":%d,"size":%d,"duration":%d}' \
                "${#files[@]}" "$total_size" "$total_duration"
            printf '}\n'
            ;;

        *)
            log_error "Unknown format: $format"
            return "$EX_USAGE"
            ;;
    esac

    return 0
}

export -f cmd_list
