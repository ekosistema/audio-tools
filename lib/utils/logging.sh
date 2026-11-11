# Audio Tools — Logging & colors
#
# One palette for the whole tool. Colors are decided per stream, so piping stdout
# (`audio-tools list | less`) never leaks escape codes even when stderr is a terminal.
#
#   RED GREEN YELLOW CYAN BLUE MAGENTA BOLD DIM BRIGHT_WHITE GRAY DARK_GRAY NC
#       for text written to stdout (menus, tables, reports)
#   E_RED E_GREEN E_YELLOW E_CYAN E_BOLD E_DIM E_NC
#       for text written to stderr (log lines, progress, prompts)
#
# Color is OFF when any of these holds (first match wins):
#   NO_COLOR is set (https://no-color.org), --no-color / AUDIO_TOOLS_NO_COLOR=yes,
#   --json, TERM=dumb, AUDIO_TOOLS_COLOR=never / --color=never.
# Color is ON for a stream that is a terminal, or everywhere with
# AUDIO_TOOLS_COLOR=always / --color=always / CLICOLOR_FORCE=1.
#
# Values are literal "\033[..m" text, to be printed with `echo -e` or `printf %b`.
# Call init_colors again after the flags are parsed (the dispatcher does).

# Is color allowed for file descriptor $1 (1 = stdout, 2 = stderr)?
_color_wanted() {
    [ -z "${NO_COLOR:-}" ] || return 1
    [ "${AUDIO_TOOLS_NO_COLOR:-no}" != "yes" ] || return 1
    [ "${AUDIO_TOOLS_JSON:-no}" != "yes" ] || return 1
    [ "${TERM:-}" != "dumb" ] || return 1
    case "${AUDIO_TOOLS_COLOR:-auto}" in
        never)  return 1 ;;
        always) return 0 ;;
    esac
    if [ -n "${CLICOLOR_FORCE:-}" ] && [ "${CLICOLOR_FORCE}" != "0" ]; then return 0; fi
    [ -t "$1" ]
}

init_colors() {
    if _color_wanted 1; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        BRIGHT_WHITE='\033[1;37m'
        GRAY='\033[0;37m'
        DARK_GRAY='\033[1;90m'
        NC='\033[0m'
    else
        RED=''; GREEN=''; YELLOW=''; BLUE=''; MAGENTA=''; CYAN=''
        BOLD=''; DIM=''; BRIGHT_WHITE=''; GRAY=''; DARK_GRAY=''; NC=''
    fi

    if _color_wanted 2; then
        E_RED='\033[1;31m'
        E_GREEN='\033[0;32m'
        E_YELLOW='\033[0;33m'
        E_CYAN='\033[0;36m'
        E_BOLD='\033[1m'
        E_DIM='\033[2m'
        E_NC='\033[0m'
    else
        E_RED=''; E_GREEN=''; E_YELLOW=''; E_CYAN=''; E_BOLD=''; E_DIM=''; E_NC=''
    fi
}

init_colors

# Info/warn are suppressed when AUDIO_TOOLS_QUIET=yes. The message is printed
# verbatim (never interpreted as a format or escape sequence).
log_info() {
    [ "${AUDIO_TOOLS_QUIET:-no}" = "yes" ] && return 0
    printf '%b%s\n' "${E_CYAN}[INFO]${E_NC} " "$1" >&2
}

log_warn() {
    [ "${AUDIO_TOOLS_QUIET:-no}" = "yes" ] && return 0
    printf '%b%s\n' "${E_YELLOW}[WARN]${E_NC} " "$1" >&2
}

log_error() { printf '%b%s\n' "${E_RED}[ERROR]${E_NC} " "$1" >&2; }

# Print "$*" in the given style (a palette variable such as "$BOLD").
styled_echo() {
    local style="$1"
    shift
    echo -e "${style}$*${NC}"
}

# Clear the screen only on a real terminal, and never fail: plain `clear` returns 1
# when TERM is unset or "dumb" (CI, containers, cron), which aborts a `set -e` script.
ui_clear() {
    if [ -t 1 ] && [ -n "${TERM:-}" ] && [ "${TERM}" != "dumb" ]; then
        clear 2>/dev/null || true
    fi
}
