function _fzf_configure_bindings_help --description "Prints the help message for fzf_configure_bindings."
    echo "\
USAGE:
    fzf_configure_bindings [--history=[KEY_SEQUENCE]]

DESCRIPTION
    fzf_configure_bindings installs key bindings for fzf.fish's commands and erases any bindings it
    previously installed. It installs bindings for both default and insert modes. fzf.fish executes
    it without options on fish startup to install the out-of-the-box key bindings.

    By default, commands are bound to a mnemonic key sequence, shown below:
        COMMAND            |  DEFAULT KEY SEQUENCE         |  CORRESPONDING OPTION
        Search History     |  Ctrl+R     (R for reverse)   |  --history

    Override the command's binding by specifying its corresponding option with the desired key
    sequence using fish's key name syntax (e.g. ctrl-r). Disable the command's binding
    by specifying its corresponding option with no value.

    Because fzf_configure_bindings erases bindings it previously installed, it can be cleanly
    executed multiple times. Once the desired fzf_configure_bindings command has been found, add it
    to your config.fish in order to persist the customized bindings.

    Pass -h or --help to print this help message and exit.

EXAMPLES
    Default bindings but bind Search History to Ctrl+Alt+H
        \$ fzf_configure_bindings --history=ctrl-alt-h
    Disable Search History
        \$ fzf_configure_bindings --history=

SEE Also
    To learn more about fish key bindings, see bind(1) and fish_key_reader(1).
"
end
