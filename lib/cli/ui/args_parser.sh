# Audio Tools — Argument Parser Helper
# Provides utilities for consistent argument parsing across commands

if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t die)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi

# ── Argument Parser ──

# Simple argument parser that handles:
# - Short flags: -d value
# - Long flags: --directory value
# - Boolean flags: --no-color
# - Positional arguments
#
# Usage:
#   parse_args "$@"
#   # $PARSED_ARGS contains remaining positional args
#   # Individual flags set variables (e.g., directory="/path")

parse_arguments() {
    local -n args_ref=$1
    shift

    PARSED_ARGS=()

    while [ $# -gt 0 ]; do
        case "$1" in
            --)
                shift
                PARSED_ARGS+=("$@")
                break
                ;;
            -*)
                # This is a flag, but we don't know what to do with it
                # Return error for caller to handle
                log_error "Unknown flag: $1"
                return "$EX_USAGE"
                ;;
            *)
                # Positional argument
                PARSED_ARGS+=("$1")
                shift
                ;;
        esac
    done

    return 0
}

# ── Flag Extraction ──

# Extract a flag value from arguments
# Usage: get_flag_value "-d" "--directory" "$@"
# Returns the value in $FLAG_VALUE, remaining args in $REMAINING_ARGS

get_flag_value() {
    local short="$1"
    local long="$2"
    shift 2

    FLAG_VALUE=""
    REMAINING_ARGS=()

    while [ $# -gt 0 ]; do
        case "$1" in
            "$short"|"$long")
                FLAG_VALUE="$2"
                shift 2
                ;;
            "$short"=*)
                FLAG_VALUE="${1#*=}"
                shift
                ;;
            "$long"=*)
                FLAG_VALUE="${1#*=}"
                shift
                ;;
            *)
                REMAINING_ARGS+=("$1")
                shift
                ;;
        esac
    done
}

# ── Common Flag Parsers ──

# Parse directory flag: -d, --directory
parse_directory_flag() {
    shift || true
    local dir=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -d|--directory)
                dir="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$dir"
}

# Parse format flag: -f, --format
parse_format_flag() {
    shift || true
    local format="mp3"

    while [ $# -gt 0 ]; do
        case "$1" in
            -f|--format)
                format="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$format"
}

# Parse bitrate flag: -b, --bitrate
parse_bitrate_flag() {
    shift || true
    local bitrate="320k"

    while [ $# -gt 0 ]; do
        case "$1" in
            -b|--bitrate)
                bitrate="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$bitrate"
}

# Parse threshold flag: -t, --threshold
parse_threshold_flag() {
    shift || true
    local threshold=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -t|--threshold)
                threshold="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$threshold"
}

# Parse query flag: -q, --query
parse_query_flag() {
    shift || true
    local query=""

    while [ $# -gt 0 ]; do
        case "$1" in
            -q|--query)
                query="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$query"
}

# Parse operation flag: -o, --operation
parse_operation_flag() {
    shift || true
    local operation="list"

    while [ $# -gt 0 ]; do
        case "$1" in
            -o|--operation)
                operation="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$operation"
}

# Parse output flag: --output
parse_output_flag() {
    shift || true
    local output=""

    while [ $# -gt 0 ]; do
        case "$1" in
            --output|-o)
                output="$2"
                shift 2
                ;;
            *)
                break
                ;;
        esac
    done

    echo "$output"
}

# ── Boolean Flag Checking ──

# Check if a boolean flag is present
# Usage: has_flag "--preview" "$@" && echo "preview enabled"

has_flag() {
    local flag="$1"
    shift

    while [ $# -gt 0 ]; do
        if [ "$1" = "$flag" ]; then
            return 0
        fi
        shift
    done

    return 1
}

# ── Export ──

export -f parse_arguments get_flag_value
export -f parse_directory_flag parse_format_flag parse_bitrate_flag
export -f parse_threshold_flag parse_query_flag parse_operation_flag parse_output_flag
export -f has_flag
