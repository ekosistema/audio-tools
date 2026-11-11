# Command Template

Each command file in `lib/cli/commands/` should follow this structure.

Commands are auto-discovered by the dispatcher — create a file named `<command>.sh`
and it will be available as `audio-tools <command>`.

## File Naming

- Filename: `<command>.sh` (e.g., `convert.sh`, `clean.sh`)
- Must match subcommand name (e.g., `audio-tools convert` → `convert.sh`)
- Hyphens in command names use hyphens in filenames (e.g., `trim-silence.sh`)
- The dispatcher translates hyphens to underscores for the function name: `trim-silence.sh` → `cmd_trim_silence()`

## Required Structure

```bash
# Audio Tools — <name> subcommand

# Self-source dependencies (allow standalone testing)
if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t <core_function>)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/<module>.sh"
fi

cmd_<command>() {
    local dir="."

    # Help check
    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
USAGE:
  audio-tools <command> [options] [directory]

OPTIONS:
  -d, --directory PATH   Source directory [default: current]
  --dry-run              Preview without modifying
  -h, --help             Show this help message
EOF
        return 0
    fi

    # Parse command-specific arguments
    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            --dry-run) export AUDIO_TOOLS_DRY_RUN="yes"; shift ;;
            --) shift; break ;;
            *) dir="$1"; shift ;;
        esac
    done

    # Validate
    if [ ! -d "$dir" ]; then
        log_error "Directory not found: $dir"
        return "$EX_IOERR"
    fi

    # Execute business logic
    export AUDIO_TOOLS_DIRECTORY="$dir"
    <core_function> "$dir"
}

export -f cmd_<command>
```

## Global State Available

Each command can access these exported variables (set by `lib/cli/dispatcher.sh`):

- `$AUDIO_TOOLS_QUIET` — Suppress non-error output (yes/no)
- `$AUDIO_TOOLS_VERBOSE` — Enable detailed logs (yes/no)
- `$AUDIO_TOOLS_JSON` — Output JSON format (yes/no)
- `$AUDIO_TOOLS_DRY_RUN` — Simulate without side effects (yes/no)
- `$AUDIO_TOOLS_NO_COLOR` — Disable ANSI colors (yes/no)
- `$AUDIO_TOOLS_COLOR` — `auto` (default), `always` or `never`
- `$AUDIO_TOOLS_FORCE` — Skip confirmations (yes/no)
- `$AUDIO_TOOLS_DIRECTORY` — Target directory
- `$AUDIO_TOOLS_THRESHOLD` — Duration threshold (for remove commands)

> **You do not parse the global flags yourself.** The dispatcher handles `--dry-run`, `--json`,
> `--color[=WHEN]`, `--no-color`, `--quiet`, `--verbose`, `--force` and `--no-force`, whether they
> come before or after the command name, and removes them before calling your `cmd_<name>()`.
> Parse only the options that belong to your command. (Short flags such as `-f` are *not* hoisted
> because they can mean different things per command.)

## Example: convert.sh

```bash
# Audio Tools — Convert subcommand

if [ -z "$(type -t log_info)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"
fi
if [ -z "$(type -t log_error)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../utils/errors.sh"
fi
if [ -z "$(type -t convert_to_mp3)" ]; then
    source "$(dirname "${BASH_SOURCE[0]}")/../core/converter.sh"
fi

cmd_convert() {
    local dir="."
    local format="mp3"
    local bitrate="320k"

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        cat << 'EOF'
USAGE:
  audio-tools convert [options] [directory]

OPTIONS:
  -d, --directory PATH   Source directory [default: current]
  -f, --format FORMAT    Output format [default: mp3]
  -b, --bitrate RATE     Audio bitrate [default: 320k]
  -h, --help             Show this help message
EOF
        return 0
    fi

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -d|--directory) dir="$2"; shift 2 ;;
            -f|--format) format="$2"; shift 2 ;;
            -b|--bitrate) bitrate="$2"; shift 2 ;;
            --) shift; break ;;
            *) dir="$1"; shift ;;
        esac
    done

    export AUDIO_TOOLS_DIRECTORY="$dir"
    export AUDIO_TOOLS_FORMAT="$format"
    export AUDIO_TOOLS_BITRATE="$bitrate"

    convert_to_mp3 "$dir"
}

export -f cmd_convert
```

