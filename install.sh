#!/usr/bin/env bash

# 1. Tentukan konstanta direktori
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SCRIPTS_DIR="$REPO_DIR/scripts"
TARGET_DIR="/usr/local/bin"

echo "=== Memulai Instalasi Skrip dari Folder GitHub ==="

# 2. Pastikan folder 'scripts' benar-benar ada di repo
if [ ! -d "$SRC_SCRIPTS_DIR" ]; then
    echo "❌ Error: Folder '$SRC_SCRIPTS_DIR' tidak ditemukan!"
    echo "Pastikan folder 'scripts' ada di dalam repositori sebelum menjalankan instalasi."
    exit 1
fi

# 3. Cek apakah user menjalankan dengan sudo/root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Skrip ini memerlukan hak akses root untuk membuat symlink di $TARGET_DIR"
    echo "Silakan jalankan ulang dengan: sudo ./install.sh"
    exit 1
fi

# 4. Deteksi home directory user asli ($SUDO_USER) agar folder tidak dimiliki root
USER_HOME=$(eval echo "~$SUDO_USER")
LOCAL_BIN_REAL="$USER_HOME/.local/bin"

if [ ! -d "$LOCAL_BIN_REAL" ]; then
    echo "📁 Membuat direktori penyimpanan lokal: $LOCAL_BIN_REAL"
    mkdir -p "$LOCAL_BIN_REAL"
    chown "$SUDO_USER":"$SUDO_USER" "$LOCAL_BIN_REAL"
fi

# 5. Loop semua file yang HANYA ada di dalam folder 'scripts'
for file in "$SRC_SCRIPTS_DIR"/*; do
    filename=$(basename "$file")

    # Lewati jika itu adalah direktori (jika ada sub-folder di dalam folder scripts)
    [ -d "$file" ] && continue

    # Proteksi jika folder scripts kosong agar tidak memproses karakter wildcard '*'
    [ "$filename" = "*" ] && echo "⚠️ Folder 'scripts' kosong." && break

    # 6. Salin file dari folder repo/scripts ke ~/.local/bin
    dest_file="$LOCAL_BIN_REAL/$filename"
    cp "$file" "$dest_file"
    
    # Berikan izin eksekusi pada file yang sudah dipindahkan ke lokal
    chmod +x "$dest_file"
    chown "$SUDO_USER":"$SUDO_USER" "$dest_file"

    # 7. Proses pemotongan ekstensi untuk nama symlink global
    symlink_name="${filename%.*}"
    if [ -z "$symlink_name" ]; then
        symlink_name="$filename"
    fi

    # 8. Buat symlink di /usr/local/bin mengarah ke file di ~/.local/bin
    ln -sf "$dest_file" "$TARGET_DIR/$symlink_name"

    echo "✅ Dipasang: scripts/$filename -> $dest_file -> $TARGET_DIR/$symlink_name"
done

echo "=== Instalasi Selesai ==="
echo "Semua utilitas dari folder 'scripts' berhasil dipasang ke sistem Anda!"
