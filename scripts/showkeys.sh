#!/bin/bash

JSON_FILE="$(dirname "$(realpath "$0")")/utils/keybind_help.json"

# =========================================================
# CHECK FILE
# =========================================================

if [[ ! -f "$JSON_FILE" ]]; then
    echo "JSON file not found: $JSON_FILE" >&2
    exit 1
fi

# =========================================================
# BUILD MENU
# =========================================================

menu=$(
    jq -r '
    to_entries[]
    | .key as $category
    | .value[]
    | select(.hidden != true)
    | [
        (.id | tostring),

        (
            (.category_icon // " ")
            + "  "
            + (.display // .key)
        ),

        (
            if .repeatable == true
            then "[R]"
            else "   "
            end
        ),

        (
            if .dangerous == true
            then "[!]"
            else "   "
            end
        ),

        .description
      ]
    | @tsv
    ' "$JSON_FILE"
)

# =========================================================
# FORMAT
# =========================================================

formatted=$(
    echo "$menu" | column -t -s $'\t'
)

separator=$(printf '─%.0s' {1..120})

header="ID   KEYBIND                            REP  DNG  DESCRIPTION"

full_menu="$header
$separator
$formatted"

# =========================================================
# SHOW MENU
# =========================================================

selected=$(
    echo "$full_menu" \
    | fuzzel --dmenu \
        --font "JetBrainsMono Nerd Font:size=12" \
        --lines 40 \
        --width 140 \
        --horizontal-pad 20 \
        --vertical-pad 12 \
        --prompt "󱄅 Hyprland Keys > "
)

# =========================================================
# EXIT
# =========================================================

[[ -z "$selected" ]] && exit 0

# =========================================================
# OPTIONAL:
# COPY SELECTED ENTRY
# =========================================================

echo "$selected"