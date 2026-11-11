# Changelog

## Unreleased

### Trash
- Linux/WSL without `gio`/`trash-put` now follows the **FreeDesktop Trash spec** (`~/.local/share/Trash/files` + `info/*.trashinfo` with the original path and deletion date), so deleted files stay restorable from a file manager or `trash-restore`; `$XDG_DATA_HOME` is honoured
- Each backend is tried in turn (gio, trash-put, FreeDesktop, `to_delete/`): a failing `gio` no longer skips the rest
- Trash/`to_delete/` moves never overwrite an existing file of the same name (`song_2.mp3`); the same applies to macOS `~/.Trash`

### Safety
- **`--dry-run` now really never deletes**: `move_to_trash` is a no-op under dry run (`remove short|long`, `search --operation delete` previously ignored it)
- **`--quiet` no longer skips delete confirmations** (it used to delete without asking)
- New `confirm_prompt`: with no input available (closed stdin, CI) destructive commands exit 64 with a hint to use `--force` instead of hanging or guessing
- Interactive menu exits 64 with a message when stdin is closed

### Fixes
- Convert, normalize, trim-silence and split-silence preserve the source sample rate and channels (MP3 capped at 48 kHz / 2 ch, AAC at 96 kHz); override with `AUDIO_TOOLS_SAMPLE_RATE` / `AUDIO_TOOLS_CHANNELS`
- Outputs are written to `<name>.part.<ext>` and renamed on success, so failed runs leave no truncated files; ffmpeg's last error line is shown (full log with `--verbose`); zero-byte leftovers are re-converted
- JSON output is escaped correctly (file names with quotes/backslashes), no `jq` needed; table JSON rows are arrays; global `--json` now applies to `list`
- `bc` is no longer required; ffprobe CRLF output (Windows builds) no longer breaks `stats`/`list`
- `--help`/`--version` work without ffmpeg installed
- Bash 3.2 (macOS default) is detected with an actionable message; shebang is now `#!/usr/bin/env bash`

### Tooling
- GitHub Actions CI: shellcheck, bats on Ubuntu and macOS, CLI smoke test
- `.shellcheckrc`; the codebase is shellcheck-clean

## 3.0.0 — 2026-05

Major refactor and production-ready release.

- **Modular architecture**: Codebase split into four layers — `cli/`, `core/`, `io/`, `utils/` — with clear separation of concerns
- **Interactive menu**: New guided terminal UI with config wizard, accessible by running `audio-tools` without arguments
- **Trash safety system**: All destructive operations funnel through `move_to_trash()` — macOS Trash → gio trash → trash-put → local fallback
- **Marketing landing page**: Standalone Tailwind CSS site under `html/` with PWA support
- **CI/CD pipeline**: GitHub Actions with shellcheck, bats tests, and smoke tests on every push/PR
- **Man page**: `man audio-tools.1` with full reference
- **Configuration wizard**: First-run prompts for source dirs, output paths, and force mode
- **Self-sourcing modules**: Core modules auto-source dependencies, enabling standalone testing

### Fixes & Improvements

- **Rename**: Extensión auto-preservada cuando el patrón no incluye `{ext}`
- **Rename**: `{date}` ahora incluye sufijo aleatorio de 6 caracteres (`YYYYMMDD_XXXXXX`)
- **Rename**: Filtra solo archivos de audio (ya no renombra `.txt` etc.)
- **TUI**: Tab-completion (readline) en prompts de ruta
- **TUI**: Recorte de espacios finales post-TAB en rutas
- **Dispatcher**: `--no-force` como flag global
- **Dispatcher**: `--verbose` overridea `--quiet` (ya no es error)
- **Dispatcher**: Flags desconocidos sin subcomando ahora devuelven error (exit 64)
- **Dispatcher**: `--quiet --help` y similares ahora muestran ayuda correctamente
- **Dispatcher**: `clean-names` renombrado a `clean` (alias eliminado)
- **Tests**: 87/89 tests pasan (2 fallan por shellcheck no instalado)

## 2.1.0 — 2025

- Safety confirmation prompts before destructive operations
- `--force` flag to skip confirmations in batch mode
- HTML marketing page initial version

## 2.0.0 — 2025

- Batch mode with `--action` flag and argument parsing (`lib/cli/args.sh`)
- FFmpeg/ffprobe wrapper with `LD_LIBRARY_PATH` isolation (`lib/io/media.sh`)
- Dedicated modules: `converter.sh`, `cleaner.sh`, `organizer.sh`
- Environment variable configuration (`AUDIO_TOOLS_CONVERTED_DIR`, `AUDIO_TOOLS_SCAN_DIR`)
- Improved error handling with sysexits exit codes

## 1.0.0 — 2024

- Initial release
- Single monolithic script (`audio_tools.sh`)
- Basic MP3 conversion and filename cleaning
- MIT License

---

Maintained by [CeleroLab](https://celerolab.com?utm_source=audiotools&utm_medium=docs&utm_campaign=changelog).
