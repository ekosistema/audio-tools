# Changelog

All notable changes to this project are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Nothing yet. See [CONTRIBUTING.md](CONTRIBUTING.md) for how to propose a change.

## [3.1.0] - 2026-11-11

A safety, correctness and polish release. If you only read one thing: **`--dry-run` now really
changes nothing, `--quiet` can no longer delete without asking, and `dedup` finally does what its
help text says.** Run `audio-tools --help` to see the new flags.

### Added

- **Color.** The interactive menu, tables, progress, `dedup`, `info`, `stats` and `--dry-run`
  previews are now colorized. It is automatic on terminals, never leaks into pipes, and follows
  [`NO_COLOR`](https://no-color.org/), `--no-color` and the new `--color[=auto|always|never]`
  flag (also `AUDIO_TOOLS_COLOR` and `CLICOLOR_FORCE=1`).
- **Global flags work after the command.** `audio-tools convert --dry-run` is now the same as
  `audio-tools --dry-run convert` (applies to `--dry-run`, `--json`, `--color`, `--no-color`,
  `--quiet`, `--verbose`, `--force`, `--no-force`).
- `AUDIO_TOOLS_SAMPLE_RATE` and `AUDIO_TOOLS_CHANNELS` to force the output format of `convert`,
  `normalize` and `trim-silence`.
- Community files: `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue and pull request
  templates, `docs/architecture.md`, `docs/safety.md`, and an animated demo in the README.
- GitHub Actions CI: ShellCheck, the bats suite on Ubuntu and macOS, and a CLI smoke test.

### Changed

- **Audio quality:** `convert`, `normalize`, `trim-silence` and `split-silence` keep the source
  sample rate and channel layout instead of forcing 44.1 kHz stereo. MP3 output is capped at
  48 kHz / 2 channels and AAC at 96 kHz, the encoders' limits.
- **Trash on Linux and WSL** follows the FreeDesktop Trash specification when `gio` and
  `trash-put` are missing, so deleted files can be restored from a file manager. Every backend is
  tried in turn, and a file never overwrites another one of the same name in the trash.
- `dedup` keeps the first file by sorted path, so the result no longer depends on directory order.
- `find-dupes` labels the kept file `keep:`.
- Tables (`list --format table`, `info`) size their columns to the widest cell.
- The version shown by `--version`, `--help` and the menu banner comes from the single `VERSION`
  file.
- Bash 4.0+ is checked at startup with an actionable message (macOS ships Bash 3.2), and the
  shebang is now `#!/usr/bin/env bash`.

### Fixed

- **`--dry-run` was ignored** by `remove short`, `remove long` and `search --operation delete`
  (which really moved files to the trash), and `clean`, `scan` and `search --operation extract`
  (which really renamed or copied files). Every file-touching command now prints what it would do and
  leaves the folder exactly as it was, without even creating an empty output directory.
- `search --operation extract` overwrote files that shared a name; it now writes `name_1.wav`, ...
- **`--quiet` skipped the delete confirmation** and deleted without asking. It no longer does.
- **`dedup` never removed anything**, although its help text promised it. It now moves duplicates
  to the trash, after a confirmation (or `--force`).
- Destructive commands exit with status 64 and a hint to use `--force` when there is nobody to ask
  (closed stdin, CI, cron) instead of hanging or guessing.
- Failed conversions no longer leave truncated files that later runs mistook for finished work.
  Outputs are written to `<name>.part.<ext>` and renamed on success, ffmpeg's last error line is
  shown (the whole log with `--verbose`), and zero-byte leftovers are converted again.
- JSON output is valid for any file name (quotes, backslashes, control characters), and no longer
  needs `jq`. Table rows in JSON are arrays. `--json` now applies to `list`.
- The interactive menu no longer aborts when `TERM` is unset or `dumb` (CI, containers), and exits
  with a message when stdin is closed.
- Invalid values for `--color` (and other flag parsing errors) exit with status 64 instead of being
  ignored.
- `bc` is no longer required. Windows ffprobe builds (CRLF output) no longer break `stats` and
  `list`.
- `--help` and `--version` work even when ffmpeg is not installed.
- Messages containing backslashes are printed verbatim.

## [3.0.0] - 2026-05

Major refactor and production-ready release.

### Added

- **Modular architecture**: the code is split into four layers, `cli/`, `core/`, `io/` and
  `utils/`, with a clear separation of concerns.
- **Interactive menu**: a guided terminal UI with a configuration wizard, opened by running
  `audio-tools` without arguments.
- **Trash safety system**: all destructive operations go through `move_to_trash()` (macOS Trash,
  `gio trash`, `trash-put`, local fallback).
- **Landing page**: a standalone Tailwind CSS site under `html/` with PWA support.
- **Man page**: `man audio-tools` with the full reference.
- **First-run configuration wizard** for source directories, output paths and force mode.
- **Self-sourcing modules**: core modules source their own dependencies, enabling standalone
  testing.
- `--no-force` as a global flag.
- Tab completion (readline) in the menu's path prompts.

### Changed

- `clean-names` was renamed to `clean` (the old alias was removed).
- `--verbose` overrides `--quiet` instead of being an error.
- Unknown flags without a subcommand return an error (exit 64).

### Fixed

- `rename`: the extension is preserved when the pattern does not include `{ext}`; `{date}` now
  includes a random 6-character suffix (`YYYYMMDD_XXXXXX`); only audio files are renamed (no more
  `.txt` files).
- Menu: trailing spaces after TAB completion in paths are trimmed.
- `--quiet --help` and similar combinations now show the help.

## [2.1.0] - 2025

### Added

- Confirmation prompts before destructive operations.
- `--force` flag to skip confirmations in batch mode.
- First version of the HTML landing page.

## [2.0.0] - 2025

### Added

- Batch mode with the `--action` flag and argument parsing (`lib/cli/args.sh`).
- ffmpeg/ffprobe wrapper with `LD_LIBRARY_PATH` isolation (`lib/io/media.sh`).
- Dedicated modules: `converter.sh`, `cleaner.sh`, `organizer.sh`.
- Environment variable configuration (`AUDIO_TOOLS_CONVERTED_DIR`, `AUDIO_TOOLS_SCAN_DIR`).

### Changed

- Improved error handling with [sysexits](https://man.freebsd.org/cgi/man.cgi?query=sysexits) exit
  codes.

## [1.0.0] - 2024

### Added

- Initial release: a single monolithic script (`audio_tools.sh`) with basic MP3 conversion and
  filename cleaning. MIT license.

---

Maintained by [CeleroLab](https://celerolab.com?utm_source=audiotools&utm_medium=docs&utm_campaign=changelog).
