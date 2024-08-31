#!/bin/bash

# Function to convert files to MP3
convert_to_mp3() {
    read -p "Please enter the path to the folder containing the audio files: " source_folder

    if [ ! -d "$source_folder" ]; then
        echo "The specified folder does not exist."
        return
    fi

    output_folder="${source_folder}/converted_mp3"
    mkdir -p "$output_folder"

    find "$source_folder" -type f \( -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) | while read -r file; do
        echo "Converting: $file"
        output_file="${output_folder}/$(basename "${file%.*}").mp3"
        ffmpeg -i "$file" -acodec libmp3lame -b:a 320k -ar 44100 -ac 2 "$output_file"
    done

    echo "Conversion completed. MP3 files are located in: $output_folder"
}

# Function to remove short audio files
remove_short_audios() {
    read -p "Enter the path to the folder containing the audio files: " audio_folder

    if [ ! -d "$audio_folder" ]; then
        echo "The specified folder does not exist or is not accessible."
        return
    fi

    read -p "Enter the maximum duration in seconds for files to be deleted: " max_duration

    if ! [[ "$max_duration" =~ ^[0-9]+$ ]]; then
        echo "Please enter a valid number for the duration."
        return
    fi

    cd "$audio_folder" || return

    find . -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) -print0 | 
    while IFS= read -r -d '' file; do
        duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
        duration=${duration%.*}
        
        if [ "$duration" -lt "$max_duration" ]; then
            echo "Deleting $file (duration: $duration seconds)"
            rm "$file"
        fi
    done

    echo "Process completed. Audio files shorter than $max_duration seconds have been deleted from the folder $audio_folder."
}

# Function to scan and copy audio files from subfolders
scan_audios_subfolders() {
    read -p "Please enter the path of the folder to scan: " source_folder

    if [ ! -d "$source_folder" ]; then
        echo "Error: The specified folder does not exist."
        return
    fi

    destination_folder="$source_folder/ALL_AUDIOS"
    mkdir -p "$destination_folder"

    find "$source_folder" -type f | while read -r file; do
        if [[ "${file,,}" =~ \.(mp3|wav|ogg|flac|aac|wma|m4a)$ ]]; then
            base_name=$(basename "$file")
            destination="$destination_folder/$base_name"
            counter=1
            while [ -e "$destination" ]; do
                name="${base_name%.*}"
                extension="${base_name##*.}"
                destination="$destination_folder/${name}_${counter}.${extension}"
                ((counter++))
            done
            cp "$file" "$destination"
            echo "Copied: $file -> $destination"
        fi
    done

    echo "Process completed. All audio files have been copied to the ALL_AUDIOS folder."
}

# Function to clean filenames
clean_filenames() {
    read -p "Enter the folder path: " directory

    if [ ! -d "$directory" ]; then
        echo "The directory does not exist."
        return
    fi

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

    echo "Process completed."
}

# Function to remove long audio files
remove_long_audios() {
    read -p "Enter the path to the folder containing the audio files: " audio_folder

    if [ ! -d "$audio_folder" ]; then
        echo "The specified folder does not exist or is not accessible."
        return
    fi

    read -p "Enter the maximum duration in seconds for files to keep: " max_duration

    if ! [[ "$max_duration" =~ ^[0-9]+$ ]]; then
        echo "Please enter a valid number for the duration."
        return
    fi

    cd "$audio_folder" || return

    find . -type f \( -name "*.mp3" -o -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) -print0 | 
    while IFS= read -r -d '' file; do
        duration=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$file")
        duration=${duration%.*}
        
        if [ "$duration" -gt "$max_duration" ]; then
            echo "Deleting $file (duration: $duration seconds)"
            rm "$file"
        fi
    done

    echo "Process completed. Audio files longer than $max_duration seconds have been deleted from the folder $audio_folder."
}

# Main function
main() {
    while true; do
        echo "
Select an option:
1. Convert files to MP3
2. Remove short audio files
3. Scan and copy audio files from subfolders
4. Clean filenames
5. Remove long audio files
6. Exit
"
        read -p "Enter the number of the desired option: " choice

        case $choice in
            1) convert_to_mp3 ;;
            2) remove_short_audios ;;
            3) scan_audios_subfolders ;;
            4) clean_filenames ;;
            5) remove_long_audios ;;
            6) echo "Exiting the program."; exit 0 ;;
            *) echo "Invalid option. Please try again." ;;
        esac

        read -p "Do you want to perform another operation? (y/n): " continue
        if [[ ${continue,,} != "y" ]]; then
            echo "Exiting the program."
            break
        fi
    done
}

# Run the main function
main
