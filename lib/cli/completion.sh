# Audio Tools — Shell completion generator

generate_completion() {
    local shell="$1"
    case "$shell" in
        bash) _completion_bash ;;
        zsh)  _completion_zsh ;;
        fish) _completion_fish ;;
    esac
}

_completion_bash() {
    cat <<'BASH'
_audio_tools_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ $COMP_CWORD -eq 1 ]; then
        COMPREPLY=($(compgen -W "convert normalize trim-silence split-silence concat clean rename remove scan list stats info search config completion find-dupes dedup" -- "$cur"))
        return 0
    fi

    # Handle subcommands for 'remove'
    if [ "${COMP_WORDS[1]}" = "remove" ] && [ $COMP_CWORD -eq 2 ]; then
        COMPREPLY=($(compgen -W "short long" -- "$cur"))
        return 0
    fi

    case "${COMP_WORDS[1]}" in
        remove)
            case "$prev" in
                --threshold|-t)
                    COMPREPLY=(())
                    return 0
                    ;;
            esac
            COMPREPLY=($(compgen -W "--threshold --force --quiet --verbose --json" -- "$cur"))
            ;;
        convert|clean)
            case "$prev" in
                --format|-f|--bitrate|-b|--output|-o)
                    COMPREPLY=(())
                    return 0
                    ;;
            esac
            COMPREPLY=($(compgen -W "--format --bitrate --output --force --quiet --verbose --json --dry-run" -- "$cur"))
            ;;
        normalize|trim-silence|concat)
            COMPREPLY=($(compgen -W "--force --quiet --verbose --json --dry-run" -- "$cur"))
            ;;
        split-silence)
            COMPREPLY=($(compgen -W "--force --quiet --verbose --json --dry-run" -- "$cur"))
            ;;
        rename)
            case "$prev" in
                --pattern|-p)
                    COMPREPLY=(())
                    return 0
                    ;;
            esac
            COMPREPLY=($(compgen -W "--pattern --force --quiet --verbose --json --dry-run" -- "$cur"))
            ;;
        dedup|find-dupes)
            COMPREPLY=($(compgen -W "--force --quiet --verbose --json --dry-run" -- "$cur"))
            ;;
        search)
            case "$prev" in
                --operation|-o)
                    COMPREPLY=($(compgen -W "delete extract list" -- "$cur"))
                    return 0
                    ;;
            esac
            COMPREPLY=($(compgen -W "--query --operation --force --quiet --verbose --json" -- "$cur"))
            ;;
        scan|list|stats)
            COMPREPLY=($(compgen -W "--format --quiet --verbose --json" -- "$cur"))
            ;;
        config)
            if [ $COMP_CWORD -eq 2 ]; then
                COMPREPLY=($(compgen -W "get set list edit reset path" -- "$cur"))
                return 0
            fi
            ;;
        info)
            COMPREPLY=($(compgen -W "--format --quiet --verbose --json" -- "$cur"))
            ;;
        completion)
            COMPREPLY=($(compgen -W "bash zsh fish" -- "$cur"))
            ;;
    esac
}
complete -F _audio_tools_complete audio-tools
BASH
}

_completion_zsh() {
    cat <<'ZSH'
#compdef audio-tools

_audio_tools() {
    local -a commands subcommands_remove
    commands=(
        'convert:Convert audio files to another format'
        'normalize:Normalize loudness (EBU R128 -16 LUFS)'
        'trim-silence:Remove leading/trailing silence'
        'split-silence:Split audio at silence points'
        'concat:Concatenate multiple audio files'
        'clean:Sanitize filenames (remove spaces & special chars)'
        'rename:Batch rename with patterns'
        'remove:Remove audio files by condition'
        'scan:Consolidate audio from subfolders'
        'list:List audio files with metadata'
        'stats:Aggregate directory statistics'
        'info:Display audio file metadata'
        'search:Find and process audio files by keyword'
        'config:Manage configuration'
        'completion:Generate shell completion script'
        'find-dupes:Find duplicates by SHA256 (keep files)'
        'dedup:Remove exact duplicates by SHA256'
    )

    subcommands_remove=(
        'short:Remove files shorter than threshold'
        'long:Remove files longer than threshold'
    )

    case $state in
        command)
            _describe 'command' commands
            ;;
        subcommand)
            case "${words[2]}" in
                remove)
                    _describe 'remove subcommand' subcommands_remove
                    ;;
            esac
            ;;
    esac
}

_audio_tools
ZSH
}

_completion_fish() {
    cat <<'FISH'
complete -c audio-tools -f

# Subcommands
complete -c audio-tools -n "test (count (commandline -opc)) -eq 1" \
    -a "convert normalize trim-silence split-silence concat clean rename remove scan list stats info search config completion find-dupes dedup"

# Subcommands for 'remove'
complete -c audio-tools -n "__fish_seen_subcommand_from remove" \
    -a "short long"

# Global flags
complete -c audio-tools -s h -l help -d "Show help"
complete -c audio-tools -s V -l version -d "Show version"
complete -c audio-tools -s f -l force -d "Skip confirmation prompts"
complete -c audio-tools -s q -l quiet -d "Suppress output"
complete -c audio-tools -s v -l verbose -d "Detailed logs"
complete -c audio-tools -l json -d "Machine-readable JSON output"
complete -c audio-tools -l dry-run -d "Simulate without side effects"
complete -c audio-tools -l no-color -d "Disable colored output"
FISH
}
