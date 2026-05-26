# Audio Tools — Remove-long subcommand (alias for `remove long`)

if [ -z "$(type -t _remove_long)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/remove.sh"
fi

cmd_remove_long() {
    _remove_long "$@"
}

export -f cmd_remove_long
