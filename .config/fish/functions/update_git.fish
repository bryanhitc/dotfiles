function update_git -d "Download, compile, and install the latest Git version to ~/.local"
    set -l apt_cmd "sudo apt update && sudo apt install -y build-essential gettext libcurl4-gnutls-dev libexpat1-dev zlib1g-dev libssl-dev make"

    # 1. Pre-checks for compile tools and libraries
    if not type -q make; or not type -q gcc
        echo (set_color -o red)"Error: 'make' or 'gcc' is not installed."(set_color normal) >&2
        echo "Please install build dependencies by running:" >&2
        echo (set_color cyan)"  $apt_cmd"(set_color normal) >&2
        return 1
    end

    if not type -q curl-config
        echo (set_color -o red)"Error: 'curl-config' not found. Compilation will likely fail due to missing curl headers."(set_color normal) >&2
        echo "Please install build dependencies by running:" >&2
        echo (set_color cyan)"  $apt_cmd"(set_color normal) >&2
        return 1
    end

    # Fetch latest stable tag from GitHub
    echo "Checking for the latest Git release..."
    set -l latest_tag (curl -s https://api.github.com/repos/git/git/tags | grep -oE '"name": "v[0-9]+\.[0-9]+\.[0-9]+"' | head -n 1 | cut -d'"' -f4)

    if test -z "$latest_tag"
        echo "Error: Could not retrieve latest Git version from GitHub." >&2
        return 1
    end

    # Clean tag name (v2.54.0 -> 2.54.0)
    set -l latest_version (string replace "v" "" $latest_tag)

    # Check currently installed version
    set -l current_version (git --version 2>/dev/null | awk '{print $3}')

    echo "Currently installed Git: "(set_color -o cyan)"$current_version"(set_color normal)
    echo "Latest available Git:    "(set_color -o green)"$latest_version"(set_color normal)

    if test "$current_version" = "$latest_version"; and not contains -- --force $argv
        echo "Git is already up-to-date! (Run with 'update_git --force' to force re-install)"
        return 0
    end

    echo "Updating Git to v$latest_version..."

    # Set up a safe temporary directory
    set -l tmp_dir (mktemp -d /tmp/git-update-XXXXXX)
    
    # Save current directory to return to it later
    set -l old_pwd $PWD
    cd "$tmp_dir"

    # Download
    echo "Downloading Git source..."
    if not curl -sL "https://github.com/git/git/archive/refs/tags/$latest_tag.tar.gz" -o git.tar.gz
        echo (set_color -o red)"Error: Failed to download Git source."(set_color normal) >&2
        cd $old_pwd
        rm -rf "$tmp_dir"
        return 1
    end

    # Extract
    echo "Extracting..."
    if not tar -zxf git.tar.gz
        echo (set_color -o red)"Error: Failed to extract Git source."(set_color normal) >&2
        cd $old_pwd
        rm -rf "$tmp_dir"
        return 1
    end
    
    cd "git-$latest_version"

    # Compile
    echo "Compiling Git..."
    if not make prefix=$HOME/.local -j(nproc) all
        echo (set_color -o red)"Error: Compilation failed."(set_color normal) >&2
        echo "Please make sure you have all build dependencies installed by running:" >&2
        echo (set_color cyan)"  $apt_cmd"(set_color normal) >&2
        cd $old_pwd
        rm -rf "$tmp_dir"
        return 1
    end

    # Install
    echo "Installing Git to ~/.local..."
    if not make prefix=$HOME/.local install
        echo (set_color -o red)"Error: Installation failed."(set_color normal) >&2
        cd $old_pwd
        rm -rf "$tmp_dir"
        return 1
    end

    # Clean up
    cd $old_pwd
    rm -rf "$tmp_dir"

    echo "Successfully updated Git to "(git --version)
end

