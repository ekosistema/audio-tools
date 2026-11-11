# Audio Tools — Error handling & exit codes
# sysexits conventions: https://man.freebsd.org/cgi/man.cgi?query=sysexits

readonly EX_OK=0
readonly EX_USAGE=64
readonly EX_DATAERR=65
readonly EX_NOINPUT=66
readonly EX_UNAVAILABLE=69
readonly EX_IOERR=74
readonly EX_TEMPFAIL=75
readonly EX_PROTOCOL=76
readonly EX_NOPERM=77
readonly EX_CONFIG=78

die() {
    local exit_code="$1"
    local message="$2"
    echo "[FATAL] $message" >&2
    exit "$exit_code"
}

warn() {
    echo "[WARN] $1" >&2
}

# Ask a yes/no question on stderr. Returns 0 only for an answer of exactly "yes".
# --force skips the question. Unlike a bare `read`, this never hangs silently:
# when there is no input to read (CI, cron, closed stdin) it exits with a clear
# message instead of guessing an answer for a destructive action.
# Note: --quiet does NOT skip confirmation; it only hides informational output.
confirm_prompt() {
    local question="$1" response=""
    [ "${AUDIO_TOOLS_FORCE:-no}" = "yes" ] && return 0
    # A dry run changes nothing, so there is nothing to confirm
    [ "${AUDIO_TOOLS_DRY_RUN:-no}" = "yes" ] && return 0
    printf '%s (yes/no): ' "$question" >&2
    if ! IFS= read -r response; then
        printf '\n' >&2
        die "$EX_USAGE" "Confirmation required but no input is available (stdin is not interactive). Re-run with --force to proceed, or --dry-run to preview."
    fi
    [ "$response" = "yes" ]
}
