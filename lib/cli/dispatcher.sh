# Audio Tools — Subcommand Dispatcher
# Routes commands like `audio-tools convert`, `audio-tools clean`, etc.

# Self-source dependencies
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t die)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi

# ── Global State ──

# Global flags (parsed before subcommand)
declare -g AUDIO_TOOLS_QUIET="no"
declare -g AUDIO_TOOLS_VERBOSE="no"
declare -g AUDIO_TOOLS_NO_COLOR="no"
declare -g AUDIO_TOOLS_JSON="no"
declare -g AUDIO_TOOLS_DRY_RUN="no"
declare -g AUDIO_TOOLS_CONFIG=""
declare -g AUDIO_TOOLS_FORCE="no"

# Subcommand info
declare -g AUDIO_TOOLS_SUBCOMMAND=""
declare -g AUDIO_TOOLS_REMAINING_ARGS=()

# ── Flag Parsing ──

parse_global_flags() {
    local parsed_count=0
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -V|--version)
                show_version
                exit 0
                ;;
            -q|--quiet)
                AUDIO_TOOLS_QUIET="yes"; parsed_count=$((parsed_count + 1)); shift
                ;;
            -v|--verbose)
                AUDIO_TOOLS_VERBOSE="yes"; parsed_count=$((parsed_count + 1)); shift
                ;;
            --no-color)
                AUDIO_TOOLS_NO_COLOR="yes"; parsed_count=$((parsed_count + 1)); shift
                ;;
            --json)
                AUDIO_TOOLS_JSON="yes"; parsed_count=$((parsed_count + 1)); shift
                ;;
            --dry-run)
                AUDIO_TOOLS_DRY_RUN="yes"; parsed_count=$((parsed_count + 1)); shift
                ;;
            -C|--config)
                AUDIO_TOOLS_CONFIG="$2"; parsed_count=$((parsed_count + 1)); shift 2
                ;;
            -f|--force)
                AUDIO_TOOLS_FORCE="yes"; parsed_count=$((parsed_count + 1)); shift
                ;;
            --no-force)
                AUDIO_TOOLS_FORCE="no"; parsed_count=$((parsed_count + 1)); shift
                ;;
            -*)
                break
                ;;
            *)
                AUDIO_TOOLS_SUBCOMMAND="$1"
                shift
                break
                ;;
        esac
    done

    AUDIO_TOOLS_REMAINING_ARGS=("$@")
    AUDIO_TOOLS_PARSE_COUNT="$parsed_count"

    return 0
}

# ── Dispatcher ──

dispatch_command() {
    local cmd="$AUDIO_TOOLS_SUBCOMMAND"
    local cmd_file="$(dirname "${BASH_SOURCE[0]}")/commands/${cmd}.sh"

    # Legacy support: translate --action convert → convert subcommand
    if [ -z "$cmd" ] && [ -n "${AUDIO_TOOLS_COMMAND:-}" ]; then
        log_warn "Using --action is deprecated; use 'audio-tools <command>' instead"
        cmd="$AUDIO_TOOLS_COMMAND"
        cmd_file="$(dirname "${BASH_SOURCE[0]}")/commands/${cmd}.sh"
    fi

    # Handle missing command
    if [ -z "$cmd" ]; then
        local first_arg="${AUDIO_TOOLS_REMAINING_ARGS[0]:-}"
        if [ -n "$first_arg" ]; then
            if [[ "$first_arg" == -* ]]; then
                log_error "Unknown option: $first_arg"
                return "$EX_USAGE"
            fi
            log_error "Unknown command: $first_arg"
            return "$EX_USAGE"
        fi
        # All args were consumed as global flags → show help
        if [ "${AUDIO_TOOLS_PARSE_COUNT:-0}" -gt 0 ]; then
            show_help
            return 0
        fi
        return 3  # Signal to caller: show interactive menu
    fi

    # Check if command file exists
    if [ ! -f "$cmd_file" ]; then
        log_error "Unknown command: $cmd"
        log_info "Run 'audio-tools --help' to see available commands"
        return "$EX_USAGE"
    fi

    # Source and execute command
    source "$cmd_file"

    # Each command file should define a function: cmd_<command>()
    local cmd_func="cmd_${cmd//-/_}"
    if ! declare -f "$cmd_func" >/dev/null 2>&1; then
        log_error "Command '$cmd' is malformed (missing $cmd_func function)"
        return "$EX_USAGE"
    fi

    # Execute the command with remaining args
    "$cmd_func" "${AUDIO_TOOLS_REMAINING_ARGS[@]}"
}

# ── Environment Setup ──

setup_environment() {
    # Respect NO_COLOR env var
    if [ -n "${NO_COLOR:-}" ]; then
        AUDIO_TOOLS_NO_COLOR="yes"
    fi

    # Disable colors if not a TTY (piped output)
    if [ ! -t 1 ]; then
        AUDIO_TOOLS_NO_COLOR="yes"
    fi

    # If json mode requested, silence colored output
    if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
        AUDIO_TOOLS_NO_COLOR="yes"
    fi

    # Export global state so sourced commands can access it
    export AUDIO_TOOLS_QUIET
    export AUDIO_TOOLS_VERBOSE
    export AUDIO_TOOLS_NO_COLOR
    export AUDIO_TOOLS_JSON
    export AUDIO_TOOLS_DRY_RUN
    export AUDIO_TOOLS_CONFIG
    export AUDIO_TOOLS_FORCE
}

# ── Validation ──

validate_dispatch() {
    if [ "$AUDIO_TOOLS_QUIET" = "yes" ] && [ "$AUDIO_TOOLS_VERBOSE" = "yes" ]; then
        log_warn "Both --quiet and --verbose set; --verbose takes precedence"
        AUDIO_TOOLS_QUIET="no"
    fi
    return 0
}

# ── Main Entry ──

# Usage: dispatch "$@"
# Parses args, sets up environment, and dispatches to subcommand
dispatch() {
    parse_global_flags "$@"

    setup_environment
    validate_dispatch || return $?
    dispatch_command
}
