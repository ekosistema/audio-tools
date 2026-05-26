# Audio Tools — Dedup subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t audio_dedup)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/deduper.sh"
fi

cmd_dedup() {
    local dir="."

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Remove exact duplicate audio files by SHA256"
        echo ""
        echo "USAGE:"
        echo "  audio-tools dedup [options] [directory]"
        echo ""
        echo "OPTIONS:"
        echo "  -d, --directory PATH   Directory to scan [default: current]"
        echo "  -f, --force            Skip confirmation prompt"
        echo "  --dry-run              Preview without deleting"
        echo "  -h, --help             Show this help message"
        echo ""
        echo "NOTES:"
        echo "  Duplicates are moved to trash (not permanently deleted)."
        echo "  The first file found is kept; subsequent duplicates are trashed."
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            -f|--force) export AUDIO_TOOLS_FORCE="yes"; shift ;;
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
    audio_dedup "$dir"
}

export -f cmd_dedup
