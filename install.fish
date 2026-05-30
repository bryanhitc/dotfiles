#!/usr/bin/env fish

set DOTFILES_DIR (cd (dirname (status filename)); and pwd)
set BACKUP_DIR "$HOME/.config-backup/"(date +'%Y-%m-%d_%H%M%S')

function usage
    echo "Usage: ./install.fish <config-name> | all"
    echo "Installs configurations from the dotfiles repo into ~/.config by symlinking individual files"
    echo "Example: ./install.fish jj"
    echo "         ./install.fish all"
    exit 1
end

if test (count $argv) -lt 1
    usage
end

set TARGET $argv[1]

function cleanup_dangling_symlinks -a name
    set dest_dir "$HOME/.config/$name"
    if not test -d "$dest_dir"
        return 0
    end

    # Find all symlinks in the destination directory
    for link in (find "$dest_dir" -type l)
        # Skip if the symlink is NOT dangling (target exists)
        if test -e "$link"
            continue
        end

        # Verify the symlink points to our dotfiles directory before deleting
        set target (readlink "$link")
        if not string match -q "$DOTFILES_DIR*" "$target"
            continue
        end

        echo "Removing dangling symlink '$link' -> '$target'"
        rm "$link"
    end
end

function install_file -a src dest
    set dest_parent (dirname "$dest")
    
    # Ensure parent directory of the destination exists
    mkdir -p "$dest_parent"

    # If destination exists
    if test -e "$dest"; or test -L "$dest"
        # If it's already a symlink pointing to the correct place, do nothing
        if test -L "$dest"; and test (readlink "$dest") = "$src"
            return 0
        end

        # Compute relative backup path based on home directory structure
        set rel_from_home (string replace "$HOME/" "" "$dest")
        set backup_dest "$BACKUP_DIR/$rel_from_home"

        echo "Backing up existing file '$dest' to '$backup_dest'..."
        mkdir -p (dirname "$backup_dest")
        mv "$dest" "$backup_dest"
    end

    # Create the symlink
    echo "Symlinking '$dest' -> '$src'"
    ln -s "$src" "$dest"
end

function install_config -a name
    set src_dir "$DOTFILES_DIR/.config/$name"
    set dest_dir "$HOME/.config/$name"

    if not test -d "$src_dir"; and not test -f "$src_dir"
        echo "Error: Configuration '$name' does not exist in dotfiles/.config"
        return 1
    end

    # If source is an individual file, install it directly
    if test -f "$src_dir"
        install_file "$src_dir" "$dest_dir"
        return 0
    end

    # Recreate directory structure and symlink each file individually
    find "$src_dir" -type f | while read -l src_file
        # Compute relative path from src_dir
        set rel_path (string replace "$src_dir/" "" "$src_file")
        set dest_file "$dest_dir/$rel_path"

        install_file "$src_file" "$dest_file"
    end

    # Clean up any dangling symlinks inside this configuration directory
    cleanup_dangling_symlinks "$name"
end

if test "$TARGET" != "all"
    install_config "$TARGET"
    exit 0
end

# Install all items inside .config/
for item in $DOTFILES_DIR/.config/*
    if test -d "$item"; or test -f "$item"
        set name (basename "$item")
        install_config "$name"
    end
end
