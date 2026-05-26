# Audio Tools — Completion subcommand

if [ -z "$(type -t generate_completion)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../completion.sh"
fi

cmd_completion() {
    local shell="${1:-bash}"

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
Generate shell completion script

USAGE:
  audio-tools completion <bash|zsh|fish>

EXAMPLES:
  audio-tools completion bash
  audio-tools completion zsh
  audio-tools completion fish
EOF
        return 0
    fi

    case "$shell" in
        bash|zsh|fish) generate_completion "$shell" ;;
        *) log_error "Usage: audio-tools completion bash|zsh|fish"; return "$EX_USAGE" ;;
    esac
}

export -f cmd_completion