## Pattern: Subcommand Nesting

For commands with subcommands (like `remove short`, `remove long`):

```bash
cmd_remove() {
    local subcommand="${1:-}"

    if [ "$subcommand" = "-h" ] || [ "$subcommand" = "--help" ]; then
        cat << 'EOF'
USAGE:
  audio-tools remove <short|long> [options]

SUBCOMMANDS:
  short   Remove files shorter than threshold
  long    Remove files longer than threshold
EOF
        return 0
    fi

    shift || true

    case "$subcommand" in
        short) _remove_short "$@" ;;
        long)  _remove_long "$@" ;;
        *) log_error "Usage: audio-tools remove <short|long>"; return "$EX_USAGE" ;;
    esac
}
```

## Pattern: JSON Output

Never build JSON by interpolating raw strings: a file name with a quote in it would produce invalid
JSON. Use the helpers from `lib/cli/ui/output.sh` (pure Bash, no `jq`):

```bash
if [ "$AUDIO_TOOLS_JSON" = "yes" ]; then
    printf '{"status":"success","directory":%s,"files":%d}\n' "$(json_string "$dir")" "$count"
else
    log_info "Converted $count files"
fi
```

`json_string` quotes and escapes a string, `json_number` prints a number or `null`.

## Pattern: Confirmation Prompts

Use `confirm_prompt` (from `lib/utils/errors.sh`) before anything destructive. It skips the question
with `--force`, never lets `--quiet` skip it, and exits with status 64 and a helpful message when
there is nobody to answer (closed stdin, CI) instead of guessing:

```bash
confirm_prompt "Delete ${#files[@]} files?" || { log_info "Cancelled"; return 0; }
```

## Pattern: Destructive Operations

Never call `rm`. Move files with `move_to_trash` (from `lib/io/trash.sh`): it is recoverable, never
overwrites, and is already a no-op under `--dry-run`, so a command that funnels deletions through it
honours `--dry-run` for free. Report with `delete_verb` so the message says "Would delete" on a dry run:

```bash
for file in "${files[@]}"; do
    move_to_trash "$file" "$dir" || true
done
log_info "$(delete_verb) ${#files[@]} files"
```

If your command writes new files, honour `--dry-run` yourself (print what would happen and return)
and write through a temporary `.part` file (see `run_atomic` in `lib/io/filesystem.sh`) so a failure
never leaves a truncated output.

## Pattern: Color

Colors come from one palette (`lib/utils/logging.sh`). Use the variables, never raw escape codes:
`$RED $GREEN $YELLOW $CYAN $MAGENTA $BOLD $DIM $NC` for text on **stdout**, and `$E_RED`, `$E_CYAN`,
`$E_NC`… for text on **stderr**. They are empty when color is off, so the same line works everywhere:

```bash
printf '  %bkeep:%b %s\n' "$GREEN" "$NC" "$path"
```

Use `printf '%b%s'` (not `echo -e "...$user_text"`) so file names containing backslashes print verbatim.

## Exit Codes

Use sysexits convention from `lib/utils/errors.sh`:

- `0` — Success
- `64` (`$EX_USAGE`) — Usage error (invalid args)
- `65` (`$EX_DATAERR`) — Data error (bad file)
- `69` (`$EX_UNAVAILABLE`) — Service unavailable (missing dependency)
- `74` (`$EX_IOERR`) — I/O error (read/write failed)

---

Maintained by [CeleroLab](https://celerolab.com?utm_source=audiotools&utm_medium=docs&utm_campaign=command-template). MIT License.
