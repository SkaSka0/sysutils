#!/bin/bash
set -e

# =========================
# 📁 PATHS & CONFIG
# =========================
THEME_DIR="/usr/share/sddm/themes"
CONFIG_DIR="/etc/sddm.conf.d"
CONFIG_FILE="$CONFIG_DIR/theme.conf"
LOG_FILE="/var/log/sddm-switcher.log"

# =========================
# 🚩 ARGUMENT PARSING
# =========================
NO_RESTART=false
FORCE_RESTART=false
LIST_ONLY=false
SHOW_CURRENT=false
SHOW_LOG=false
TAIL_LOG=false
SET_THEME=""
VERBOSE=false

show_help() {
cat << EOF
SDDM Theme Switcher

Usage:
  sddm-theme [options]

Description:
  Without any options, the program will launch
  interactive theme selection using fzf.

Options:
  -h, --help              Show this help message
  -l, --list              List available valid themes
  -c, --current           Show current active theme
  -s, --set <theme>       Set theme directly
  -n, --no-restart        Skip SDDM restart
  -r, --restart           Restart SDDM without confirmation
  -v, --verbose           Enable verbose output
      --log               Show log file
      --tail-log          Monitor log file in realtime

Examples:
  sddm-theme
      Launch interactive fzf theme selector

  sddm-theme --list
      Show all available themes

  sddm-theme --current
      Show current active theme

  sddm-theme --set sugar-dark
      Apply theme directly

  sddm-theme --set sugar-dark --restart
      Apply theme and restart SDDM immediately

  sddm-theme --set sugar-dark --no-restart
      Apply theme without restarting SDDM

  sddm-theme --log
      Show log file contents

  sddm-theme --tail-log
      Monitor log file in realtime
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            show_help
            exit 0
            ;;

        -l|--list)
            LIST_ONLY=true
            shift
            ;;

        -c|--current)
            SHOW_CURRENT=true
            shift
            ;;

        -s|--set)
            if [[ -z "$2" ]]; then
                echo "Error: --set requires a theme name"
                exit 1
            fi

            SET_THEME="$2"
            shift 2
            ;;

        -n|--no-restart)
            NO_RESTART=true
            shift
            ;;

        -r|--restart)
            FORCE_RESTART=true
            shift
            ;;

        -v|--verbose)
            VERBOSE=true
            shift
            ;;

        --log)
            SHOW_LOG=true
            shift
            ;;

        --tail-log)
            TAIL_LOG=true
            shift
            ;;

        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# =========================
# 🎨 COLORS & STYLE
# =========================
BOLD="\e[1m"
RESET="\e[0m"
MAGENTA="\e[38;5;213m"
CYAN="\e[38;5;117m"
GREEN="\e[38;5;120m"
RED="\e[38;5;204m"
YELLOW="\e[38;5;227m"
GRAY="\e[38;5;245m"

# =========================
# 📝 LOGGING FUNCTION
# =========================
log() {
    local level=$1
    local msg=$2
    local timestamp

    timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"

    if [[ "$VERBOSE" == false && "$level" == "INFO" ]]; then
        return
    fi

    case "$level" in
        "INFO")
            echo -e "${CYAN}[INFO]${RESET} $msg"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${RESET} $msg"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${RESET} $msg"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${RESET} $msg" >&2
            ;;
    esac
}

# =========================
# 🔒 ROOT CHECK & LOG INIT
# =========================
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}󰌾 Error: Please run this script with sudo!${RESET}"
    exit 1
fi

touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log "INFO" "--- SDDM Switcher Session Started ---"

# =========================
# 📜 LOG VIEW MODES
# =========================
if $SHOW_LOG; then
    if [[ -f "$LOG_FILE" ]]; then
        cat "$LOG_FILE"
    else
        echo -e "${YELLOW}Log file does not exist yet.${RESET}"
    fi
    exit 0
fi

if $TAIL_LOG; then
    if [[ -f "$LOG_FILE" ]]; then
        echo -e "${CYAN}󰍉 Monitoring log file... (CTRL+C to exit)${RESET}"
        tail -f "$LOG_FILE"
    else
        echo -e "${YELLOW}Log file does not exist yet.${RESET}"
    fi
    exit 0
fi

# =========================
# 🛠️ DEPENDENCY VALIDATION
# =========================
check_dependencies() {
    local missing_deps=()

    if ! command -v fzf &> /dev/null; then
        missing_deps+=("fzf")
    fi

    if ! fc-list | grep -iq "nerd"; then
        log "WARN" "Nerd Font not detected on system."

        read -p "Install JetBrainsMono Nerd Font? (y/N): " INSTALL_FONT

        if [[ "$INSTALL_FONT" =~ ^[Yy]$ ]]; then
            missing_deps+=("ttf-jetbrains-mono-nerd")
        fi
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "INFO" "Installing: ${missing_deps[*]}..."

        if pacman -Sy --needed --noconfirm "${missing_deps[@]}" >> "$LOG_FILE" 2>&1; then
            log "SUCCESS" "Dependencies installed."
        else
            log "ERROR" "Installation failed. Check $LOG_FILE"
            exit 1
        fi
    fi
}

