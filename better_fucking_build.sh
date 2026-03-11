#!/bin/bash
set -Eueo pipefail


fucking_create_with_() {
    local input_svg_folder="$1"
    local input_dir="$SRC/$input_svg_folder"

    command -v inkscape >/dev/null 2>&1 || {
        echo "Error: inkscape is not installed."
        exit 1
    }

    for size in "${SIZES[@]}"; do
        local output_dir="$SRC/${size}x${size}"
        mkdir -p "$output_dir"

        echo "Rendering ${size}px PNGs → ${size}x${size}/"

        find "$input_dir" -type f -name "*.svg" -print0 | while IFS= read -r -d '' file; do
            rel="${file#$input_dir/}"
            rel_no_ext="${rel%.svg}"
            out="$output_dir/$rel_no_ext.png"

            mkdir -p "$(dirname "$out")"

            env -u GTK_MODULES -u QT_QPA_PLATFORMTHEME \
                inkscape \
                    --export-type=png \
                    --export-filename="$out" \
                    --export-width="$size" \
                    --export-height="$size" \
                    "$file" >/dev/null 2>&1
        done
    done

    echo "PNGs generation DONE"
}


fucking_calculate() {
    echo "Preparing temp cursor config..."

    rm -rf "$TEMP_CONFIG"
    mkdir -p "$TEMP_CONFIG"

    # copy generated Png folders beside cursor files
    for size in "${SIZES[@]}"; do
        cp -r "$SRC/${size}x${size}" "$TEMP_CONFIG/"
    done

    python3 -c '
import os
import json
import sys

src_dir = sys.argv[1]
temp_config_dir = sys.argv[2]
sizes = [int(x) for x in sys.argv[3:]]

config_dir = os.path.join(src_dir, "config")
scalable_dir = os.path.join(src_dir, "scalable")

for cursor_file in os.listdir(config_dir):
    if not cursor_file.endswith(".cursor"):
        continue
    
    cursor_name = cursor_file[:-7]
    metadata_path = os.path.join(scalable_dir, cursor_name, "metadata.json")
    
    if not os.path.exists(metadata_path):
        print(f"Warning: {metadata_path} not found for {cursor_name}")
        continue
        
    with open(metadata_path, "r") as f:
        metadata = json.load(f)
        
    out_lines = []
    for size in sizes:
        for frame in metadata:
            filename = frame["filename"]
            png_name = filename.rsplit(".", 1)[0] + ".png"
            hotspot_x = float(frame["hotspot_x"])
            hotspot_y = float(frame["hotspot_y"])
            nominal_size = float(frame["nominal_size"])
            
            xhot = int(round(hotspot_x * size / nominal_size))
            yhot = int(round(hotspot_y * size / nominal_size))
            
            # clamp new hotspot
            if xhot < 0: xhot = 0
            if yhot < 0: yhot = 0
            if xhot >= size: xhot = size - 1
            if yhot >= size: yhot = size - 1
            
            delay = frame.get("delay")
            if delay is not None:
                out_lines.append(f"{size} {xhot} {yhot} {size}x{size}/{png_name} {delay}\n")
            else:
                out_lines.append(f"{size} {xhot} {yhot} {size}x{size}/{png_name}\n")
                
    with open(os.path.join(temp_config_dir, cursor_file), "w") as f:
        f.writelines(out_lines)
' "$SRC" "$TEMP_CONFIG" "${SIZES[@]}"

    echo "Temp config ready"
}

fucking_dist() {
    cd "$SRC"

    OUTPUT="$BUILD/cursors"
    ALIASES="$SRC/cursorList"

    mkdir -p "$BUILD" "$OUTPUT"

    command -v xcursorgen >/dev/null 2>&1 || {
        echo "Error: xorg-xcursorgen is not installed."
        exit 1
    }

    echo "Generating cursor theme..."

    for CUR in "$TEMP_CONFIG"/*.cursor; do
#         echo -e "\nNow working with: $CUR"
        BASENAME="$(basename "$CUR" .cursor)"
        xcursorgen "$CUR" "$OUTPUT/$BASENAME"
    done

    echo "Generating shortcuts..."
    cd "$OUTPUT"
    while read -r ALIAS; do
        FROM="${ALIAS#* }"
        TO="${ALIAS% *}"
        [ -e "$TO" ] || ln -sr "$FROM" "$TO"
    done < "$ALIASES"

    echo "Generating Theme Index..."
    INDEX="$BUILD/index.theme"
    echo -e "[Icon Theme]\nName=$THEME\n" > "$INDEX"

    echo "Build DONE"
    for size in "${SIZES[@]}"; do
        local output_dir="$SRC/${size}x${size}"
        rm -rf "$output_dir"
    done

}


SRC="$PWD/src"
TEMP_CONFIG="$SRC/temp-config"

SIZES=(48 54 60 68 128)
THEME="Qogir-white Cursors"
BUILD="$SRC/../dist-Dark"
rm -rf $BUILD

fucking_create_with_ "svg-Dark"
fucking_calculate
fucking_dist

rm -rf "$TEMP_CONFIG"
