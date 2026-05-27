#!/usr/bin/env bash

# Pastikan skrip dijalankan dari direktori tempat skrip ini berada
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="/usr/local/bin"

echo "=== Memulai Instalasi Skrip ==="

# Cek apakah user menjalankan dengan sudo/root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Error: Skrip ini memerlukan hak akses root untuk membuat symlink di $TARGET_DIR"
    echo "Silakan jalankan ulang dengan: sudo ./install.sh"
    exit 1
fi

# Daftar file yang ingin diabaikan (tidak ingin dijadikan symlink)
EXCLUDE_LIST=("install.sh" "README.md" "LICENSE" ".gitignore")

# Loop semua file di direktori saat ini
for file in "$SCRIPT_DIR"/*; do
    # Ambil hanya nama filenya saja
    filename=$(basename "$file")

    # Lewati jika itu adalah direktori
    [ -d "$file" ] && continue

    # Lewati jika file ada di dalam daftar pengecualian
    if [[ " ${EXCLUDE_LIST[*]} " =~ " ${filename} " ]]; then
        continue
    fi

    # Pastikan file skrip asli memiliki izin eksekusi (chmod +x)
    chmod +x "$file"

    # Hapus ekstensi untuk nama symlink (menghilangkan .py, .sh, .fish, dll.)
    # ${filename%.*} akan mengambil nama file sebelum titik terakhir
    symlink_name="${filename%.*}"

    # Jika file aslinya memang tidak punya ekstensi (seperti 'showkeys'),
    # gunakan nama asli filenya agar tidak kosong atau rusak.
    if [ -z "$symlink_name" ]; then
        symlink_name="$filename"
    fi

    # Buat symlink di /usr/local/bin menggunakan nama tanpa ekstensi
    ln -sf "$file" "$TARGET_DIR/$symlink_name"

    echo "✅ Berhasil memasang: $symlink_name -> $file"
done

echo "=== Instalasi Selesai ==="
echo "Sekarang Anda bisa menjalankan skrip langsung menggunakan namanya di terminal."
