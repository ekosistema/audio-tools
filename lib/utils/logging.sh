# Audio Tools — Logging & styling
# Colors disabled when stderr is not a tty, or NO_COLOR is set
# Info/warn suppressed when AUDIO_TOOLS_QUIET=yes

if [ -t 2 ] && [ -z "${NO_COLOR:-}" ]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[0;33m'
    readonly BOLD='\033[1m'
    readonly DIM='\033[2m'
    readonly BRIGHT_WHITE='\033[1;37m'
    readonly GRAY='\033[0;37m'
    readonly DARK_GRAY='\033[1;90m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BOLD=''
    readonly DIM=''
    readonly BRIGHT_WHITE=''
    readonly GRAY=''
    readonly DARK_GRAY=''
    readonly NC=''
fi

log_info() {
    [ "${AUDIO_TOOLS_QUIET:-no}" = "yes" ] && return 0
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    [ "${AUDIO_TOOLS_QUIET:-no}" = "yes" ] && return 0
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

styled_echo() {
    local style="$1"
    shift
    echo -e "${style}$*${NC}"
}
