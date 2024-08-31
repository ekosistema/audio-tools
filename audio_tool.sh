#!/bin/bash

# 1. Request the folder path
read -p "Enter the path of the folder containing the audio files: " directory

# Verify if the folder exists
if [ ! -d "$directory" ]; then
    echo "The specified directory does not exist."
    exit 1
fi

# 2. Clean file names
echo "Renaming files in the folder..."

for file in "$directory"/*; do
    if [ -f "$file" ]; then
        dir=$(dirname "$file")
        filename=$(basename "$file")
        newname=$(echo "$filename" | sed -e 's/[^A-Za-z0-9._-]//g' -e 's/ /_/g')
        if [ "$filename" != "$newname" ]; then
            mv "$file" "$dir/$newname"
            echo "Renamed: $filename -> $newname"
        fi
    fi
done

echo "File name cleaning completed."

# 3. Remove short audios
while true; do
    read -p "Enter the maximum duration in seconds to delete audio files: " max_duration
    if [[ "$max_duration" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        break
    else
        echo "Please enter a valid number for the duration."
    fi
done

echo "Removing short audio files..."

cd "$directory" || exit 1

find . -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) -print0 | 
while IFS= read -r -d '' file; do
    duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
    
    if (( $(echo "$duration < $max_duration" | bc -l) )); then
        echo "Removing $file (duration: $duration seconds)"
        rm "$file"
    fi
done

echo "Removal of short files completed."

# 4. Convert audios to MP3
output_folder="${directory}/converted_mp3"
mkdir -p "$output_folder"

echo "Converting audio files to MP3..."

convert_to_mp3() {
    input_file="$1"
    output_file="${output_folder}/$(basename "${input_file%.*}").mp3"
    ffmpeg -i "$input_file" -acodec libmp3lame -b:a 320k -ar 44100 -ac 2 "$output_file"
}

find "$directory" -type f \( -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) | while read -r file; do
    echo "Converting: $file"
    convert_to_mp3 "$file"
done

echo "MP3 conversion completed. MP3 files are located in: $output_folder"

echo "Process complete."