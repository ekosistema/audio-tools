# Audio Tools — Split Silence subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t audio_split_silence)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/processor.sh"
fi

cmd_split_silence() {
    local file=""

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        echo "Split audio file at silence points into separate files"
        echo ""
        echo "USAGE:"
        echo "  audio-tools split-silence [options] <file>"
        echo ""
        echo "OPTIONS:"
        echo "  --dry-run              Preview without modifying"
        echo "  -h, --help             Show this help message"
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --dry-run) export AUDIO_TOOLS_DRY_RUN="yes"; shift ;;
            --) shift; break ;;
            -*) log_error "Unknown option: $1"; return "$EX_USAGE" ;;
            *) file="$1"; shift ;;
        esac
    done

    if [ -z "$file" ]; then
        log_error "Usage: audio-tools split-silence <file>"
        return "$EX_USAGE"
    fi

    audio_split_silence "$file"
}

export -f cmd_split_silence
