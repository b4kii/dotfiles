#!/bin/bash

home=$1

echo "Deleting files.."
sudo rm -rf "$home"/.zshrc
sudo rm -rf "$home"/.tmux.conf
sudo rm -rf "$home"/.config/nvim/
sudo rm -rf "$home"/.oh-my-zsh
sudo rm -rf /usr/local/bin/nvim
sudo rm -rf /usr/local/share/nvim/
echo "Finished deleting files."

if [ -z "$home" ]; then
	echo "Path for user was not provided! Exiting setup."
	exit
fi

function check_wget {
	local url=$1
	local destination=$2
    if wget -q --spider "$url"; then
        wget "$url" -P "$destination"
    else
	echo "Error while getting file!"
	exit 1
    fi
}

cd "$home"

echo "Updating and upgrading system. May take a while.."

yes | apt update 
yes | apt upgrade

echo "Finished upgrading system."

echo "Installing required packages."

yes | apt install ninja-build gettext cmake unzip curl build-essential git wget tmux zsh xclip fzf

echo "Building and installing neovim."

git clone https://github.com/neovim/neovim
cd neovim && make CMAKE_BUILD_TYPE=RelWithDebInfo 
sudo make install 

echo "Configuring neovim."

mkdir "$home"/.config/nvim
check_wget https://raw.githubusercontent.com/b4kii/dotfiles/main/init.vim "$home"/.config/nvim/

echo "Neovim setup finished."


echo "Configuring zsh."

yes | sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-"$home"/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
rm "$home"/.zshrc
check_wget https://raw.githubusercontent.com/b4kii/dotfiles/main/.zshrc "$home"
chsh -s $(which zsh)

echo "Zsh setup finished."

echo "Configuring tmux."

check_wget https://raw.githubusercontent.com/b4kii/dotfiles/main/.tmux.conf "$home"/

echo "Tmux setup finished."

echo "Installing i3."

yes | apt install i3 dmenu

echo "i3 setup finished."


#xmodmap -e 'keycode 66 = Control_L'
#xmodmap -e 'clear Lock'
#xmodmap -e 'add Control = Control_L'

