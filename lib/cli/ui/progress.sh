# Audio Tools — Progress Indicators
# Progress bars, spinners, and status displays

# ── Spinner Animation ──

declare -g SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
declare -g SPINNER_IDX=0

# Start a spinner
# Usage: start_spinner "Loading..."
# Returns PID that can be used with stop_spinner

start_spinner() {
    local message="${1:-Processing...}"

    (
        while true; do
            printf "\r${SPINNER_FRAMES[SPINNER_IDX]} %s" "$message"
            SPINNER_IDX=$(((SPINNER_IDX + 1) % ${#SPINNER_FRAMES[@]}))
            sleep 0.1
        done
    ) &

    echo $!
}

# Stop a spinner
stop_spinner() {
    local spinner_pid="$1"
    local status="${2:-}"

    kill $spinner_pid 2>/dev/null
    wait $spinner_pid 2>/dev/null

    if [ "$status" = "success" ]; then
        echo -e "\r✓ Done"
    elif [ "$status" = "error" ]; then
        echo -e "\r✗ Failed"
    else
        echo ""
    fi
}

# ── Progress Bar ──

# Show a progress bar
# Usage: show_progress_bar 50 100 "Converting..."
# Arguments: current, total, message

show_progress_bar() {
    local current=$1
    local total=$2
    local message="${3:-Progress}"

    if [ $total -eq 0 ]; then
        total=1
    fi

    local percent=$((current * 100 / total))
    local filled=$((percent / 5))  # Divide by 5 for 20 characters
    local empty=$((20 - filled))

    printf "\r[%s%s] %3d%% (%d/%d) %s" \
        "$(printf '█%.0s' $(seq 1 $filled))" \
        "$(printf '░%.0s' $(seq 1 $empty))" \
        "$percent" "$current" "$total" "$message"
}

# ── Simple Status Indicators ──

show_status_success() {
    local message="${1:-Success}"
    printf "\r✓ %s\n" "$message"
}

show_status_error() {
    local message="${1:-Error}"
    printf "\r✗ %s\n" "$message"
}

show_status_warning() {
    local message="${1:-Warning}"
    printf "\r⚠ %s\n" "$message"
}

show_status_info() {
    local message="${1:-Info}"
    printf "\rℹ %s\n" "$message"
}

# ── Percentage Indicator ──

show_percentage() {
    local current=$1
    local total=$2
    local label="${3:-Items}"

    if [ $total -eq 0 ]; then
        return
    fi

    local percent=$((current * 100 / total))
    printf "%d%% (%d/%d %s)\n" "$percent" "$current" "$total" "$label"
}

# ── Detailed Progress ──

# Multi-line progress with details
# Usage: show_detailed_progress "Converting files" 25 100 "sample_03.wav"

show_detailed_progress() {
    local title="$1"
    local current=$2
    local total=$3
    local detail="${4:-}"

    clear
    echo "╔════════════════════════════════════════════════════╗"
    echo "║  $title"
    echo "╚════════════════════════════════════════════════════╝"
    echo ""

    show_progress_bar "$current" "$total" ""
    echo ""
    echo ""

    if [ -n "$detail" ]; then
        echo "Current: $detail"
    fi

    if [ $current -gt 0 ] && [ $total -gt 0 ]; then
        local elapsed=0  # Would need to track this elsewhere
        local rate=$((current / (elapsed + 1)))
        local remaining=$((total - current))
        local eta=$((remaining / (rate + 1)))

        echo ""
        printf "Speed: %d/sec | ETA: %ds\n" "$rate" "$eta"
    fi
}

# ── ETA Calculation ──

calculate_eta() {
    local start_time=$1
    local current=$2
    local total=$3

    if [ $current -eq 0 ] || [ $total -eq 0 ]; then
        echo "??:??"
        return
    fi

    local elapsed=$(($(date +%s) - start_time))
    [ $elapsed -eq 0 ] && elapsed=1

    local rate=$((current / elapsed))
    [ $rate -eq 0 ] && rate=1

    local remaining=$((total - current))
    local eta_seconds=$((remaining / rate))

    local minutes=$((eta_seconds / 60))
    local seconds=$((eta_seconds % 60))

    printf "%02d:%02d\n" "$minutes" "$seconds"
}

# ── Format Duration ──

format_duration_compact() {
    local seconds=$1

    if [ $seconds -lt 60 ]; then
        echo "${seconds}s"
    elif [ $seconds -lt 3600 ]; then
        local mins=$((seconds / 60))
        local secs=$((seconds % 60))
        printf "%dm %ds\n" "$mins" "$secs"
    else
        local hours=$((seconds / 3600))
        local mins=$(((seconds % 3600) / 60))
        printf "%dh %dm\n" "$hours" "$mins"
    fi
}

# ── Export ──

export -f start_spinner stop_spinner
export -f show_progress_bar
export -f show_status_success show_status_error show_status_warning show_status_info
export -f show_percentage show_detailed_progress
export -f calculate_eta format_duration_compact
