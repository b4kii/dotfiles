#!/bin/bash

set -e

function try_wget {
	local url=$1
	local destination=$2
    if wget -q --spider "$url"; then
        echo -e "Getting ${destination}"
        wget "$url" -P "$destination"
    else
        echo "Error while getting file!"
        exit
    fi
}

function pp {
    local message=$1

    echo "------------------------------------"
    echo -e "\t$message"
} 

userHome=$(getent passwd $SUDO_USER | cut -d: -f6)

pp "Deleting files.."

rm -rf "$userHome/.zshrc"
rm -rf "$userHome/.oh-my-zsh"
rm -rf "$userHome/.tmux.conf"
rm -rf "$userHome/.config/nvim/"
rm -rf "/root/.zshrc"
rm -rf "/root/.oh-my-zsh"
rm -rf "/root/.config/nvim/"

if [[ -d "$userHome/neovim" ]]; then
    cd "$userHome/neovim"
    cmake --build build/ --target uninstall
    rm -rf /usr/local/bin/nvim
    rm -rf /usr/local/share/nvim/
    rm -rf "$userHome/neovim"
fi

pp "Finished deleting files."

cd "$userHome"

pp "Updating and upgrading system."

apt update -y
apt upgrade -y

pp "Finished upgrading system."

pp "Installing required dependencies."

apt install -y ninja-build gettext cmake unzip curl build-essential git wget tmux zsh xclip fzf

pp "Building and installing neovim."

git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo 
make install 

pp "Configuring neovim."

mkdir "$userHome/.config/nvim"
try_wget https://raw.githubusercontent.com/b4kii/dotfiles/main/vim/init.vim "$userHome/.config/nvim/"

cd "$userHome"
pp "Neovim setup finished."


pp "Configuring oh-my-zsh and zsh."

su $SUDO_USER -c 'sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended'

git clone "https://github.com/zsh-users/zsh-autosuggestions" "$userHome/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
rm "$userHome/.zshrc"

try_wget "https://raw.githubusercontent.com/b4kii/dotfiles/main/linux/.zshrc" "$userHome"
chsh -s $(which zsh)

ln -s "$userHome/.zshrc" "/root/"
ln -s "$userHome/.oh-my-zsh" "/root/"

pp "Zsh setup finished."

pp "Configuring tmux."

try_wget https://raw.githubusercontent.com/b4kii/dotfiles/main/linux/.tmux.conf "$userHome"/

pp "Tmux setup finished."

# pp "Installing i3."

# apt install -y i3 dmenu

# pp "i3 setup finished."

# pp "Installing docker"

# curl -L https://get.docker.com | sh
# usermod -aG docker $USER

# pp "Docker installation finished"

# add vscode installation
if ! command -v code &> /dev/null
then
    echo "code could not be found"
    exit 1
fi

echo "----------------------------------"
read -p "Do you want to reboot system: " answer

if [[ "$answer" == "y" ]]; then
    pp "Rebooting"
    # reboot
fi
