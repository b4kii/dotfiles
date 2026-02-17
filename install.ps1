# =========================================
# DOTFILES INSTALL SCRIPT - WINDOWS
# =========================================

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

Write-Host "== Cloning dotfiles =="
if (Test-Path $DotfilesDir) {
    Remove-Item $DotfilesDir -Recurse -Force
}
git clone $RepoUrl $DotfilesDir

Write-Host "== Installing tools =="
scoop install wezterm starship helix yazi lazygit
scoop install nodejs python lua-language-server gopls rust-analyzer taplo
scoop install ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick

Write-Host "== Installing npm LSP =="

npm install -g `
  typescript `
  typescript-language-server `
  vscode-langservers-extracted `
  emmet-language-server `
  intelephense `
  @tailwindcss/language-server `
  sql-language-server `
  @prisma/language-server `
  dockerfile-language-server-nodejs `
  bash-language-server


# =============================
# COPY CONFIGS (FORCE)
# =============================

Write-Host "== Copying configs =="

# PowerShell
$psDir = "$env:USERPROFILE\Documents\PowerShell"
New-Item -ItemType Directory -Force -Path $psDir | Out-Null
Copy-Item "$DotfilesDir\windows-powershell\Microsoft.PowerShell_profile.ps1" `
    "$psDir\Microsoft.PowerShell_profile.ps1" -Force

# WezTerm
Copy-Item "$DotfilesDir\.wezterm.lua" `
    "$env:USERPROFILE\.wezterm.lua" -Force

# Starship
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.config" | Out-Null
Copy-Item "$DotfilesDir\config\starship.toml" `
    "$env:USERPROFILE\.config\starship.toml" -Force

# Helix
$hxDir = "$env:APPDATA\helix"
New-Item -ItemType Directory -Force -Path "$hxDir\theme" | Out-Null

Copy-Item "$DotfilesDir\config\helix\config.toml" `
    "$hxDir\config.toml" -Force

Copy-Item "$DotfilesDir\config\helix\languages.toml" `
    "$hxDir\languages.toml" -Force

Copy-Item "$DotfilesDir\config\helix\theme\custom_theme.toml" `
    "$hxDir\theme\custom_theme.toml" -Force

# Yazi
$yaziDir = "$env:APPDATA\yazi"
New-Item -ItemType Directory -Force -Path $yaziDir | Out-Null
Copy-Item "$DotfilesDir\.yazi\yazi.toml" `
    "$yaziDir\yazi.toml" -Force

Write-Host "== DONE! Restart terminal =="
