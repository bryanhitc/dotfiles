# set PATH so it includes user's private bin if it exists
fish_add_path "$HOME/bin"
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/.cargo/bin"

# Fix terminal type for xterm-ghostty
set -gx TERMINFO $HOME/.terminfo
set -gx TERMINFO_DIRS $HOME/.terminfo /usr/share/terminfo

# The rest of the config is for interactive shell sessions.
if not status is-interactive
    return
end

# Commands to run in interactive sessions can go here
COMPLETE=fish jj | source

# FZF Configuration
set -x FZF_DEFAULT_OPTS '--cycle --border --preview-window=wrap --marker="*"'
set -x FZF_DEFAULT_COMMAND 'rg --files --hidden --glob "!.git/*"'
set -x FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"

# Initialize title for Tmux/Zellij
update_title
