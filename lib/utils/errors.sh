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
