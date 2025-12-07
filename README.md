# 🎛️ Audio Tools
> **A Bash Suite for Audio Management**

**Audio Tools** is a comprehensive suite of Bash scripts designed to assist with audio file management. It provides a set of utilities for converting, cleaning, and organizing audio libraries, intended for sound engineers, producers, and data archivists.

The goal is to simplify repetitive tasks through a reliable command-line interface.

---

## ✨ Features

*   **📦 Modular**: Built with reusable libraries to ensure maintainability and easy extension.
*   **🛡️ Safer Operations**: Prioritizes using the system trash (freedesktop.org/macOS) over permanent deletion to prevent accidental data loss.
*   **⚙️ Automation**: Includes dependency checks and error handling for consistent operation.
*   **🖥️ Interactive**: specific commands are not required; an interactive menu guides the usage.
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

To start the interactive menu, run:

```bash
audio-tools
```

Available options:

1.  🎵 **Convert files to MP3**
2.  ⏱️ **Remove short audio files**
3.  📥 **Scan and copy audio files**
4.  📝 **Clean filenames**
5.  ⏳ **Remove long audio files**
6.  🔍 **Search and process audio files**

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
*   **Version**: 2.0.0