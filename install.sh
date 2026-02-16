#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/b4kii/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

echo "== Updating system =="
sudo apt update

echo "== Installing base packages =="
sudo apt install -y \
  git curl unzip build-essential \
  tmux zsh \
  nodejs npm \
  python3 python3-pip \
  golang-go \
  rustc cargo \
  lua5.4

echo "== Installing tools =="

# WezTerm
if ! command -v wezterm &> /dev/null; then
  curl -LO https://github.com/wez/wezterm/releases/latest/download/wezterm-ubuntu22.04.deb
  sudo apt install -y ./wezterm-ubuntu22.04.deb || sudo apt -f install -y
fi

# Starship
curl -sS https://starship.rs/install.sh | sh -s -- -y

# Helix
if ! command -v hx &> /dev/null; then
  sudo snap install helix --classic
fi

# Yazi
if ! command -v yazi &> /dev/null; then
  cargo install yazi-fm
fi

# Lazygit
sudo apt install -y lazygit || true

echo "== Installing LSP =="
npm install -g \
  typescript \
  typescript-language-server \
  vscode-langservers-extracted \
  emmet-language-server \
  intelephense \
  @tailwindcss/language-server \
  sql-language-server \
  @prisma/language-server \
  dockerfile-language-server-nodejs \
  bash-language-server

sudo apt install -y \
  ffmpeg \
  p7zip-full \
  jq \
  poppler-utils \
  fd-find \
  ripgrep \
  fzf \
  zoxide \
  imagemagick

cargo install taplo-cli
cargo install rust-analyzer || true
go install golang.org/x/tools/gopls@latest
pip install python-lsp-server

echo "== Cloning dotfiles =="
rm -rf "$DOTFILES_DIR"
git clone $REPO_URL $DOTFILES_DIR

echo "== Copying configs =="

# Zsh
cp -f "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# Tmux
cp -f "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"

# WezTerm
mkdir -p "$HOME/.config/wezterm"
cp -f "$DOTFILES_DIR/.wezterm.lua" "$HOME/.config/wezterm/wezterm.lua"

# Starship
mkdir -p "$HOME/.config"
cp -f "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"

# Helix
mkdir -p "$HOME/.config/helix/theme"
cp -f "$DOTFILES_DIR/config/helix/config.toml" "$HOME/.config/helix/config.toml"
cp -f "$DOTFILES_DIR/config/helix/languages.toml" "$HOME/.config/helix/languages.toml"
cp -f "$DOTFILES_DIR/config/helix/theme/custom_theme.toml" \
   "$HOME/.config/helix/theme/custom_theme.toml"

# Yazi
mkdir -p "$HOME/.config/yazi"
cp -f "$DOTFILES_DIR/.yazi/yazi.toml" "$HOME/.config/yazi/yazi.toml"

echo "== DONE =="
