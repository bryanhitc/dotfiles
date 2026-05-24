function update_title --on-variable PWD
    set -l title (basename $PWD)

    # Update TMUX if inside a session
    if test -n "$TMUX"
        tmux rename-window $title
    end

    # Update Zellij if inside a session
    if test -n "$ZELLIJ"
        zellij action rename-tab $title
    end
end