check_dependencies

# =========================
# ✅ VALID THEME CHECK
# =========================
is_valid_theme() {
    local theme_path="$1"

    [[ -f "$theme_path/metadata.desktop" ]] &&
    [[ -f "$theme_path/Main.qml" ]]
}

# =========================
# 🔍 GET CURRENT THEME
# =========================
get_current_theme() {
    local theme=""

    if [[ -f "$CONFIG_FILE" ]]; then
        theme=$(grep -E '^Current=' "$CONFIG_FILE" | cut -d'=' -f2)
    fi

    if [[ -z "$theme" && -f /etc/sddm.conf ]]; then
        theme=$(grep -E '^Current=' /etc/sddm.conf | cut -d'=' -f2)
    fi

    echo "${theme:-default}"
}

CURRENT_THEME=$(get_current_theme)

log "INFO" "Current theme: $CURRENT_THEME"

# =========================
# 📋 SIMPLE COMMAND MODES
# =========================
if $SHOW_CURRENT; then
    echo "$CURRENT_THEME"
    exit 0
fi

if $LIST_ONLY; then
    find "$THEME_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d | sort | while read -r path; do

        theme=$(basename "$path")

        if is_valid_theme "$path"; then
            echo "$theme"
        fi
    done

    exit 0
fi

# =========================
# 🔄 LOAD VALID THEMES
# =========================
THEMES_LIST=$(
find "$THEME_DIR" \
    -mindepth 1 \
    -maxdepth 1 \
    -type d | sort | while read -r path; do

    theme=$(basename "$path")

    if ! is_valid_theme "$path"; then
        log "WARN" "Skipping invalid theme: $theme"
        continue
    fi

    if [[ "$theme" == "$CURRENT_THEME" ]]; then
        echo "󰄵 $theme (active)"
    else
        echo "󰆊 $theme"
    fi
done
)

# =========================
# 🎯 THEME SELECTION
# =========================
if [[ -n "$SET_THEME" ]]; then
    THEME="$SET_THEME"
else
    SELECTED=$(echo "$THEMES_LIST" | fzf \
        --ansi \
        --header="󱄅 SDDM THEME SWITCHER" \
        --info=inline \
        --layout=reverse \
        --border=rounded \
        --prompt=" Search Theme: " \
        --pointer="➜" \
        --color="border:#bd93f9,header:#ff79c6,prompt:#50fa7b,pointer:#ffb86c" \
        --height=40%)

    if [[ -z "$SELECTED" ]]; then
        log "INFO" "Action cancelled by user."
        exit 0
    fi

    THEME=$(echo "$SELECTED" | sed -E 's/^(󰄵|󰆊) //; s/ \(active\)//')
fi

# =========================
# ⚙️ VALIDATION
# =========================
if [[ ! -d "$THEME_DIR/$THEME" ]]; then
    log "ERROR" "Theme '$THEME' does not exist."
    exit 1
fi

if ! is_valid_theme "$THEME_DIR/$THEME"; then
    log "ERROR" "Theme '$THEME' is invalid."
    exit 1
fi

if [[ "$THEME" == "$CURRENT_THEME" ]]; then
    log "INFO" "Theme '$THEME' is already active."
    exit 0
fi

# =========================
# 🚀 APPLY THEME
# =========================
log "INFO" "Applying theme: $THEME"

mkdir -p "$CONFIG_DIR"

if echo -e "[Theme]\nCurrent=$THEME" > "$CONFIG_FILE"; then
    log "SUCCESS" "Configuration updated successfully."
else
    log "ERROR" "Failed to write to $CONFIG_FILE"
    exit 1
fi

echo

# =========================
# 🔄 RESTART HANDLER
# =========================
echo -e "${RED}${BOLD}󱈸 WARNING:${RESET} Restarting SDDM will close all running applications!"

if $NO_RESTART; then
    CONFIRM="n"
elif $FORCE_RESTART; then
    CONFIRM="y"
else
    read -p "󰑓 Restart now? (y/N): " CONFIRM
    CONFIRM=${CONFIRM:-n}
fi

# =========================
# 🔁 RESTART SDDM
# =========================
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    log "INFO" "Restarting SDDM service..."

    SESSION_ID=$(loginctl list-sessions --no-legend | awk '$3 != "root" {print $1; exit}')

    if [[ -n "$SESSION_ID" ]]; then
        log "INFO" "Terminating session: $SESSION_ID"
        loginctl terminate-session "$SESSION_ID"
    fi

    sleep 1

    if systemctl restart sddm; then
        log "SUCCESS" "SDDM restarted successfully."
    else
        log "ERROR" "Failed to restart SDDM."
        exit 1
    fi
else
    log "INFO" "Restart skipped."
    echo -e "${GRAY}󰚥 Changes will take effect after manual logout or reboot.${RESET}"
fi

log "SUCCESS" "Script finished successfully."