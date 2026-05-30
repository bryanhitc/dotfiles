function update_git -d "Download, compile, and install the latest Git version to ~/.local"
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

    # Download and compile
    echo "Downloading Git source..."
    curl -sL "https://github.com/git/git/archive/refs/tags/$latest_tag.tar.gz" -o git.tar.gz

    echo "Extracting..."
    tar -zxf git.tar.gz
    cd "git-$latest_version"

    echo "Compiling Git..."
    make prefix=$HOME/.local -j(nproc) all

    echo "Installing Git to ~/.local..."
    make prefix=$HOME/.local install

    # Clean up
    cd $old_pwd
    rm -rf "$tmp_dir"

    echo "Successfully updated Git to "(git --version)
end
