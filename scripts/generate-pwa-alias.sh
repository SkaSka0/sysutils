#!/usr/bin/env fish

# ==============================================================================
# KONFIGURASI GLOBAL & KONSTANTA
# ==============================================================================
set -g APP_DIR ~/.local/share/applications
set -g ALIAS_FILE ~/.config/fish/conf.d/pwa_aliases.fish
set -g LAUNCHER_DIR ~/.local/bin/utils

# ==============================================================================
# FUNGSI BANTUAN
# ==============================================================================

function usage
    echo "Usage: generate-pwa-aliases [OPTIONS]"
    echo ""
    echo "Support:"
    echo "  - Brave PWA"
    echo "  - Firefox pseudo-PWA"
    echo ""
    echo "Options:"
    echo "  -l, --list              List detected apps"
    echo "  -p, --prefix PREFIX     Set alias prefix (default: app_)"
    echo "  -h, --help              Show this help message"
end

# ------------------------------------------------------------------------------
# Ambil value dari file .desktop
# ------------------------------------------------------------------------------
function get_desktop_value
    set -l key $argv[1]
    set -l file $argv[2]

    set -l line (grep -m1 "^$key=" $file)

    if test -n "$line"
        string replace "$key=" '' $line
    end
end

# ------------------------------------------------------------------------------
# Parse Brave Profile
# ------------------------------------------------------------------------------
function parse_brave_profile
    set -l exec_value $argv[1]

    if string match -rq '"--profile-directory=' $exec_value
        string replace -r '.*"--profile-directory=([^"]+)".*' '$1' $exec_value
    else if string match -rq -- '--profile-directory=' $exec_value
        string replace -r '.*--profile-directory=([^ ]+).*' '$1' $exec_value
    end
end

# ------------------------------------------------------------------------------
# Parse Brave App ID
# ------------------------------------------------------------------------------
function parse_appid
    set -l exec_value $argv[1]

    if string match -rq -- '--app-id=' $exec_value
        string replace -r '.*--app-id=([^ ]+).*' '$1' $exec_value
    end
end

# ------------------------------------------------------------------------------
# Parse Firefox Profile
# ------------------------------------------------------------------------------
function parse_firefox_profile
    set -l exec_value $argv[1]

    if string match -rq -- ' -P ' $exec_value
        string replace -r '.* -P ([^ ]+).*' '$1' $exec_value
    end
end

# ------------------------------------------------------------------------------
# Generate alias unik
# ------------------------------------------------------------------------------
function generate_unique_alias
    set -l appname $argv[1]
    set -l prefix $argv[2]

    set -l safe_name (
        string lower (
            string replace -a ' ' '_' $appname
        )
    )

    # Bersihkan karakter aneh
    set safe_name (
        string replace -ra '[^a-z0-9_]' '' $safe_name
    )

    set -l base_alias "$prefix$safe_name"
    set -l alias_name $base_alias

    set -l count 1

    while contains $alias_name $used_aliases
        set alias_name "$base_alias"_"$count"
        set count (math $count + 1)
    end

    echo $alias_name
end

# ------------------------------------------------------------------------------
# Process file .desktop
# ------------------------------------------------------------------------------
function process_desktop_file
    set -l file $argv[1]
    set -l prefix $argv[2]
    set -l listmode $argv[3]

    # Ambil Name
    set -l appname (get_desktop_value "Name" $file)

    test -z "$appname"
    and return

    # Ambil Exec
    set -l exec_value (get_desktop_value "Exec" $file)

    test -z "$exec_value"
    and return

    # Bersihkan %U / %u
    set exec_value (
        string replace -r ' %[UuFf]$' '' $exec_value
    )

    # ------------------------------------------------------------------------------
    # Detect browser
    # ------------------------------------------------------------------------------
    set -l browser ""

    if string match -rq "brave" $exec_value
        set browser "brave"
    else if string match -rq "firefox" $exec_value
        set browser "firefox"
    else
        return
    end

    # ------------------------------------------------------------------------------
    # Parse profile/appid
    # ------------------------------------------------------------------------------
    set -l profile ""
    set -l appid ""

    if test "$browser" = "brave"
        set profile (parse_brave_profile $exec_value)
        set appid (parse_appid $exec_value)
    else if test "$browser" = "firefox"
        set profile (parse_firefox_profile $exec_value)
    end

    # Validasi minimal harus ada profile
    if test -z "$profile"
        echo "Skip invalid entry: $file"
        return
    end

    # ------------------------------------------------------------------------------
    # Build command
    # ------------------------------------------------------------------------------
    set -l cmd ""

    if test "$browser" = "brave"

        set -l profile_escaped (
            string replace -a ' ' '\ ' $profile
        )

        set cmd "/opt/brave-bin/brave --profile-directory=$profile_escaped --app-id=$appid"

    else if test "$browser" = "firefox"

        # Firefox langsung pakai Exec asli
        set cmd $exec_value
    end

    # ------------------------------------------------------------------------------
    # Generate alias
    # ------------------------------------------------------------------------------
    set -l alias_name (
        generate_unique_alias $appname $prefix
    )

    set -g used_aliases $used_aliases $alias_name

    # ------------------------------------------------------------------------------
    # Output
    # ------------------------------------------------------------------------------
    if test $listmode -eq 1

        echo "$alias_name -> $cmd"

    else

        # Alias Fish
        echo "alias $alias_name=\"$cmd\"" >> $ALIAS_FILE

        # Launcher shell
        set -l launcher "$LAUNCHER_DIR/$alias_name"

        echo "#!/usr/bin/env bash" > $launcher
        echo "$cmd" >> $launcher

        chmod +x $launcher

        echo ""
        echo "Generated:"
        echo "  App      : $appname"
        echo "  Browser  : $browser"
        echo "  Source   : $file"
        echo "  Alias    : $alias_name"
        echo "  Launcher : $launcher"
    end
end

# ==============================================================================
# MAIN
# ==============================================================================

set listmode 0
set prefix "app_"

# ------------------------------------------------------------------------------
# Parse arguments
# ------------------------------------------------------------------------------
for i in (seq (count $argv))

    set arg $argv[$i]

    switch $arg

        case '-l' '--list'
            set listmode 1

        case '-p' '--prefix'

            if test (math $i + 1) -le (count $argv)
                set prefix $argv[(math $i + 1)]
            else
                echo "Error: missing value after $arg"
                exit 1
            end

        case '-h' '--help'
            usage
            exit 0
    end
end

# ------------------------------------------------------------------------------
# Persiapan directory
# ------------------------------------------------------------------------------
if test $listmode -eq 0

    mkdir -p (dirname $ALIAS_FILE)
    mkdir -p $LAUNCHER_DIR

    echo "# Auto-generated PWA aliases" > $ALIAS_FILE
end

# ------------------------------------------------------------------------------
# Global alias tracker
# ------------------------------------------------------------------------------
set -g used_aliases

# ------------------------------------------------------------------------------
# Scan semua .desktop
# ------------------------------------------------------------------------------
for file in $APP_DIR/*.desktop

    if test -f $file
        process_desktop_file $file $prefix $listmode
    end
end

# ------------------------------------------------------------------------------
# Reload Fish aliases otomatis
# ------------------------------------------------------------------------------
if test $listmode -eq 0

    if test -f $ALIAS_FILE
        source $ALIAS_FILE
    end

    echo ""
    echo "Done."
end