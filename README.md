# sysutils - Kumpulan Utilitas Sistem dan Skrip Pembantu

Repositori ini berisi koleksi skrip shell dan Python yang dirancang untuk mempermudah manajemen sistem, otomatisasi tugas, dan kustomisasi pada lingkungan Linux, khususnya Arch Linux dan Hyprland, serta utilitas untuk perangkat Android.

## Fitur Utama

*   **Instalasi & Pengelolaan Skrip:** Memasang dan mengelola skrip utilitas secara sistem-wide, membuatnya mudah diakses dari terminal.
*   **Manajemen Keybind Hyprland:** Alat untuk menampilkan, memeriksa ketersediaan, dan mengelola konfigurasi keybind Hyprland.
*   **Penggantian Tema SDDM:** Memilih dan menerapkan tema untuk SDDM (Simple Desktop Display Manager) dengan opsi pratinjau dan logging.
*   **Alias PWA (Progressive Web App):** Membuat alias shell dan skrip launcher untuk PWA dari Brave dan Firefox, menyederhanakan peluncuran aplikasi web.
*   **Manajemen Kernel UKI Arch Linux:** Memasang kernel, mengonfigurasi Unified Kernel Image (UKI), mengelola entri boot EFI, dan mengontrol urutan boot.
*   **Debloating Android:** Skrip untuk menghapus bloatware dari perangkat Android menggunakan ADB (Android Debug Bridge).
*   **Penggantian Tema Fastfetch:** Memilih dan menerapkan tema untuk Fastfetch, alat informatif sistem.

## Instalasi

### Prasyarat

Beberapa skrip memerlukan alat atau lingkungan tertentu untuk berfungsi dengan baik:

*   **`sudo`**: Diperlukan untuk instalasi sistem-wide dan operasi yang memerlukan hak akses root.
*   **`adb`**: Diperlukan untuk skrip `debloat.sh` (Android Debug Bridge).
*   **`fzf`**: Diperlukan untuk `showkeys.sh`, `sddm-theme.sh`, dan `ff-theme.sh` (fuzzy finder interaktif).
*   **`jq`**: Diperlukan oleh `showkeys.sh` untuk memproses data JSON.
*   **`efibootmgr`**: Diperlukan oleh `kernel-manager.sh` untuk mengelola entri boot EFI.
*   **`mkinitcpio`**: Diperlukan oleh `kernel-manager.sh` untuk menghasilkan UKI.
*   **`python3`**: Diperlukan untuk skrip Python seperti `hyprkeys.py` dan `check-keybind.py`.
*   **`fish` shell**: Diperlukan untuk skrip `rename-pwa.sh` dan `generate-pwa-alias.sh`.
*   **`bat`**: (Opsional) Untuk pratinjau tema Fastfetch yang lebih baik di `ff-theme.sh`.

### Cara Menginstal

1. **Clone repositori:**
    ```bash
    git clone https://github.com/SkaSka0/sysutils.git
    cd sysutils
    ```

2. **Berikan izin eksekusi dan jalankan skrip instalasi:**
    Skrip `install.sh` akan menyalin semua utilitas dari folder `scripts/` ke folder lokal Anda (`~/.local/bin`) secara otomatis, lalu membuat symlink global di `/usr/local/bin` tanpa ekstensi file.

    ```bash
    chmod +x install.sh
    sudo ./install.sh
    ```
    *Catatan: Hak akses `sudo` hanya diperlukan saat pembuatan symlink global di direktori sistem `/usr/local/bin`.*

## Penggunaan

Setelah instalasi, Anda dapat menjalankan skrip-skrip ini langsung dari terminal Anda.

---

### `showkeys` (scripts/showkeys.sh)

Menampilkan daftar keybind Hyprland yang dikonfigurasi secara interaktif menggunakan `fuzzel` (atau `fzf` sebagai fallback). Skrip ini membaca data keybind dari file JSON untuk menyajikan informasi yang rapi.

**Contoh:**
```bash
showkeys
```

---

### `sddm-theme` (scripts/sddm-theme.sh)

Alat untuk mengelola dan mengganti tema SDDM. Mendukung pemilihan interaktif menggunakan `fzf`, daftar tema yang tersedia, menampilkan tema aktif saat ini, dan opsi untuk restart SDDM.

**Contoh:**
```bash
sddm-theme                  # Mode interaktif
sddm-theme --list           # Daftar tema
sddm-theme --set sugar-dark # Terapkan tema langsung
sddm-theme --current        # Tampilkan tema aktif
sddm-theme --log            # Tampilkan log aktivitas
sddm-theme --tail-log       # Monitor log secara realtime
```

