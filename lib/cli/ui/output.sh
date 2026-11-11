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

# ── JSON primitives ──
# Pure bash (no jq dependency). Every JSON string emitted by audio-tools goes
# through json_escape so quotes, backslashes and control characters in file
# names can never produce invalid JSON.

# Print $1 escaped for use INSIDE a JSON string (no surrounding quotes).
json_escape() {
    # C locale: [[:cntrl:]] must only match ASCII controls, never UTF-8 bytes
    local LC_ALL=C
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\b'/\\b}"
    s="${s//$'\f'/\\f}"
    if [[ "$s" =~ [[:cntrl:]] ]]; then
        local out="" ch i code
        for ((i = 0; i < ${#s}; i++)); do
            ch="${s:i:1}"
            printf -v code '%d' "'$ch"
            # Only ASCII controls (and DEL) are escaped; bytes >= 0x80 pass through
            if [ "$code" -ge 0 ] && { [ "$code" -lt 32 ] || [ "$code" -eq 127 ]; }; then
                printf -v ch '\\u%04x' "$code"
            fi
            out+="$ch"
        done
        s="$out"
    fi
    printf '%s' "$s"
}

# Print $1 as a quoted JSON string.
json_string() { printf '"%s"' "$(json_escape "$1")"; }

# Print $1 as a JSON number, or null when it is not a plain non-negative number.
json_number() {
    case "$1" in
        ''|*[!0-9.]*|*.*.*|.|.*|*.) printf 'null' ;;
        *) printf '%s' "$1" ;;
    esac
}

# ── Output Helpers ──

_output_status_json() {
    printf '{"status":"%s","message":%s}\n' "$1" "$(json_string "$2")"
}

output_success() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        _output_status_json success "$message"
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        printf '%b%s\n' "${COLOR_GREEN}✓${COLOR_RESET} " "$message"
    fi
}

output_error() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        _output_status_json error "$message" >&2
    else
        printf '%b%s\n' "${COLOR_RED}✗${COLOR_RESET} " "$message" >&2
    fi
}

output_warning() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        _output_status_json warning "$message"
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        printf '%b%s\n' "${COLOR_YELLOW}⚠${COLOR_RESET} " "$message"
    fi
}

output_info() {
    local message="$1"
    if [ "$OUTPUT_FORMAT" = "json" ]; then
        return  # JSON doesn't output info
    elif [ "$OUTPUT_QUIET" != "yes" ]; then
        printf '%b%s\n' "${COLOR_CYAN}ℹ${COLOR_RESET} " "$message"
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
        printf '%0.s─' $(seq 1 "$width")
        sep="  "
    done
    echo ""
}

output_table_row() {
    # One entry per row, cells joined by the ASCII unit separator
    local _row
    printf -v _row '%s\x1f' "$@"
    TABLE_ROWS+=("${_row%$'\x1f'}")

    if [ "$OUTPUT_FORMAT" = "json" ]; then
        return
    fi

    local -a row_args=("$@")

    # Update widths if needed
    for ((i=0; i<$#; i++)); do
        local val="${row_args[$i]}"
        if [ ${#val} -gt "${TABLE_WIDTHS[i]:-0}" ]; then
            TABLE_WIDTHS[i]=${#val}
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
        # {"columns":[...],"rows":[[cell,...],...]}
        local col row cell sep="" rsep="" cells
        printf '{"columns":['
        for col in "${TABLE_COLS[@]}"; do
            printf '%s%s' "$sep" "$(json_string "$col")"; sep=","
        done
        printf '],"rows":['
        for row in "${TABLE_ROWS[@]}"; do
            printf '%s[' "$rsep"; rsep=","; sep=""
            IFS=$'\x1f' read -r -a cells <<< "$row"
            for cell in "${cells[@]}"; do
                printf '%s%s' "$sep" "$(json_string "$cell")"; sep=","
            done
            printf ']'
        done
        printf ']}\n'
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
        printf '%s:%s' "$(json_string "$key")" "$(json_string "${obj_ref[$key]}")"
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
        json_string "$item"
    done
    printf ']\n'
}

output_json() {
    local key="$1"
    shift

    # Build JSON object from remaining args (key=value pairs)
    printf '{%s:{' "$(json_string "$key")"
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
        printf '%s:%s' "$(json_string "$k")" "$(json_string "$v")"
        shift
    done
    printf '}}\n'
}

# ── Statistics Formatting ──

format_size() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$((bytes / 1024))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
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

    if [ "$hours" -gt 0 ]; then
        printf "%dh %dm %ds" $hours $minutes $secs
    elif [ "$minutes" -gt 0 ]; then
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
                printf '{"path":%s,"name":%s}' "$(json_string "$file")" "$(json_string "$(basename "$file")")"
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
