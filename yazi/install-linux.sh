#!/usr/bin/env sh
set -eu

printf '%s\n' '== Yazi cross-platform config: Linux installer =='

install_clipboard_helper() {
    if [ "${XDG_SESSION_TYPE:-}" = "wayland" ]; then
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm wl-clipboard
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y wl-clipboard
        fi
    else
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm xclip
        elif command -v apt-get >/dev/null 2>&1; then
            sudo apt-get install -y xclip
        fi
    fi
}

if command -v pacman >/dev/null 2>&1; then
    printf '%s\n' 'Detected Arch/pacman.'
    sudo pacman -S --needed --noconfirm \
        yazi file ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick
    install_clipboard_helper

elif command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' 'Detected Debian/Ubuntu/apt.'

    if ! command -v yazi >/dev/null 2>&1; then
        curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg \
            | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null
        echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' \
            | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null
    fi

    sudo apt-get update
    sudo apt-get install -y \
        yazi file ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick curl git

    # resvg availability differs between Debian/Ubuntu releases.
    if apt-cache show resvg >/dev/null 2>&1; then
        sudo apt-get install -y resvg
    else
        printf '%s\n' 'NOTE: resvg is not available in this apt release; SVG preview remains optional.'
    fi

    # Debian/Ubuntu package fd-find installs the command as fdfind.
    if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        case ":${PATH}:" in
            *:"$HOME/.local/bin":*) : ;;
            *)
                printf '%s\n' 'NOTE: add ~/.local/bin to PATH if your shell does not already include it:'
                printf '%s\n' '  export PATH="$HOME/.local/bin:$PATH"'
                ;;
        esac
    fi

    install_clipboard_helper

elif command -v dnf >/dev/null 2>&1; then
    printf '%s\n' 'Detected Fedora/RHEL-compatible dnf.'
    if ! command -v yazi >/dev/null 2>&1; then
        if ! dnf copr --help >/dev/null 2>&1; then
            sudo dnf install -y dnf-plugins-core
        fi
        sudo dnf copr enable -y lihaohong/yazi
    fi
    # The Yazi RPM pulls recommended dependencies through weak dependencies.
    sudo dnf install -y yazi file

else
    printf '%s\n' 'Unsupported package manager in this helper.' >&2
    printf '%s\n' 'Install Yazi and its recommended dependencies using the official Yazi installation docs.' >&2
    exit 1
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config_dir="$HOME/.config/yazi"
mkdir -p "$config_dir"

timestamp=$(date +%Y%m%d-%H%M%S)
for name in yazi.toml theme.toml keymap.toml; do
    target="$config_dir/$name"
    if [ -f "$target" ]; then
        cp "$target" "$target.$timestamp.bak"
        printf 'Backup: %s\n' "$target.$timestamp.bak"
    fi
    cp "$script_dir/$name" "$target"
    printf 'Installed: %s\n' "$target"
done

if [ ! -d "$config_dir/flavors/vscode-dark-plus.yazi" ]; then
    printf '%s\n' 'Installing VS Code Dark+ Yazi flavor...'
    ya pkg add 956MB/vscode-dark-plus
else
    printf '%s\n' 'VS Code Dark+ flavor already present.'
fi

ya cache clear

printf '%s\n' ''
printf '%s\n' 'Verification:'
yazi --version
file --version | head -n 1

printf '%s\n' ''
printf '%s\n' 'Done. Run: yazi'
printf '%s\n' 'Optional shell wrapper: shell/bash-zsh-wrapper.sh'
