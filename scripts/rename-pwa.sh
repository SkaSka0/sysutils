#!/usr/bin/env fish

function usage
    echo "Usage: rename-pwa [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -o DIR, --output DIR   Set output directory for symlinks (default: ~/.local/share/applications)"
    echo "  -n, --dry-run          Show what would be done, without creating symlinks"
    echo "  -f, --force            Overwrite existing symlinks"
    echo "  -l, --list             List detected Brave PWA apps (Name + path)"
    echo "  -h, --help             Show this help message"
end

# Default values
set appdir ~/.local/share/applications
set targetdir $appdir
set dryrun 0
set force 0
set listmode 0

# Parse arguments
for i in (seq (count $argv))
    set arg $argv[$i]
    switch $arg
        case '-o' '--output'
            if test (math $i + 1) -le (count $argv)
                set targetdir $argv[(math $i + 1)]
            else
                echo "Error: missing directory after $arg"
                exit 1
            end
        case '-n' '--dry-run'
            set dryrun 1
        case '-f' '--force'
            set force 1
        case '-l' '--list'
            set listmode 1
        case '-h' '--help'
            usage
            exit 0
    end
end

# Buat folder target jika belum ada (kecuali list mode)
if test $listmode -eq 0
    if not test -d $targetdir
        mkdir -p $targetdir
    end
end

# Proses file .desktop
for file in $appdir/brave-*.desktop
    # Ambil Name= pertama
    set name_line (grep -m1 '^Name=' $file)
    set appname (string replace 'Name=' '' $name_line)

    if test -n "$appname"
        # Ganti spasi dengan underscore
        set safe_name (string replace -a ' ' '_' $appname)
        set newfile "$targetdir/$safe_name.desktop"

        if test $listmode -eq 1
            echo "$appname -> $file"
        else
            if test -e $newfile
                if test $force -eq 1
                    echo "Overwrite symlink: $newfile"
                    if test $dryrun -eq 0
                        rm -f $newfile
                        ln -s $file $newfile
                    end
                else
                    echo "Skip $file, target $newfile sudah ada"
                end
            else
                echo "Symlink $file -> $newfile"
                if test $dryrun -eq 0
                    ln -s $file $newfile
                end
            end
        end
    end
end
