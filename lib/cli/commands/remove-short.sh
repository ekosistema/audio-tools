# Audio Tools — Remove-short subcommand (alias for `remove short`)

if [ -z "$(type -t _remove_short)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/remove.sh"
fi

cmd_remove_short() {
    _remove_short "$@"
}

export -f cmd_remove_short
