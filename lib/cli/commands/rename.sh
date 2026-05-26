# Audio Tools — Rename subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t rename_files)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/cleaner.sh"
fi

cmd_rename() {
    local dir="."

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Batch rename audio files using patterns"
        echo ""
        echo "USAGE:"
        echo "  audio-tools rename [options] [directory]"
        echo ""
        echo "OPTIONS:"
        echo "  -d, --directory PATH   Target directory [default: current]"
        echo "  -p, --pattern PAT      Rename pattern [required]"
        echo "                         Tokens: {n} {orig} {ext} {date}"
        echo "                         Example: --pattern 'track_{n}_{orig}'"
        echo "  --dry-run              Preview without renaming"
        echo "  -h, --help             Show this help message"
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            -p|--pattern) export AUDIO_TOOLS_PATTERN="$2"; shift 2 ;;
            --dry-run) export AUDIO_TOOLS_DRY_RUN="yes"; shift ;;
            --) shift; break ;;
            *) dir="$1"; shift ;;
        esac
    done

    if [ -f "$dir" ]; then
        AUDIO_TOOLS_FILES=("$dir"); dir="$(dirname "$dir")"
    else
        export AUDIO_TOOLS_DIRECTORY="$dir"
    fi

    if [ -z "${AUDIO_TOOLS_PATTERN:-}" ]; then
        log_error "Pattern (--pattern) is required."
        return "$EX_USAGE"
    fi

    rename_files "$dir"
}

export -f cmd_rename
