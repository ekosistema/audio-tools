#!/bin/bash

# Ask the user for the folder where the audio files are located
read -p "Enter the path to the folder containing the audio files: " audio_folder

# Check if the folder exists
if [ ! -d "$audio_folder" ]; then
    echo "The specified folder does not exist or is not accessible."
    exit 1
fi

# Ask the user for the maximum duration in seconds
read -p "Enter the maximum duration in seconds for files to be deleted: " max_duration

# Check if a valid number was entered
if ! [[ "$max_duration" =~ ^[0-9]+$ ]]; then
    echo "Please enter a valid number for the duration."
    exit 1
fi

# Change to the specified directory
cd "$audio_folder" || exit 1

# Find and delete audio files shorter than the specified duration
find . -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) -print0 | 
while IFS= read -r -d '' file; do
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
    duration=${duration%.*}  # Remove decimals
    
    if [ "$duration" -lt "$max_duration" ]; then
        echo "Deleting $file (duration: $duration seconds)"
        rm "$file"
    fi
done

echo "Process completed. Audio files shorter than $max_duration seconds have been deleted from the folder $audio_folder."
