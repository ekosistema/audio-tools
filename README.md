<div align="center">

# Audio Tools

**Batch convert, clean, normalize, dedup, and organize audio files from the terminal.**

[![License](https://img.shields.io/github/license/ekosistema/audio-tools?color=blue)](./LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnu-bash&logoColor=white)](bin/audio-tools)
[![FFmpeg](https://img.shields.io/badge/dep-ffmpeg%20|%20ffprobe-555555?logo=ffmpeg)](https://ffmpeg.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-8b5cf6)](https://github.com/ekosistema/audio-tools/pulls?utm_source=audiotools&utm_medium=docs&utm_campaign=readme-badges)

[Installation](#installation) •
[Quick Start](#quick-start) •
[Usage](#usage) •
[Configuration](#configuration) •
[Development](#development)

</div>

---

## Features

- **Convert** — WAV, OGG, FLAC, AAC, WMA, M4A → MP3, OGG, AAC, FLAC with configurable bitrate
- **Normalize** — EBU R128 loudness normalization (−16 LUFS)
- **Trim silence** — Remove leading/trailing silence from audio files
- **Split at silence** — Segment audio files at silence points
- **Concatenate** — Join multiple audio files into one
- **Clean** — Replace spaces with underscores, strip special characters in batch
- **Rename** — Batch rename with patterns: `{n}`, `{orig}`, `{date}`, `{ext}`
- **Remove** — Delete files by duration condition (shorter/longer than threshold) via system trash
- **Dedup** — Find and remove exact duplicates by SHA256 hash
- **Search** — Find files by keyword, then delete, extract, or list
- **Scan** — Consolidate scattered audio from subfolders into one flat directory
- **List** — Display audio files with metadata (size, duration, format) in multiple formats
- **Stats** — Aggregate directory statistics (file count, total duration, format breakdown)
- **Info** — Extract and display audio file metadata (bitrate, channels, sample rate, duration)
- **Config** — Manage configuration settings (get, set, edit, reset, path)
- **Completion** — Generate shell completion scripts (bash/zsh/fish)
- **Interactive menu** — Guided terminal UI with visual navigation when run without arguments
- **Batch scripting** — All commands support JSON output and global flags for automation

> All destructive operations funnel through the system trash — nothing is permanently deleted without a safety net.

---

## Installation

Requires **ffmpeg** and **ffprobe**.

```bash
git clone https://github.com/ekosistema/audio-tools.git
cd audio-tools
./install.sh
```

The installer can also fetch ffmpeg through your system package manager:

| System          | Command                         |
|-----------------|---------------------------------|
| Debian / Ubuntu | `sudo apt install ffmpeg`       |
| macOS           | `brew install ffmpeg`           |
| Arch Linux      | `sudo pacman -S ffmpeg`         |
| Fedora          | `sudo dnf install ffmpeg`       |
| RHEL / CentOS   | `sudo yum install ffmpeg`       |
| Windows         | `winget install ffmpeg` or WSL  |

Verify the installation:

```bash
audio-tools --version
audio-tools --help
```

---

## Quick Start

```bash
# Launch the interactive menu
audio-tools

# Or use subcommands directly
audio-tools convert /path/to/audio --format mp3 --bitrate 320k
audio-tools list /path/to/audio --format table
audio-tools remove short /path/to/audio --threshold 2
audio-tools info sample.wav
audio-tools normalize /path/to/audio
audio-tools dedup /path/to/audio
```

---

## Usage

### Interactive Mode

Run without arguments to enter the guided menu. It prompts you for:

1. Action to perform (via numbered menu)
2. Source directory and parameters (format, bitrate, threshold, etc.)
3. Confirmation before any destructive operation

```bash
audio-tools
```

This launches a TUI with options like:

```
╔══════════════════════════════════════════════════════════════╗
║                    Audio Tools v3.0.0                        ║
║         Batch process audio files with confidence            ║
╚══════════════════════════════════════════════════════════════╝

CONVERSION & PROCESSING
  1)  Convert audio (any format → mp3/ogg/aac/flac)
  2)  Normalize loudness (EBU R128 -16 LUFS)
  3)  Trim silence (remove start/end silence)
  4)  Concatenate files (join multiple files)
  5)  Split at silence (segment a file)

CLEANUP & ORGANIZE
  6)  Sanitize filenames
  7)  Rename files with patterns
  8)  Scan & consolidate from subfolders
  9)  Remove short/long files

DEDUPLICATION
 10)  Find duplicates (SHA256, keep files)
 11)  Dedup & remove duplicates (SHA256)

INSPECT & SEARCH
 12)  List all audio files
 13)  Stats (directory statistics)
 14)  Show file metadata
 15)  Search & extract/delete files

  c)   Configuration
  h)   Help

  0)   Exit
```

### Subcommand Mode

Use subcommands for scripting and batch processing:

```bash
# Convert audio files
audio-tools convert /path/to/audio --format mp3 --bitrate 320k

# Normalize loudness
audio-tools normalize /path/to/audio

# Trim leading/trailing silence
audio-tools trim-silence /path/to/audio

# Split file at silence points
audio-tools split-silence recording.wav

# Concatenate files
audio-tools concat /path/to/audio

# List files with metadata
audio-tools list /path/to/audio --format table

# Remove files shorter than 2 seconds
audio-tools remove short /path/to/audio --threshold 2 --force

# Remove files longer than 60 seconds
audio-tools remove long /path/to/audio --threshold 60

# Search for "kick" samples and extract them
audio-tools search /path/to/audio --query kick --operation extract

# Sanitize filenames (spaces → underscores, special chars removed)
audio-tools clean /path/to/audio

# Rename with pattern
audio-tools rename /path/to/audio --pattern 'track_{n}'

# Find duplicate files (SHA256, keep all)
audio-tools find-dupes /path/to/audio

# Remove exact duplicates (keep first)
audio-tools dedup /path/to/audio

# Consolidate audio from subfolders into one directory
audio-tools scan /path/to/audio --output ALL_AUDIO

# Show aggregate statistics
audio-tools stats /path/to/audio

# Show file metadata
audio-tools info sample.wav

# Manage configuration
audio-tools config list
audio-tools config get bitrate
audio-tools config set bitrate 192k
audio-tools config edit
audio-tools config path

# Generate shell completion
audio-tools completion bash
audio-tools completion zsh
```

### Commands Reference

| Command          | Subcommands        | Description                                      |
|------------------|--------------------|--------------------------------------------------|
| `convert`        | —                  | WAV/OGG/FLAC/AAC/WMA/M4A → MP3/OGG/AAC/FLAC     |
| `normalize`      | —                  | EBU R128 loudness normalization (−16 LUFS)       |
| `trim-silence`   | —                  | Remove leading/trailing silence                  |
| `split-silence`  | —                  | Split audio at silence points into segments      |
| `concat`         | —                  | Concatenate multiple files into one              |
| `clean`          | —                  | Replace spaces with underscores, strip special chars |
| `rename`         | —                  | Batch rename with `{n}` `{orig}` `{date}` `{ext}` |
| `remove`         | `short`, `long`    | Move files by duration condition to system trash |
| `search`         | —                  | Find files by keyword, then delete/extract/list  |
| `scan`           | —                  | Copy all audio from subfolders into one directory |
| `list`           | —                  | List audio files with metadata and formatting    |
| `stats`          | —                  | Aggregate directory statistics                   |
| `info`           | —                  | Display audio file metadata                      |
| `dedup`          | —                  | Remove exact duplicates by SHA256                |
| `find-dupes`     | —                  | Find exact duplicates by SHA256 (keep files)     |
| `config`         | `list`, `get`, `set`, `reset`, `edit`, `path` | Manage configuration  |
| `completion`     | —                  | Generate shell completion script                 |

### Global Flags (All Commands)

| Flag                      | Description                                      |
|---------------------------|--------------------------------------------------|
| `-h`, `--help`            | Show help message for command                    |
| `-V`, `--version`         | Show version information                         |
| `-q`, `--quiet`           | Suppress non-error output                        |
| `-v`, `--verbose`         | Enable detailed step-by-step logs                |
| `--json`                  | Output results in JSON format                    |
| `--dry-run`               | Simulate operation without side effects          |
| `--no-color`              | Disable ANSI colored output                      |
| `-f`, `--force`           | Skip confirmation prompts (use with caution)     |
| `--no-force`              | Always ask for confirmation [default]            |
| `-C`, `--config FILE`     | Use custom config file path                      |
| `-d`, `--directory PATH`  | Target directory [default: current]              |
| `-t`, `--threshold SEC`   | Duration threshold for remove commands           |
| `-q`, `--query STRING`    | Filename keyword for search                      |
| `-o`, `--operation OP`    | Operation for search: `delete` \| `extract`     |
| `--format FMT`            | Output format for convert [default: mp3]         |
| `--bitrate RATE`          | Audio bitrate [default: 320k]                    |
| `--pattern PAT`           | Rename pattern: `{n}`, `{orig}`, `{date}`, `{ext}` |
| `--files-from FILE`       | Read file paths from a file (one per line)       |
| `--max-depth N`           | Max recursion depth [default: unlimited]         |
| `--progress`              | Show compact progress bar [default]              |
| `--no-progress`           | Show detailed per-file logs instead              |

### Output Formats

Several commands support multiple output formats:

```bash
# Table format (default for list)
audio-tools list /path --format table

# Simple list
audio-tools list /path --format simple

# Tree view (hierarchical)
audio-tools list /path --format tree

# JSON (all commands)
audio-tools list /path --json
audio-tools info sample.wav --json
audio-tools stats /path --json
```

---

## Configuration

The config file at `~/.config/audio-tools/config.sh` uses plain Bash syntax
and is sourced at startup.

Priority: **CLI flags > environment variables > config file > built-in defaults**.

```bash
# Example config file
export AUDIO_TOOLS_CONVERTED_DIR="mp3_output"
export AUDIO_TOOLS_SCAN_DIR="all_audio"
export AUDIO_TOOLS_FORMAT="flac"
export AUDIO_TOOLS_BITRATE="192k"
export AUDIO_TOOLS_FORCE="yes"
```

### Environment Variables

| Variable                     | Default                            | Description                     |
|------------------------------|------------------------------------|---------------------------------|
| `AUDIO_TOOLS_CONVERTED_DIR`  | `converted_mp3`                    | Output subdirectory for convert |
| `AUDIO_TOOLS_SCAN_DIR`       | `ALL_AUDIOS`                       | Output subdirectory for scan    |
| `AUDIO_TOOLS_FORMAT`         | `mp3`                              | Default output format           |
| `AUDIO_TOOLS_BITRATE`        | `320k`                             | Default audio bitrate           |
| `AUDIO_TOOLS_CONFIG`         | `~/.config/audio-tools/config.sh`  | Config file path                |
| `AUDIO_TOOLS_FORCE`          | —                                  | Skip prompts when set to `yes`  |
| `AUDIO_TOOLS_QUIET`          | —                                  | Suppress output when set to `yes`|
| `NO_COLOR`                   | —                                  | Disable ANSI color output       |

## Exit Status

| Code | Meaning                                     |
|------|---------------------------------------------|
| `0`  | Success                                     |
| `64` | Usage error (invalid flag, missing argument) |
| `65` | Data error (bad file)                       |
| `69` | Service unavailable (ffmpeg/ffprobe missing) |
| `74` | I/O error (file read/write failure)          |

---

## Safety

Audio Tools **never deletes files permanently** without a safety net. All destructive
operations (`remove short`, `remove long`, `search --operation delete`, `dedup`) use
`move_to_trash()`, which follows this funnel:

1. **macOS** — moves to `~/.Trash`
2. **Linux** — attempts `gio trash`, then `trash-put`, then `~/.local/share/Trash/files`
3. **Fallback** — moves to a local `to_delete/` folder

Run with `--force` or set `AUDIO_TOOLS_FORCE=yes` to skip confirmation prompts
(use with caution).

---

## Development

Dependencies: **bats** (testing), **shellcheck** (linting).

```bash
# Install dev dependencies
bash tests/setup.sh

# Run all tests
bats tests/bats/

# Lint every script
shellcheck bin/audio-tools lib/cli/**/*.sh lib/core/**/*.sh lib/io/**/*.sh lib/utils/**/*.sh

# Syntax check
bash -n bin/audio-tools

# Smoke test
bash bin/audio-tools --version
bash bin/audio-tools --help
bash bin/audio-tools convert --help
```

### Adding a New Command

1. Create `lib/cli/commands/mycommand.sh` following the template in [`docs/command-template.md`](docs/command-template.md)
2. Implement the `cmd_mycommand()` function and export it
3. Add tests in `tests/bats/test_mycommand.bats`

The dispatcher auto-discovers commands by filename — no need to register manually.

### Project Structure

```
audio-tools/
├── bin/
│   └── audio-tools          # Entry point (thin dispatch)
├── lib/
│   ├── cli/
│   │   ├── dispatcher.sh     # Subcommand routing (git-style)
│   │   ├── help.sh           # Help text generation
│   │   ├── completion.sh     # Shell completion (bash/zsh/fish)
│   │   ├── commands/         # Per-command handlers (auto-discovered)
│   │   │   ├── convert.sh
│   │   │   ├── clean.sh
│   │   │   ├── concat.sh
│   │   │   ├── config.sh
│   │   │   ├── dedup.sh
│   │   │   ├── find-dupes.sh
│   │   │   ├── info.sh
│   │   │   ├── list.sh
│   │   │   ├── normalize.sh
│   │   │   ├── remove.sh
│   │   │   ├── remove-short.sh
│   │   │   ├── remove-long.sh
│   │   │   ├── rename.sh
│   │   │   ├── scan.sh
│   │   │   ├── search.sh
│   │   │   ├── split-silence.sh
│   │   │   ├── stats.sh
│   │   │   └── trim-silence.sh
│   │   └── ui/               # User interface layer
│   │       ├── output.sh     # Output formatting (text, JSON, table)
│   │       ├── args_parser.sh # Argument parsing helpers
│   │       ├── tui.sh        # Interactive menu system
│   │       ├── file_browser.sh # File selection with fzf
│   │       └── progress.sh   # Progress bars and spinners
│   ├── core/                 # Business logic
│   │   ├── converter.sh
│   │   ├── cleaner.sh
│   │   ├── organizer.sh
│   │   ├── inspector.sh
│   │   ├── processor.sh
│   │   ├── deduper.sh
│   │   └── validator.sh
│   ├── io/                   # I/O layer
│   │   ├── filesystem.sh
│   │   ├── media.sh
│   │   └── trash.sh
│   └── utils/                # Shared utilities
│       ├── errors.sh
│       ├── logging.sh
│       ├── config.sh
│       └── progress.sh
├── docs/
│   └── command-template.md   # Template for adding new commands
├── tests/
│   ├── bats/                 # Test suites (bats)
│   └── fixtures/             # Test audio samples
├── html/                     # Marketing landing page
├── man/
│   └── audio-tools.1         # Man page
├── VERSION                   # Version number
├── install.sh                # Installation script
├── CHANGELOG.md              # Release history
└── README.md                 # This file
```

### Architecture

The code follows strict layering for testability and modularity:

- **`lib/cli/dispatcher.sh`** — Parses global flags, routes subcommands (git-style), and dispatches to command handlers. Auto-discovers commands by filename in `lib/cli/commands/`.
- **`lib/cli/commands/`** — Individual command implementations. Each file defines a `cmd_<name>()` function. Parse args, call core logic, format output. Auto-sources dependencies for standalone testing.
- **`lib/cli/ui/`** — User interface components: interactive menu (`tui.sh`), file browser (`file_browser.sh`), progress indicators (`progress.sh`), output formatting (`output.sh`).
- **`lib/core/`** — Pure business logic. No I/O, no stdin reading, no process exits. Takes input, returns results.
- **`lib/io/`** — Wraps external tools (ffmpeg, ffprobe) and system operations (filesystem, trash handling).
- **`lib/utils/`** — Shared utilities: error codes (`errors.sh`), colored logging (`logging.sh`), config loading (`config.sh`), progress bars (`progress.sh`).

---

## Contributing

Contributions are welcome. Please follow these guidelines:

1. Open an [issue](https://github.com/ekosistema/audio-tools/issues?utm_source=audiotools&utm_medium=docs&utm_campaign=readme-contributing) to discuss changes before submitting a PR
2. Maintain the existing layer separation (`cli/` → `core/` → `io/` → `utils/`)
3. Add or update bats tests for new functionality
4. Run `shellcheck` on all modified `.sh` files
5. Keep the CHANGELOG updated with user-facing changes

---

## License

MIT — maintained by [CeleroLab](https://celerolab.com?utm_source=audiotools&utm_medium=docs&utm_campaign=readme-license). See [LICENSE](./LICENSE).
