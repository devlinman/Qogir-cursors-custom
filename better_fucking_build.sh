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


motherfucking_calculate_and_insert_size() {
    local cursor_file="$1"
    local new_size="$2"

    # skip if size already exists
    if awk '{print $1}' "$cursor_file" | grep -qx "$new_size"; then
        return
    fi

    # use last line as reference
    read -r last_size last_xhot last_yhot last_path < <(tail -n1 "$cursor_file")

    new_xhot=$(awk -v x="$last_xhot" -v ns="$new_size" -v ls="$last_size" \
        'BEGIN { printf "%.0f", x * ns / ls }')

    new_yhot=$(awk -v y="$last_yhot" -v ns="$new_size" -v ls="$last_size" \
        'BEGIN { printf "%.0f", y * ns / ls }')

    # clamp new hotspot
    (( new_xhot < 0 )) && new_xhot=0
    (( new_yhot < 0 )) && new_yhot=0
    (( new_xhot >= new_size )) && new_xhot=$((new_size - 1))
    (( new_yhot >= new_size )) && new_yhot=$((new_size - 1))

    new_path=$(echo "$last_path" | sed -E "s/[0-9]+x[0-9]+/${new_size}x${new_size}/")
    new_line="$new_size $new_xhot $new_yhot $new_path"

    tmp=$(mktemp)

    awk -v newline="$new_line" -v size="$new_size" '
        BEGIN { inserted=0 }
        {
            if (!inserted && $1 > size) {
                print newline
                inserted=1
            }
            print
        }
        END { if (!inserted) print newline }
    ' "$cursor_file" > "$tmp"

    mv "$tmp" "$cursor_file"
}


fucking_calculate() {
    echo "Preparing temp cursor config..."

    rm -rf "$TEMP_CONFIG"
    cp -r "$SRC/config" "$TEMP_CONFIG"

    # copy generated Png folders beside cursor files
    for size in "${SIZES[@]}"; do
        cp -r "$SRC/${size}x${size}" "$TEMP_CONFIG/"
    done

    for CUR in "$TEMP_CONFIG"/*.cursor; do
        # add missing sizes
        for size in "${SIZES[@]}"; do
            motherfucking_calculate_and_insert_size "$CUR" "$size"
        done

        tmp=$(mktemp)

        awk -v sizes="${SIZES[*]}" '
        BEGIN {
            split(sizes, allowed)
            for (i in allowed) ok[allowed[i]] = 1
        }
        {
            line=$0
            sub(/^[ \t]+/, "", line)
            if (line == "" || line ~ /^#/) next

            split(line, f, " ")
            size=f[1]
            xhot=f[2]
            yhot=f[3]
            path=f[4]

            if (size in ok) {
                sub(/[0-9]+x[0-9]+/, size "x" size, path)

                if (xhot < 0) xhot = 0
                if (yhot < 0) yhot = 0
                if (xhot >= size) xhot = size - 1
                if (yhot >= size) yhot = size - 1

                print size, xhot, yhot, path
            }
        }
        ' "$CUR" > "$tmp"

        mv "$tmp" "$CUR"
    done

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
        echo -e "\nNow working with: $CUR"
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
}


SRC="$PWD/src"
TEMP_CONFIG="$SRC/temp-config"

SIZES=(40)
THEME="Qogir-white Cursors"
BUILD="$SRC/../dist-Dark"

fucking_create_with_ "svg-Dark"
fucking_calculate
fucking_dist

rm -rf "$TEMP_CONFIG"
