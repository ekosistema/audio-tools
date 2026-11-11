# Audio Tools — Progress bar (compact single-line progress)
# Everything goes to stderr, so stdout stays clean for data and pipes.

_PROGRESS_TOTAL=0
_PROGRESS_CURRENT=0
_PROGRESS_LABEL=""
_PROGRESS_ACTIVE=no
_PROGRESS_TTY=no
_PROGRESS_COLS=80

_init_progress_tty() {
    _PROGRESS_TTY=no
    _PROGRESS_COLS=80
    if [ -t 2 ] && [ "${AUDIO_TOOLS_PROGRESS:-yes}" = "yes" ] && [ "${AUDIO_TOOLS_QUIET:-no}" = "no" ]; then
        _PROGRESS_TTY=yes
        _PROGRESS_COLS=$(tput cols 2>/dev/null || echo 80)
    fi
}

init_progress() {
    _PROGRESS_TOTAL="${1:-0}"
    _PROGRESS_LABEL="${2:-Processing}"
    _PROGRESS_CURRENT=0
    _init_progress_tty
    _PROGRESS_ACTIVE=yes
}

update_progress() {
    _PROGRESS_CURRENT=$((_PROGRESS_CURRENT + 1))
    [ "$_PROGRESS_ACTIVE" != "yes" ] && return
    local cur=$_PROGRESS_CURRENT total=$_PROGRESS_TOTAL
    local file="${1:-}"
    local base; base=$(basename "$file")

    if [ "$_PROGRESS_TTY" = "yes" ]; then
        # "  (3/10) name.wav": counter in cyan, file name dim, truncated to the terminal width
        local counter="($cur/$total)"
        local room=$(( _PROGRESS_COLS - 2 - ${#counter} - 1 - 2 ))
        [ "$room" -lt 4 ] && room=4
        if [ ${#base} -gt "$room" ]; then
            base="${base:0:$((room - 3))}..."
        fi
        local used=$(( 2 + ${#counter} + 1 + ${#base} ))
        printf '\r  %b%s%b %b%s%b%*s' "$E_CYAN" "$counter" "$E_NC" "$E_DIM" "$base" "$E_NC" \
            "$(( _PROGRESS_COLS - used > 0 ? _PROGRESS_COLS - used : 0 ))" "" >&2
    elif [ "${AUDIO_TOOLS_QUIET:-no}" = "no" ]; then
        echo "  ($cur/$total) $base" >&2
    fi
}

finish_progress() {
    local ok="${1:-$_PROGRESS_CURRENT}"
    local errors="${2:-0}"
    local summary="${3:-$_PROGRESS_LABEL}"
    [ "$_PROGRESS_ACTIVE" != "yes" ] && return
    _PROGRESS_ACTIVE=no

    if [ "$_PROGRESS_TTY" = "yes" ]; then
        local text="($ok/$_PROGRESS_TOTAL) $summary"
        local pad=$(( _PROGRESS_COLS - 4 - ${#text} ))
        [ "$pad" -lt 0 ] && pad=0
        printf '\r  %b✓%b %s%*s\n' "$E_GREEN" "$E_NC" "$text" "$pad" "" >&2
    elif [ "${AUDIO_TOOLS_QUIET:-no}" = "no" ]; then
        echo "  ✓ ($ok/$_PROGRESS_TOTAL) $summary" >&2
    fi
    if [ "$errors" -gt 0 ]; then
        log_error "  $errors file(s) failed"
        return 1
    fi
    return 0
}
