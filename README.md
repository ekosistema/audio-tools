# Audio Tools Script Manual

## Table of Contents
- [Audio Tools Script Manual](#audio-tools-script-manual)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Installation](#installation)
    - [Method 1: One-Line Installation from GitHub](#method-1-one-line-installation-from-github)
    - [Method 2: Manual Installation](#method-2-manual-installation)
    - [Dependencies](#dependencies)
  - [Usage](#usage)
  - [Functions](#functions)
    - [Convert files to MP3](#convert-files-to-mp3)
    - [Remove short audio files](#remove-short-audio-files)
    - [Scan and copy audio files from subfolders](#scan-and-copy-audio-files-from-subfolders)
    - [Clean filenames](#clean-filenames)
    - [Remove long audio files](#remove-long-audio-files)
    - [Search and process audio files](#search-and-process-audio-files)
  - [Troubleshooting](#troubleshooting)

## Introduction

The Audio Tools script is a comprehensive audio processing tool that combines multiple functionalities for managing audio files. It allows you to convert audio files to MP3, remove short or long audio files, scan and copy audio files from subfolders, clean filenames, and search and process audio files based on their names.

## Installation

There are two ways to install the Audio Tools script:

### Method 1: One-Line Installation from GitHub

You can install the Audio Tools script directly from GitHub using the following command:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ekosistema/audio-tools/main/install.sh)"
```

This method will:
- Install necessary dependencies (ffmpeg and sed)
- Download the audio_tools script
- Set up the script in your system
- Add the script's location to your PATH

### Method 2: Manual Installation

If you prefer to install the script manually:

1. Clone the repository or download the `audio_tools.sh` script.
2. Move the script to a directory in your PATH, for example:
   ```
   mv audio_tools.sh ~/bin/audio_tools
   ```
3. Give the script execution permissions:
   ```
   chmod +x ~/bin/audio_tools
   ```
4. Ensure that `~/bin` is in your PATH. If it's not, add the following line to your `~/.bashrc` or `~/.zshrc`:
   ```
   export PATH="$HOME/bin:$PATH"
   ```
5. Reload your shell configuration:
   ```
   source ~/.bashrc  # or source ~/.zshrc if you use Zsh
   ```

### Dependencies

The installation script will attempt to install the following dependencies if they're not already present:
- `ffmpeg`: For audio conversion and duration checking
- `sed`: For filename cleaning (usually pre-installed on most Unix-like systems)

If the automatic installation fails, you may need to install these manually using your system's package manager.

## Usage

After installation, you can run the script from anywhere by typing:

```
audio_tools
```

The script will display a menu with options. Enter the number corresponding to the desired function and follow the prompts. By default, all functions will use the current directory as the working directory, but you can specify a different directory if needed.

## Functions

### Convert files to MP3

This function converts WAV, OGG, and FLAC files to MP3 format.

- You will be asked to provide the path to the folder containing the audio files (press Enter to use the current directory).
- The script will create a new folder named `converted_mp3` in the specified directory.
- All converted files will be saved in the `converted_mp3` folder.

### Remove short audio files

This function removes audio files shorter than a specified duration.

- You will be asked to provide the path to the folder containing the audio files (press Enter to use the current directory).
- You will need to specify the maximum duration (in seconds) for files to be deleted.
- The script will remove all audio files shorter than the specified duration.

### Scan and copy audio files from subfolders

This function scans the specified folder and its subfolders for audio files and copies them to a single folder.

- You will be asked to provide the path to the folder to scan (press Enter to use the current directory).
- The script will create a new folder named `ALL_AUDIOS` in the specified directory.
- All found audio files will be copied to the `ALL_AUDIOS` folder.

### Clean filenames

This function removes non-standard characters from filenames and replaces spaces with underscores.

- You will be asked to provide the path to the folder containing the files to be renamed (press Enter to use the current directory).
- The script will rename all files in the specified folder, removing non-standard characters and replacing spaces with underscores.

### Remove long audio files

This function removes audio files longer than a specified duration.

- You will be asked to provide the path to the folder containing the audio files (press Enter to use the current directory).
- You will need to specify the maximum duration (in seconds) for files to keep.
- The script will remove all audio files longer than the specified duration.

### Search and process audio files

This function searches for audio files containing a specific string in their filename and allows you to delete or extract them.

- You will be asked to provide the path to the folder to search (press Enter to use the current directory).
- You will need to enter a text string to search for in the filenames.
- The script will display the number of files found.
- You can choose to delete the found files or extract (copy) them to a new folder.
- If you choose to delete:
  - You will be asked for confirmation before proceeding.
  - The script will attempt to move files to the system trash.
  - If moving to trash fails, files will be moved to a "to_delete" folder within the search directory.
  - You will be informed of how many files were moved to trash, moved to the "to_delete" folder, or couldn't be moved.
- If you choose to extract:
  - Files will be copied to a new folder named after your search string within the search directory.

## Troubleshooting

- If you encounter a "command not found" error after installation, try restarting your terminal or running `source ~/.bashrc` (for Bash) or `source ~/.zshrc` (for Zsh).
- If the automatic dependency installation fails, you may need to install ffmpeg manually using your system's package manager.
- Make sure you have write permissions in the folders you're working with.
- If you're having issues with file paths, try using absolute paths instead of relative paths.
- If changes to your PATH are not taking effect, try logging out and back in to your system.
- If files can't be moved to the system trash, check if you have the necessary permissions and if your system's trash functionality is working correctly.
- If a "to_delete" folder is created, review its contents before manually deleting them, as these are files that couldn't be moved to the system trash.

For any other issues or questions, please open an issue on the GitHub repository or contact the script maintainer.