# ~/.zshrc

# ============================================================
# PIERWSZA INSTALACJA / WYMAGANIA
# ============================================================
#
# 1. Zainstaluj Zsh, Git, fzf i chsh:
#
#    sudo dnf install zsh git fzf util-linux-user
#
#
# 2. Ustaw Zsh jako domyślny shell:
#
#    chsh -s "$(which zsh)"
#
#    Potem WYLOGUJ SIĘ i zaloguj ponownie.
#
#    Sprawdzenie:
#
#    echo $SHELL
#
#    Powinno być:
#    /usr/bin/zsh
#
#
# 3. Zainstaluj Oh My Zsh:
#
#    git clone --depth=1 \
#      https://github.com/ohmyzsh/ohmyzsh.git \
#      ~/.oh-my-zsh
#
#
# 4. Zainstaluj zsh-autosuggestions:
#
#    git clone --depth=1 \
#      https://github.com/zsh-users/zsh-autosuggestions \
#      ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
#
#
# 5. OPTIONAL - NVM (Node.js):
#
#    Jeśli używasz Node.js/NVM, zainstaluj NVM osobno.
#    Po instalacji powinien istnieć katalog:
#
#    ~/.nvm
#
#
# 6. OPTIONAL - Neovim dla aliasu `nv`:
#
#    sudo dnf install neovim
#
#
# Po wszystkim:
#
#    exec zsh
#
# ============================================================


# ============================================================
# OH MY ZSH
# ============================================================

export ZSH="$HOME/.oh-my-zsh"

# Motyw prompta dostarczany przez Oh My Zsh.
# Nie potrzebujesz Starshipa, jeśli chcesz używać tego motywu.
#
# Alternatywnie:
# ZSH_THEME="robbyrussell"

ZSH_THEME="bureau"


# ============================================================
# PLUGINY OH MY ZSH
# ============================================================
#
# Wbudowane w Oh My Zsh:
#
#   git
#   z
#   sudo
#   fzf
#   web-search
#   copyfile
#   copypath
#
# Dodatkowej instalacji wymaga:
#
#   zsh-autosuggestions
#
# Instalacja:
#
#   git clone --depth=1 \
#     https://github.com/zsh-users/zsh-autosuggestions \
#     ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
#

plugins=(
  git
  z
  sudo
  fzf
  zsh-autosuggestions
  web-search
  copyfile
  copypath
)


# Ładowanie Oh My Zsh.
#
# Jeśli zobaczysz:
#
#   no such file or directory ~/.oh-my-zsh/oh-my-zsh.sh
#
# oznacza to, że Oh My Zsh nie jest zainstalowany.

source "$ZSH/oh-my-zsh.sh"


# ============================================================
# ALIASY
# ============================================================

# Neovim
alias nv='nvim'

# Czytelniejsze ls
alias ll='ls -lah'


# ============================================================
# FZF
# ============================================================
#
# Wymaga:
#
#   sudo dnf install fzf
#
# Alt+F -> wyszukiwanie plików
# Alt+R -> wyszukiwanie historii poleceń
#

bindkey '^[f' fzf-file-widget
bindkey '^[r' fzf-history-widget


# ============================================================
# NVM
# ============================================================

export NVM_DIR="$HOME/.nvm"

# Załaduj NVM tylko wtedy, gdy jest zainstalowane.
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

# Completion dla NVM.
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
