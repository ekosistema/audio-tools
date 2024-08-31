#!/bin/bash

# Solicitar al usuario la carpeta de origen
read -p "Por favor, ingrese la ruta de la carpeta que contiene los archivos de audio: " source_folder

# Verificar si la carpeta existe
if [ ! -d "$source_folder" ]; then
    echo "La carpeta especificada no existe."
    exit 1
fi

# Crear una carpeta para los archivos convertidos
output_folder="${source_folder}/converted_mp3"
mkdir -p "$output_folder"

# Función para convertir un archivo a MP3
convert_to_mp3() {
    input_file="$1"
    output_file="${output_folder}/$(basename "${input_file%.*}").mp3"
    ffmpeg -i "$input_file" -acodec libmp3lame -b:a 320k -ar 44100 -ac 2 "$output_file"
}

# Buscar y convertir archivos WAV, OGG y FLAC
find "$source_folder" -type f \( -name "*.wav" -o -name "*.ogg" -o -name "*.flac" \) | while read -r file; do
    echo "Convirtiendo: $file"
    convert_to_mp3 "$file"
done

echo "Conversión completada. Los archivos MP3 se encuentran en: $output_folder"