---

### `rename-pwa` (scripts/rename-pwa.sh)

Mengganti nama file `.desktop` Brave PWA di `~/.local/share/applications` menjadi format yang lebih rapi (misalnya, dari `brave-*.desktop` menjadi `Nama_Aplikasi.desktop`). Berguna untuk manajemen ikon yang lebih baik.

**Opsi:**
*   `-o, --output DIR`: Menentukan direktori output untuk symlink (default: `~/.local/share/applications`).
*   `-n, --dry-run`: Hanya menampilkan apa yang akan dilakukan, tanpa membuat symlink.
*   `-f, --force`: Menimpa symlink yang sudah ada.
*   `-l, --list`: Daftar aplikasi Brave PWA yang terdeteksi.

**Contoh:**
```bash
rename-pwa
rename-pwa --dry-run
rename-pwa --list
```

---

### `kernel-manager` (scripts/kernel-manager.sh)

Manajer kernel untuk Arch Linux yang mendukung Unified Kernel Image (UKI). Memungkinkan instalasi kernel, konfigurasi preset `mkinitcpio`, pembuatan entri boot EFI, dan pengelolaan urutan boot.

**Opsi:**
*   `-h, --help`: Menampilkan menu bantuan.
*   `-n, --dry-run`: Menampilkan perintah tanpa mengeksekusinya.

**Contoh:**
```bash
sudo kernel-manager            # Memulai menu interaktif
sudo kernel-manager --dry-run  # Menjalankan dalam mode dry-run
```

---

### `hyprkeys` (scripts/hyprkeys.py)

Skrip Python untuk menghasilkan, menambah, memperbarui, dan menghapus entri keybind dalam format JSON. Otomatis menghasilkan metadata seperti `normalized_key`, `repeatable`, dan `dangerous` untuk setiap keybind.

**Contoh:**
```bash
# Generate metadata dari input.json ke output.json
hyprkeys input.json -o output.json

# Tambah entri baru
hyprkeys input.json -o output.json \
  --add "SUPER+Q" "killactive" "bind" "Close active window" \
  --category window_actions

# Update entri
hyprkeys keybinds.json \
  --update 10 \
  --updates key=SUPER+W description="New Description"

# Hapus entri
hyprkeys keybinds.json --delete 5
```

---

### `generate-pwa-alias` (scripts/generate-pwa-alias.sh)

Membuat alias Fish shell dan skrip launcher di `~/.local/bin/utils` untuk Progressive Web Apps (PWA) yang terdeteksi dari Brave dan Firefox. Membantu meluncurkan PWA dengan nama pendek.

**Opsi:**
*   `-l, --list`: Daftar aplikasi PWA yang terdeteksi (Nama + path).
*   `-p, --prefix PREFIX`: Menentukan awalan untuk alias (default: `app_`).

**Contoh:**
```bash
generate-pwa-alias              # Buat alias dan launcher
generate-pwa-alias --list       # Daftar PWA yang akan dibuat alias
generate-pwa-alias -p myapp_    # Gunakan awalan kustom
```

---

### `ff-theme` (scripts/ff-theme.sh)

Skrip sederhana untuk mengganti tema Fastfetch secara interaktif menggunakan `fzf`. Menampilkan pratinjau tema sebelum menerapkan.

**Contoh:**
```bash
ff-theme
```

---

### `debloat` (scripts/debloat.py)

Skrip bash untuk menghapus bloatware dari perangkat Android yang terhubung via ADB. Daftar bloatware dapat dikonfigurasi dalam skrip.

**Prasyarat:**
*   Perangkat Android terhubung dan `adb` diinstal.

**Contoh:**
```bash
debloat
```

---

### `check-keybind` (scripts/check-keybind.py)

Memeriksa apakah kombinasi keybind Hyprland yang diberikan sudah digunakan dalam file JSON keybind. Berguna untuk menghindari konflik saat mengonfigurasi keybind baru.

**Contoh:**
```bash
check-keybind "SUPER, C"
check-keybind "CTRL, ALT, T"
```

## Kontribusi

Kontribusi disambut baik! Jika Anda memiliki ide untuk skrip baru, perbaikan bug, atau peningkatan fitur, silakan buka _issue_ atau kirim _pull request_.

## Lisensi

Proyek ini dilisensikan di bawah [LICENSE](LICENSE).
