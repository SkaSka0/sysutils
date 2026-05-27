#!/usr/bin/env bash
set -euo pipefail

# =========================================================
# Arch Linux UKI Kernel Manager (Enhanced)
# =========================================================
# Features:
# - Install kernel + UKI
# - EFI boot entry management
# - Boot order control
# - Duplicate detection
# - Dry-run mode
# - Help system
# =========================================================

ESP_MOUNT="/boot"
EFI_DIR="$ESP_MOUNT/EFI/Linux"
PRESET_DIR="/etc/mkinitcpio.d"

DRY_RUN=0

# =========================================================
# Utils
# =========================================================

log() { echo -e "[INFO] $*"; }
ok()  { echo -e "[OK]   $*"; }
err() { echo -e "[ERR]  $*"; }

run() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[DRY-RUN] $*"
    else
        eval "$@"
    fi
}

pause() {
    echo
    read -rp "Enter to continue..."
}

header() {
    clear
    echo "========================================"
    echo " Arch Linux UKI Kernel Manager"
    echo "========================================"
    echo
}

# =========================================================
# Help
# =========================================================

help_menu() {
cat <<EOF
Arch Linux UKI Kernel Manager

USAGE:
  sudo kernel-manager [options]

OPTIONS:
  -h, --help      Show help
  -n, --dry-run   Show commands without executing

FEATURES:
  1. Install kernel (linux, linux-zen, linux-lts)
  2. Auto configure UKI via mkinitcpio preset
  3. Create EFI boot entry
  4. Detect duplicate entries
  5. Manage boot order
  6. Delete EFI entry

EXAMPLES:
  sudo kernel-manager
  sudo kernel-manager --dry-run
EOF
}

# =========================================================
# Args
# =========================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                help_menu
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=1
                shift
                ;;
            *)
                # Diganti agar tidak memicu error dari set -e saat geser argumen kosong
                shift || true
                ;;
        esac
    done
}

# =========================================================
# Checks
# =========================================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Run as root"
        exit 1
    fi
}

check_tools() {
    for t in pacman mkinitcpio efibootmgr findmnt lsblk; do
        command -v "$t" >/dev/null || { err "Missing: $t"; exit 1; }
    done
}

check_esp() {
    mountpoint -q "$ESP_MOUNT" || {
        err "ESP not mounted at $ESP_MOUNT"
        exit 1
    }
    mkdir -p "$EFI_DIR"
}

# =========================================================
# Kernel helpers
# =========================================================

uki_name() {
    echo "arch-${1}.efi"
}

kernel_image() {
    echo "/boot/vmlinuz-${1}"
}

preset_file() {
    echo "$PRESET_DIR/${1}.preset"
}

# =========================================================
# Duplicate detection
# =========================================================

efi_exists() {
    efibootmgr | grep -qi "$1"
}

# =========================================================
# UKI preset config
# =========================================================

configure_preset() {
    local k="$1"
    local preset
    preset="$(preset_file "$k")"

    [[ -f "$preset" ]] || { err "Preset not found: $preset"; return 1; }

    log "Configuring preset: $k"

    run "sed -i '/^default_uki=/d' '$preset'"
    run "sed -i '/^#default_uki=/d' '$preset'"

    cat >> "$preset" <<EOF

default_uki="/boot/EFI/Linux/$(uki_name "$k")"
default_options="--splash /usr/share/systemd/bootctl/splash-arch.bmp"
EOF

    ok "Preset updated"
}

# =========================================================
# Generate UKI
# =========================================================

generate_uki() {
    log "Generating UKI for $1"
    run "mkinitcpio -p $1"
    ok "UKI generated"
}

# =========================================================
# EFI entry
# =========================================================

create_efi_entry() {
    local k="$1"
    local label="$2"
    local file="$(uki_name "$k")"

    if efibootmgr | grep -qi "$label"; then
        err "EFI entry already exists: $label"
        return 1
    fi

    EFI_SOURCE=$(findmnt -no SOURCE "$ESP_MOUNT")
    DISK="/dev/$(lsblk -no pkname "$EFI_SOURCE")"
    
    # Cara alternatif yang lebih aman tanpa kolom PARTNUM
    PART=$(cat "/sys/class/block/${EFI_SOURCE##*/}/partition")

    log "Creating EFI entry: $label"

    run "efibootmgr --create \
        --disk $DISK \
        --part $PART \
        --label '$label' \
        --loader \"\\\\EFI\\\\Linux\\\\$file\""

    ok "EFI entry created"
}

# =========================================================
# Install kernel
# =========================================================

install_kernel() {
    read -rp "Kernel (linux / linux-zen / linux-lts): " k

    [[ -z "$k" ]] && { err "Empty kernel"; return; }

    log "Installing $k"

    run "pacman -S --needed $k"

    if pacman -Si "${k}-headers" &>/dev/null; then
        run "pacman -S --needed ${k}-headers"
    fi

    configure_preset "$k"
    generate_uki "$k"

    read -rp "EFI Label (default: $k): " label
    label="${label:-$k}"

    create_efi_entry "$k" "$label"
}

# =========================================================
# Boot order
# =========================================================

boot_order() {
    efibootmgr
    echo
    read -rp "Boot order (0001,0002,...): " o
    [[ -z "$o" ]] && return
    run "efibootmgr --bootorder $o"
    ok "Boot order updated"
}

# =========================================================
# Delete entry
# =========================================================

delete_entry() {
    efibootmgr
    echo
    read -rp "Boot number (0001): " b
    [[ -z "$b" ]] && return
    run "efibootmgr --delete-bootnum --bootnum $b"
    ok "Deleted $b"
}

# =========================================================
# Menu
# =========================================================

menu() {
while true; do
    header
    echo "1. Install kernel"
    echo "2. Show EFI entries"
    echo "3. Show UKI files"
    echo "4. Change boot order"
    echo "5. Delete EFI entry"
    echo "6. Exit"
    echo
    read -rp "Select: " c

    case "$c" in
        1) install_kernel; pause ;;
        2) efibootmgr; pause ;;
        3) ls -lah "$EFI_DIR"; pause ;;
        4) boot_order; pause ;;
        5) delete_entry; pause ;;
        6) exit 0 ;;
        *) err "Invalid"; pause ;;
    esac
done
}

# =========================================================
# Main Execution Control
# =========================================================
main() {
    parse_args "$@"
    check_root
    check_tools
    check_esp
    menu
}

# Jalankan fungsi utama
main "$@"
