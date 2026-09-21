# =========================================
# DOTFILES INSTALL SCRIPT - WINDOWS
# =========================================
#
# Ten skrypt stawia terminal i aplikacje. Wszystko, czego potrzebuje Neovim
# -- serwery jezykowe, formattery, tree-sitter, kompilator C -- instaluje
# nvim\install.ps1, wolany na koncu. Nie powtarzamy tego tutaj, bo tamten
# skrypt robi to lepiej: sprawdza przed instalacja, odswieza PATH miedzy
# krokami i na koncu raportuje, czego zabraklo.

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/b4kii/dotfiles"
$DotfilesDir = "$env:USERPROFILE\dotfiles"

Write-Host "== Checking Scoop =="

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..."
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    irm get.scoop.sh | iex
}

scoop bucket add main 2>$null
scoop bucket add extras 2>$null

Write-Host "== Installing Git =="
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    scoop install git
}

# Bylo tu `Remove-Item $DotfilesDir -Recurse -Force` przed klonowaniem, czyli
# kasowanie katalogu razem z wszystkim, czego nie zdazyles wypchnac.
# Teraz: jest repo -> pull, nie ma -> clone, jest katalog ale nie repo -> blad.
Write-Host "== Cloning dotfiles =="
if (Test-Path "$DotfilesDir\.git") {
    Write-Host "   repo juz istnieje, robie git pull"
    git -C $DotfilesDir pull --ff-only
} elseif (Test-Path $DotfilesDir) {
    throw "$DotfilesDir istnieje, ale to nie jest repozytorium git. Przenies go albo usun recznie."
} else {
    git clone $RepoUrl $DotfilesDir
}

Write-Host "== Installing apps =="

# terminal, powloka, edytor, menedzer plikow, git
scoop install wezterm starship neovim yazi lazygit

# zewnetrzne narzedzia yazi: podglady plikow (wideo, PDF, SVG, archiwa)
scoop install ffmpeg 7zip poppler resvg imagemagick

# powloka na co dzien: szukanie, skakanie po katalogach, JSON
scoop install fd ripgrep fzf zoxide jq

# TUI - z toinstallwindows.md
scoop install bottom      # binarka nazywa sie `btm`
scoop install fastfetch
scoop install lnav

# uv: instalator narzedzi pythonowych, kazde dostaje wlasne srodowisko i shim
scoop install uv

Write-Host "== Installing Python TUI (uv) =="

# visidata i harlequin nie maja manifestow w scoop.
uv tool install visidata

# harlequin sam umie tylko sqlite i duckdb, reszta baz to osobne adaptery.
uv tool install "harlequin[mysql]"

# =============================
# CONFIGS
# =============================
#
# Bylo tu kopiowanie plik po pliku ze sciezkami z poprzedniego ukladu repo
# (windows-powershell\, config\helix\theme\, .yazi\ ...). Zadna z nich juz nie
# istnieje, wiec przy $ErrorActionPreference = "Stop" pierwszy Copy-Item
# przerywal caly skrypt.
#
# link-configs.ps1 ma te sciezki aktualne, wiec sciezki zyja w jednym miejscu
# zamiast w dwoch. Symlinki zamiast kopii znacza tez, ze edycja configu jest
# od razu zmiana w repo -- bez recznego przeklejania.
#
# UWAGA: symlinki na Windowsie wymagaja trybu dewelopera albo admina.

Write-Host "== Linking configs =="
& "$DotfilesDir\link-configs.ps1"

# =============================
# NEOVIM
# =============================
#
# Osobny skrypt, bo ma wlasna logike, ktorej nie ma sensu tu powtarzac:
#   * scoop: tree-sitter, lua-language-server, nodejs, python
#   * npm:   intelephense, typescript-language-server, vscode-langservers-extracted,
#            @olrtg/emmet-language-server, prettier
#   * pip:   pyright, ruff
#   * pyta o Visual Studio Build Tools (tree-sitter kompiluje parsery wylacznie
#     przez MSVC -- gcc w PATH jest ignorowany)
#   * odpala nvima headless, zeby vim.pack sklonowal wtyczki
#
# -Force pomija pytania (nadpisanie istniejacej konfiguracji i Build Tools).
# Chcesz bez Build Tools: dopisz -SkipMsvc.

Write-Host "== Neovim =="
& "$DotfilesDir\nvim\install.ps1"

Write-Host "== DONE! Restart terminal =="

# =============================
# CO ZNIKNELO RAZEM Z HELIXEM
# =============================
#
# helix, gopls, rust-analyzer, taplo
#   gopls byl skonfigurowany tylko w helix/languages.toml. W nvim/lua/lsp.lua
#   gopls, clangd, rust_analyzer i bashls sa zakomentowane -- odkomentuj tam,
#   jesli ich chcesz, i dopisz z powrotem tutaj.
#
# @tailwindcss/language-server, sql-language-server, @prisma/language-server,
# dockerfile-language-server-nodejs, bash-language-server
#   To samo: wystepowaly wylacznie w helix/languages.toml. Nvim ich nie
#   konfiguruje, wiec instalowanie ich nic nie dawalo.
#
# typescript (bez wersji)  <-- to bylo grozne, nie tylko zbedne
#   Samo `npm i -g typescript` ciagnie dzis 7.x, natywne przepisanie w Go,
#   ktorego lib/ nie zawiera tsserver.js. typescript-language-server bez tego
#   pliku odmawia startu ("Could not find a valid TypeScript installation").
#   nvim\install.ps1 przypina `typescript@5` wlasnie po to -- a ta linijka
#   cofala tam poprawke przy kazdym uruchomieniu.
#
# emmet-language-server (bez zakresu)
#   nvim\install.ps1 instaluje `@olrtg/emmet-language-server`. To inny pakiet
#   npm; ten bez zakresu nie dostarcza binarki, ktorej szuka lsp.lua.
