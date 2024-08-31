# Audio Tools Manual

This manual provides instructions for a set of Bash scripts designed to process audio files. Each script performs specific tasks to help manage and convert audio files efficiently.

## Scripts Overview

1. **audio_tool.sh**: A comprehensive script that combines multiple audio processing functions (clean filenames, remove short audios and mp3 conversion).
2. **clean_filenames.sh**: Cleans and standardizes filenames in a specified directory.
3. **scan_audios_subfolders**: Scans for audio files in subfolders and copies them to a central location.
4. **remove_short_audios.sh**: Removes audio files shorter than a specified duration.
5. **mp3_conversion.sh**: Converts audio files to MP3 format.

## Instructions

### 1. audio_tool.sh

This script combines multiple audio processing functions:
- Cleans filenames
- Removes short audio files
- Converts audio files to MP3 format

Usage:
```bash
./audio_tool.sh
```

Follow the prompts to specify the directory and duration threshold.

### 2. clean_filenames.sh

This script cleans and standardizes filenames in a specified directory.

Usage:
```bash
./clean_filenames.sh
```

Enter the directory path when prompted.

### 3. _

This_script scans for audio files in subfolders and copies them to a central location.

Usage:
```bash
./_
```

_rovide the path to the folder you want to scan when prompted.

### 4. remove_short_audios.sh

This script removes audio files shorter than a specified duration.

Usage:
```bash
./remove_short_audios.sh
```

Enter the directory path and the maximum duration in seconds when prompted.

### 5. mp3_conversion.sh

This script converts audio files to MP3 format.

Usage:
```bash
./mp3_conversion.sh
```

Provide the path to the folder containing the audio files when prompted.

To use these scripts, save each script as a separate file with a `.sh` extension. Make sure to set the correct permissions to make them executable using the command `chmod +x script_name.sh` before running them.
