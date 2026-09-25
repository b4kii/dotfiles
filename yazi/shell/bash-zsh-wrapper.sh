# Optional Yazi Bash/Zsh wrapper.
# Put this function in ~/.bashrc or ~/.zshrc and run `y` instead of `yazi`.
# After quitting with `q`, the shell changes to the directory you ended in.
# Quit with `Q` when you do not want to change the shell directory.

y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    # Czysci katalog zgloszony WezTermowi (pusty OSC 7), zeby czytal go
    # na biezaco z procesu yazi. Prompt po wyjsciu zglosi katalog od nowa.
    printf '\e]7;\e\\'
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
    command rm -f -- "$tmp"
}
