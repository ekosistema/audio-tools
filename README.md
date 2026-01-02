# 🎛️ Audio Tools
> **A Bash Suite for Audio Management**

**Audio Tools** is a comprehensive suite of Bash scripts designed to assist with audio file management. It provides a set of utilities for converting, cleaning, and organizing audio libraries, intended for sound engineers, producers, and data archivists.

The goal is to simplify repetitive tasks through a reliable command-line interface.

---

## ✨ Features

*   **📦 Modular**: Built with reusable libraries to ensure maintainability and easy extension.
*   **🛡️ Safer Operations**: Implements "Strict Mode" (set -euo pipefail), dependency checks, and prioritizes system trash.
*   **⚙️ Automation**: Supports fully automated batch processing via CLI arguments.
*   **🖥️ Hybrid Interface**: choose between a guided **Interactive Menu** or advanced **Batch Mode** for scripting.
*   **⚡ Lightweight**: Written in standard Bash with minimal dependencies.

---

## 🛠️ Functionality

The toolkit is organized into three main modules:

### 1. 🔄 **Converter**
*   **Format Conversion**: Converts `WAV`, `FLAC`, and `OGG` files to **320kbps MP3**.
*   **Batch Mode**: Processes entire directories recursively.
*   **Efficiency**: Skips files that have already been processed.

### 2. 🧹 **Cleaner**
*   **Duration Filtering**: clean up folders by archiving or removing audio files that are too short (glitches) or too long.
*   **Filename Sanitization**: Standardizes filenames by removing special characters and spaces to improve compatibility.

### 3. 🗂️ **Organizer**
*   **Centralization**: Scans subdirectories and consolidates audio files into a single location.
*   **Search & Action**: Allows users to find files by keyword and perform batch operations such as copying or deleting.

---

## 📂 Project Structure

```text
audio-tools/
├── 📂 bin/             # Main executable
│   └── audio-tools
├── 📂 lib/             # Logic libraries
│   ├── 📂 modules/     # Toolsets (converter, cleaner, organizer)
│   └── utils.sh        # Utilities (logging, UI, trash)
├── install.sh          # Installation script
└── README.md           # Documentation
```

---

## 🚀 Installation

### Option A: Automatic

To clone and install the tools in one step:

```bash
git clone https://github.com/ekosistema/audio-tools.git && cd audio-tools && ./install.sh
```

### Option B: Manual

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/ekosistema/audio-tools.git
    ```
2.  **Copy files**:
    Place `bin` and `lib` in a directory like `~/.local/share/audio-tools`.
3.  **Link**:
    Create a symbolic link to the executable:
    ```bash
    ln -sf ~/.local/share/audio-tools/bin/audio-tools ~/.local/bin/audio-tools
    ```

---

## 🎮 Usage

### 🖥️ Interactive Mode
Run without arguments to launch the guided menu:
```bash
audio-tools
```

### 🤖 Batch Mode (CLI)
Run with arguments to bypass the menu.

**Syntax:**
```bash
audio-tools [OPTIONS]
```

**Options:**
| Flag | Description |
| :--- | :--- |
| `-h`, `--help` | Show help message |
| `-d`, `--directory PATH` | Target directory (defaults to current) |
| `-a`, `--action ACTION` | Action to perform (see below) |
| `-t`, `--threshold SEC` | Duration threshold (for remove_short/long) |
| `-q`, `--query TEXT` | Search query (for search action) |
| `-o`, `--operation OP` | Search operation: `delete` or `extract` |
| `-f`, `--force` | Skip confirmation prompts (for scripts) |

**Available Actions (`--action`):**
1.  `convert` - Convert to MP3
2.  `remove_short` - Remove short files
3.  `remove_long` - Remove long files
4.  `clean_names` - Sanitize filenames
5.  `scan` - Copy all audios from subfolders
6.  `search` - Search and process

**Examples:**
```bash
# Convert all files in current dir
audio-tools --action convert

# Remove files shorter than 2 seconds in specific folder (force yes)
audio-tools --action remove_short --threshold 2 --directory /tmp/samples --force

# Search for "kick" and extract matches
audio-tools --action search --query "kick" --operation extract
```

---

## ❓ Troubleshooting

| Problem | Possible Cause | Solution |
| :--- | :--- | :--- |
| **"Command not found"** | Installation path missing from `PATH`. | Add `export PATH=$PATH:~/.local/bin` to your shell configuration (`.bashrc`/`.zshrc`). |
| **"Permission denied"** | Missing execution rights. | Run `chmod +x install.sh` or check folder permissions. |
| **"ffmpeg not found"** | Dependency missing. | Install manually via package manager (e.g., `apt install ffmpeg` or `brew install ffmpeg`). |
| **Files permanently deleted** | `trash-cli` missing. | The script attempts to use system trash; if unavailable on Linux, install `trash-cli` or `trash`. |

---

## 👨‍💻 Credits

**Audio Tools** is maintained by **[CeleroLab.Com](https://celerolab.com)**.

*   **License**: MIT
*   **Version**: 2.1.0