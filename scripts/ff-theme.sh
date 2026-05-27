#!/usr/bin/env bash

THEME_DIR="$HOME/.config/fastfetch/themes"
TARGET="$HOME/.config/fastfetch/config.jsonc"

# cek fzf
if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf tidak ditemukan. Install dulu: sudo pacman -S fzf"
    exit 1
fi

# ambil list theme (hanya nama file)
THEME=$(find "$THEME_DIR" -maxdepth 1 -type f -name "*.jsonc" \
    -exec basename {} \; | sort | fzf \
    --prompt="Select Fastfetch Theme > " \
    --height=40% \
    --border \
    --preview="bat --style=numbers --color=always $THEME_DIR/{} 2>/dev/null || cat $THEME_DIR/{}"
)

# cancel
if [ -z "$THEME" ]; then
    echo "Cancelled."
    exit 0
fi

# buat symlink
ln -sf "$THEME_DIR/$THEME" "$TARGET"

echo "Theme applied: $THEME"

# optional langsung run fastfetch
fastfetch
