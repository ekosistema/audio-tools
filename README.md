# Audio Tools Script Manual

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Usage](#usage)
4. [Functions](#functions)
   1. [Convert files to MP3](#convert-files-to-mp3)
   2. [Remove short audio files](#remove-short-audio-files)
   3. [Scan and copy audio files from subfolders](#scan-and-copy-audio-files-from-subfolders)
   4. [Clean filenames](#clean-filenames)
   5. [Remove long audio files](#remove-long-audio-files)
5. [Troubleshooting](#troubleshooting)

## Introduction

The Audio Tools script is a comprehensive audio processing tool that combines multiple functionalities for managing audio files. It allows you to convert audio files to MP3, remove short or long audio files, scan and copy audio files from subfolders, and clean filenames.

## Installation

There are two ways to install the Audio Tools script:

### Method 1: Manual Installation

1. Save the script to a file named `audio_tools.sh`.
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

### Method 2: Automated Installation

1. Save the installation script provided earlier as `install_audio_tools.sh` in the same directory as your `audio_tools.sh`.
2. Give the installation script execution permissions:
   ```
   chmod +x install_audio_tools.sh
   ```
3. Run the installation script:
   ```
   ./install_audio_tools.sh
   ```
4. After the installation, restart your terminal or run `source ~/.bashrc` (for Bash) or `source ~/.zshrc` (for Zsh) to apply the changes.

### Dependencies

Ensure you have the following dependencies installed:
- `ffmpeg`: For audio conversion and duration checking
- `sed`: For filename cleaning (usually pre-installed on most Unix-like systems)

## Usage

After installation, you can run the script from anywhere by typing:

```
audio_tools
```

The script will display a menu with options. Enter the number corresponding to the desired function and follow the prompts.

## Functions

### Convert files to MP3

This function converts WAV, OGG, and FLAC files to MP3 format.

- You will be asked to provide the path to the folder containing the audio files.
- The script will create a new folder named `converted_mp3` in the specified directory.
- All converted files will be saved in the `converted_mp3` folder.

### Remove short audio files

This function removes audio files shorter than a specified duration.

- You will be asked to provide the path to the folder containing the audio files.
- You will need to specify the maximum duration (in seconds) for files to be deleted.
- The script will remove all audio files shorter than the specified duration.

### Scan and copy audio files from subfolders

This function scans the specified folder and its subfolders for audio files and copies them to a single folder.

- You will be asked to provide the path to the folder to scan.
- The script will create a new folder named `ALL_AUDIOS` in the specified directory.
- All found audio files will be copied to the `ALL_AUDIOS` folder.

### Clean filenames

This function removes non-standard characters from filenames and replaces spaces with underscores.

- You will be asked to provide the path to the folder containing the files to be renamed.
- The script will rename all files in the specified folder, removing non-standard characters and replacing spaces with underscores.

### Remove long audio files

This function removes audio files longer than a specified duration.

- You will be asked to provide the path to the folder containing the audio files.
- You will need to specify the maximum duration (in seconds) for files to keep.
- The script will remove all audio files longer than the specified duration.

## Troubleshooting

- If you encounter a "command not found" error, make sure the script is in a directory included in your PATH.
- If ffmpeg is not installed, you may need to install it using your system's package manager.
- Make sure you have write permissions in the folders you're working with.
- If you're having issues with file paths, try using absolute paths instead of relative paths.
- If changes to your PATH are not taking effect, try restarting your terminal or running `source ~/.bashrc` or `source ~/.zshrc`.

For any other issues or questions, please contact the script maintainer.
