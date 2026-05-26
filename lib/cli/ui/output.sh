# Audio Tools — Output Formatting System
# Supports: text (default), json, table, tree

# Self-source dependencies
if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi

# ── Configuration ──

declare -g OUTPUT_FORMAT="${AUDIO_TOOLS_FORMAT:-text}"  # text, json, table, tree
declare -g OUTPUT_MODE="${AUDIO_TOOLS_JSON:-no}"        # yes = force json
declare -g OUTPUT_NO_COLOR="${AUDIO_TOOLS_NO_COLOR:-no}"
declare -g OUTPUT_QUIET="${AUDIO_TOOLS_QUIET:-no}"

# ── Initialize Output System ──

init_output() {
    # Determine output format
    if [ "$OUTPUT_MODE" = "yes" ]; then
        OUTPUT_FORMAT="json"
    fi

    # Disable colors if requested
    if [ "$OUTPUT_NO_COLOR" = "yes" ] || [ -n "${NO_COLOR:-}" ]; then
        # Set color vars to empty
        export COLOR_RESET=""
        export COLOR_GREEN=""
        export COLOR_YELLOW=""
        export COLOR_RED=""
        export COLOR_CYAN=""
        export COLOR_BLUE=""
    else
        export COLOR_RESET="\033[0m"
        export COLOR_GREEN="\033[0;32m"
        export COLOR_YELLOW="\033[0;33m"
        export COLOR_RED="\033[0;31m"
        export COLOR_CYAN="\033[0;36m"
        export COLOR_BLUE="\033[0;34m"
    fi
}

# ── Output Helpers ──

output_success() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        printf '{"status":"success","message":"%s"}\n' "$message"
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        echo -e "${COLOR_GREEN}✓${COLOR_RESET} $message"
    fi
}

output_error() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        printf '{"status":"error","message":"%s"}\n' "$message" >&2
    else
        echo -e "${COLOR_RED}✗${COLOR_RESET} $message" >&2
    fi
}

output_warning() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        printf '{"status":"warning","message":"%s"}\n' "$message"
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        echo -e "${COLOR_YELLOW}⚠${COLOR_RESET} $message"
    fi
}

output_info() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        return  # JSON doesn't output info
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        echo -e "${COLOR_CYAN}ℹ${COLOR_RESET} $message"
    fi
}

# ── Table Formatting ──

# Create a simple table
# Usage: output_table_header "Col1" "Col2" "Col3"
#        output_table_row "val1" "val2" "val3"
#        output_table_footer

declare -g TABLE_COLS=()
declare -g TABLE_WIDTHS=()
declare -g TABLE_ROWS=()

output_table_header() {
    TABLE_COLS=("$@")
    TABLE_ROWS=()

    if [ "$OUTPUT_FORMAT" = "json" ]; then
        return
    fi

    # Calculate column widths
    TABLE_WIDTHS=()
    for col in "${TABLE_COLS[@]}"; do
        TABLE_WIDTHS+=("${#col}")
    done

    # Print header
    local sep=""
    for ((i=0; i<${#TABLE_COLS[@]}; i++)); do
        printf "%s%-${TABLE_WIDTHS[$i]}s" "$sep" "${TABLE_COLS[$i]}"
        sep="  "
    done
    echo ""

    # Print separator
    sep=""
    for width in "${TABLE_WIDTHS[@]}"; do
        printf "%s" "$sep"
        printf '%0.s─' $(seq 1 $width)
        sep="  "
    done
    echo ""
}

output_table_row() {
    TABLE_ROWS+=("$@")

    if [ "$OUTPUT_FORMAT" = "json" ]; then
        return
    fi

    local -a row_args=("$@")

    # Update widths if needed
    for ((i=0; i<$#; i++)); do
        local val="${row_args[$i]}"
        if [ ${#val} -gt ${TABLE_WIDTHS[$i]:-0} ]; then
            TABLE_WIDTHS[$i]=${#val}
        fi
    done

    # Print row
    local sep=""
    for ((i=0; i<$#; i++)); do
        local val="${row_args[$i]}"
        printf "%s%-${TABLE_WIDTHS[$i]}s" "$sep" "$val"
        sep="  "
    done
    echo ""
}

output_table_footer() {
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        # Output as JSON array
        printf '{"columns":%s,"rows":%s}\n' \
            "$(printf '%s\n' "${TABLE_COLS[@]}" | jq -R . | jq -s .)" \
            "$(printf '%s\n' "${TABLE_ROWS[@]}" | jq -R . | jq -s .)"
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        # Print footer
        local total=0
        [ ${#TABLE_ROWS[@]} -gt 0 ] && total=${#TABLE_ROWS[@]}
        echo "Total: $total items"
    fi

    # Clear
    TABLE_COLS=()
    TABLE_WIDTHS=()
    TABLE_ROWS=()
}

# ── JSON Output Helpers ──

output_json_object() {
    local -n obj_ref=$1
    printf '{'
    local first=true
    for key in "${!obj_ref[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s":"%s"' "$key" "${obj_ref[$key]}"
    done
    printf '}\n'
}

output_json_array() {
    local -n arr_ref=$1
    printf '['
    local first=true
    for item in "${arr_ref[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s"' "$item"
    done
    printf ']\n'
}

output_json() {
    local key="$1"
    shift

    # Build JSON object from remaining args (key=value pairs)
    printf '{"'$key'":{'
    local first=true
    while [ $# -gt 0 ]; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        # Split key=value
        local kv="$1"
        local k="${kv%%=*}"
        local v="${kv#*=}"
        printf '"%s":"%s"' "$k" "$v"
        shift
    done
    printf '}}\n'
}

# ── Statistics Formatting ──

format_size() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes}B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$((bytes / 1048576))MB"
    else
        echo "$((bytes / 1073741824))GB"
    fi
}

format_duration() {
    local seconds=$1
    local hours=$((seconds / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))

    if [ $hours -gt 0 ]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [ $minutes -gt 0 ]; then
        printf "%dm %ds" $minutes $secs
    else
        printf "%ds" $secs
    fi
}

# ── File Listing Format ──

output_file_list() {
    local -n files=$1
    local format="${2:-simple}"

    case "$format" in
        simple)
            for file in "${files[@]}"; do
                echo "  • $(basename "$file")"
            done
            ;;
        table)
            output_table_header "FILENAME" "FORMAT" "SIZE" "DURATION"
            for file in "${files[@]}"; do
                local name=$(basename "$file")
                local ext="${name##*.}"
                local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "?")
                local duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file" 2>/dev/null || echo "?")
                output_table_row "$name" "$ext" "$(format_size "$size")" "$(format_duration "${duration%.*}")"
            done
            output_table_footer
            ;;
        json)
            printf '['
            local first=true
            for file in "${files[@]}"; do
                if [ "$first" = true ]; then
                    first=false
                else
                    printf ','
                fi
                printf '{"path":"%s","name":"%s"}' "$file" "$(basename "$file")"
            done
            printf ']\n'
            ;;
    esac
}

# ── Export ──

export -f init_output output_success output_error output_warning output_info
export -f output_table_header output_table_row output_table_footer
export -f output_json_object output_json_array output_json
export -f format_size format_duration output_file_list
