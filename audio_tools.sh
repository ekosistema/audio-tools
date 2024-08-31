#!/bin/bash

# Función para ejecutar script de Python con heredoc
run_python_script() {
    python3 - "$@" << END
$1
END
}

# Función para obtener la ruta de la carpeta
get_folder_path() {
    local prompt="$1"
    local default_path="$(pwd)"
    read -p "${prompt} (press Enter for current folder [$default_path]): " user_input
    echo "${user_input:-$default_path}"
}

# Función para el audio shuffler
audio_shuffler() {
    run_python_script "
import os
import random
import subprocess
from pydub import AudioSegment
from tqdm import tqdm

def get_user_input():
    input_folder = input('Please enter the input folder path: ')
    min_duration = int(input('Please enter the minimum duration in seconds: '))
    max_duration = input('Please enter the maximum duration to trim (optional): ')
    max_duration = int(max_duration) if max_duration else None
    num_chunks = input('Please enter the number of chunks to split (default: 8): ')
    num_chunks = int(num_chunks) if num_chunks else 8
    
    return {
        'input_folder': input_folder,
        'min_duration': min_duration,
        'max_duration': max_duration,
        'num_chunks': num_chunks
    }

def process_audio_files(args):
    input_folder = args['input_folder']
    min_duration = args['min_duration']
    max_duration = args['max_duration']
    num_chunks = args['num_chunks']

    temp_folder = os.path.join(input_folder, '.temp')
    output_folder = os.path.join(input_folder, 'shuffled')
    
    os.makedirs(temp_folder, exist_ok=True)
    os.makedirs(output_folder, exist_ok=True)

    audio_files = [f for f in os.listdir(input_folder) if f.endswith(('.mp3', '.wav', '.ogg', '.flac'))]
    total_files = len(audio_files)
    
    print(f'Starting to process {total_files} files...')

    for index, file in enumerate(tqdm(audio_files, desc='Processing Files')):
        print(f'Processing file {index + 1}/{total_files}: {file}')
        
        input_path = os.path.join(input_folder, file)
        output_path = os.path.join(output_folder, f'shuffled_{file}')
        
        # Check file duration
        duration = get_audio_duration(input_path)
        
        if duration < min_duration:
            print(f'Skipping {file} (duration: {duration}s < minimum: {min_duration}s)')
            continue
        
        # Process the audio file
        audio = AudioSegment.from_file(input_path)
        
        if max_duration and duration > max_duration:
            audio = audio[:max_duration * 1000]  # Trim to max duration
        
        chunk_duration = int(len(audio) / num_chunks)  # Duration in milliseconds
        chunks = [audio[i*chunk_duration:(i+1)*chunk_duration] for i in range(num_chunks)]
        
        # Apply fade out to chunks
        fade_duration = len(audio) / 20  # 1/20 of the trimmed file duration
        chunks = [chunk.fade_out(duration=int(fade_duration)) for chunk in chunks]
        
        # Save chunks to temp folder
        chunk_files = []
        for i, chunk in enumerate(chunks):
            chunk_path = os.path.join(temp_folder, f'chunk_{i}_{file}')
            chunk.export(chunk_path, format=file.split('.')[-1])
            chunk_files.append(chunk_path)
        
        # Shuffle and concatenate chunks
        random.shuffle(chunk_files)
        shuffled_audio = AudioSegment.empty()
        for chunk_file in chunk_files:
            shuffled_audio += AudioSegment.from_file(chunk_file)
        
        # Apply fade in and fade out
        shuffled_audio = shuffled_audio.fade_in(50).fade_out(50)
        
        # Export the final audio
        shuffled_audio.export(output_path, format=file.split('.')[-1])
        
        # Clean up temp files
        for chunk_file in chunk_files:
            os.remove(chunk_file)
        
        print(f'Finished processing {file}')
    
    # Remove temp folder
    os.rmdir(temp_folder)
    
    print('All files processed successfully!')

def get_audio_duration(file_path):
    result = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', file_path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return float(result.stdout)

if __name__ == '__main__':
    args = get_user_input()
    process_audio_files(args)
"
}

# Función para el auto fader
auto_fader() {
    run_python_script "
import os
import sys
from pydub import AudioSegment
from tqdm import tqdm

def process_audio(file_path, max_duration, fade_duration, temp_folder, output_folder):
    # ... (rest of the auto_fader.py code) ...

def main():
    # ... (rest of the auto_fader.py code) ...

if __name__ == '__main__':
    main()
"
}

# Función para el auto looper
auto_looper() {
    run_python_script "
import os
import subprocess
import shutil
from tqdm import tqdm

def get_audio_duration(file_path):
    # ... (rest of the auto_looper.py code) ...

def process_audio(input_folder, min_duration, max_duration, iterations, fade_duration):
    # ... (rest of the auto_looper.py code) ...

def main():
    # ... (rest of the auto_looper.py code) ...

if __name__ == '__main__':
    main()
"
}

# Function to convert files to MP3
convert_to_mp3() {
    local source_folder=$(get_folder_path "Enter the path to the folder containing the audio files")

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
    local audio_folder=$(get_folder_path "Enter the path to the folder containing the audio files")

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
    local source_folder=$(get_folder_path "Enter the path of the folder to scan")

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
    local directory=$(get_folder_path "Enter the folder path")

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
    local audio_folder=$(get_folder_path "Enter the path to the folder containing the audio files")

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

# Function to search and process audio files
search_and_process_audios() {
    local initial_folder=$(get_folder_path "Enter the path of the folder to search")

    if [ ! -d "$initial_folder" ]; then
        echo "Error: The folder '$initial_folder' does not exist."
        return 1
    fi

    read -p "Enter the text string to search for: " search_string

    echo "Searching for audio files containing '$search_string' in '$initial_folder'..."

    found_files=$(find "$initial_folder" -type f \( -iname "*${search_string}*.mp3" -o -iname "*${search_string}*.wav" -o -iname "*${search_string}*.ogg" -o -iname "*${search_string}*.flac" \) )

    if [ -z "$found_files" ]; then
        echo "No audio files containing '$search_string' were found."
        return 0
    fi

    file_count=$(echo "$found_files" | wc -l)
    echo "$file_count files found:"
    echo "$found_files"

    while true; do
        read -p "What do you want to do? (d)elete or (e)xtract: " action
        case $action in
            [Dd]* ) 
                echo "Deleting files..."
                echo "$found_files" | while read -r file; do
                    rm -v "$file"
                done
                echo "Files deleted."
                break
                ;;
            [Ee]* )
                destination_folder="${initial_folder}/${search_string}"
                mkdir -p "$destination_folder"
                echo "Extracting files to $destination_folder..."
                echo "$found_files" | while read -r file; do
                    mv -v "$file" "$destination_folder/"
                done
                echo "Files extracted to $destination_folder"
                break
                ;;
            * ) echo "Please answer d for delete or e for extract.";;
        esac
    done
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
6. Search and process audio files
7. Audio Shuffler
8. Auto Fader
9. Auto Looper
10. Exit
"
        read -p "Enter the number of the desired option: " choice

        case $choice in
            1) convert_to_mp3 ;;
            2) remove_short_audios ;;
            3) scan_audios_subfolders ;;
            4) clean_filenames ;;
            5) remove_long_audios ;;
            6) search_and_process_audios ;;
            7) audio_shuffler ;;
            8) auto_fader ;;
            9) auto_looper ;;
            10) echo "Exiting the program."; exit 0 ;;
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
