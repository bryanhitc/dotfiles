#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="${HOME}/.config-backup/$(date +'%Y-%m-%d_%H%M%S')"

usage() {
    echo "Usage: $0 <config-name> | all"
    echo "Installs configurations from the dotfiles repo into ~/.config by symlinking individual files"
    echo "Example: $0 jj"
    echo "         $0 all"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

TARGET="$1"

cleanup_dangling_symlinks() {
    local name="$1"
    local dest_dir="${HOME}/.config/${name}"

    if [ ! -d "${dest_dir}" ]; then
        return 0
    fi

    # Find all symlinks in the destination directory
    find "${dest_dir}" -type l | while read -r link; do
        # [ ! -e "$link" ] is true if the symlink is dangling (points to a non-existent target)
        if [ ! -e "${link}" ]; then
            # Verify the symlink points to our dotfiles directory before deleting
            local target
            target="$(readlink "${link}")"
            if [[ "${target}" == "${DOTFILES_DIR}"* ]]; then
                echo "Removing dangling symlink '${link}' -> '${target}'"
                rm "${link}"
            fi
        fi
    done
}

install_file() {
    local src="$1"
    local dest="$2"
    local dest_parent
    dest_parent="$(dirname "${dest}")"

    # Ensure parent directory of the destination exists
    mkdir -p "${dest_parent}"

    # If destination exists
    if [ -e "${dest}" ] || [ -L "${dest}" ]; then
        # If it's already a symlink pointing to the correct place, do nothing
        if [ -L "${dest}" ] && [ "$(readlink -f "${dest}")" = "$(readlink -f "${src}")" ]; then
            return 0
        fi

        # Compute relative backup path based on home directory structure
        local rel_from_home="${dest#${HOME}/}"
        local backup_dest="${BACKUP_DIR}/${rel_from_home}"

        echo "Backing up existing file '${dest}' to '${backup_dest}'..."
        mkdir -p "$(dirname "${backup_dest}")"
        mv "${dest}" "${backup_dest}"
    fi

    # Create the symlink
    echo "Symlinking '${dest}' -> '${src}'"
    ln -s "${src}" "${dest}"
}

install_config() {
    local name="$1"
    local src_dir="${DOTFILES_DIR}/.config/${name}"
    local dest_dir="${HOME}/.config/${name}"

    if [ ! -d "${src_dir}" ] && [ ! -f "${src_dir}" ]; then
        echo "Error: Configuration '${name}' does not exist in dotfiles/.config"
        return 1
    fi

    # If source is an individual file, install it directly
    if [ -f "${src_dir}" ]; then
        install_file "${src_dir}" "${dest_dir}"
        return 0
    fi

    # Recreate directory structure and symlink each file individually
    find "${src_dir}" -type f | while read -r src_file; do
        # Compute relative path from src_dir
        local rel_path="${src_file#${src_dir}/}"
        local dest_file="${dest_dir}/${rel_path}"

        install_file "${src_file}" "${dest_file}"
    done

    # Clean up any dangling symlinks inside this configuration directory
    cleanup_dangling_symlinks "${name}"
}

if [ "${TARGET}" != "all" ]; then
    install_config "${TARGET}"
    exit 0
fi

# Install all items inside .config/
for item in "${DOTFILES_DIR}/.config"/*; do
    if [ -d "${item}" ] || [ -f "${item}" ]; then
        name=$(basename "${item}")
        install_config "${name}"
    fi
done
