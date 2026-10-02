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
if (Test-Path "$DotfilesDir\.git") {
    Write-Host "   repo juz istnieje, robie git pull"
    git -C $DotfilesDir pull --ff-only
} elseif (Test-Path $DotfilesDir) {
    throw "$DotfilesDir istnieje, ale to nie jest repozytorium git. Przenies go albo usun recznie."
} else {
    git clone $RepoUrl $DotfilesDir
}

Write-Host "== Installing apps =="
scoop install pwsh

# terminal, powloka, edytory, menedzer plikow, git
scoop install wezterm starship neovim helix yazi lazygit

scoop install psfzf

# zewnetrzne narzedzia yazi: podglady plikow (wideo, PDF, SVG, archiwa)
scoop install ffmpeg 7zip poppler resvg imagemagick

# powloka na co dzien
scoop install fd ripgrep fzf zoxide jq

# TUI
scoop install bottom
scoop install fastfetch
scoop install lnav
scoop install uv

# go (gopls dla helixa) i rustup (cargo: omnyssh, hx-lsp)
scoop install go rustup

Write-Host "== Installing Python TUI (uv) =="
uv tool install visidata
uv tool install "harlequin[mysql]"

# =============================
# YAZI - file.exe
# =============================
Write-Host "== Yazi: YAZI_FILE_ONE =="
$fileExe = @(
    "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe",
    "C:\Program Files\Git\usr\bin\file.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($fileExe) {
    [Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $fileExe, "User")
    $env:YAZI_FILE_ONE = $fileExe
    Write-Host "   $fileExe"
} else {
    Write-Host "   brak file.exe z Gita -- podglady yazi beda ograniczone" -ForegroundColor Yellow
}

# =============================
# NEOVIM -- MUSI byc PRZED linkowaniem
# =============================
Write-Host "== Neovim =="
& "$DotfilesDir\nvim\install.ps1"

# =============================
# HELIX - serwery jezykowe (npm)
# =============================
# Wspolne z nvimem stawia nvim\install.ps1. NIE kopiuj linijki npm z naglowka
# languages.toml: `typescript` bez wersji = 7.x bez tsserver.js,
# `emmet-language-server` bez zakresu = brak binarki.
Write-Host "== Helix: language servers =="
$env:PATH += ";$env:APPDATA\npm"
if (Get-Command npm -ErrorAction SilentlyContinue) {
    $hxNpm = @(
        @{ spec = "@tailwindcss/language-server";      probe = "tailwindcss-language-server" },
        @{ spec = "sql-language-server";               probe = "sql-language-server" },
        @{ spec = "@prisma/language-server";           probe = "prisma-language-server" },
        @{ spec = "dockerfile-language-server-nodejs"; probe = "docker-langserver" },
        @{ spec = "bash-language-server";              probe = "bash-language-server" },
        @{ spec = "stylelint-lsp";                     probe = "stylelint-lsp" }
    )
    foreach ($p in $hxNpm) {
        if (Get-Command $p.probe -ErrorAction SilentlyContinue) {
            Write-Host "   juz jest  $($p.probe)"
        } else {
            npm install -g $p.spec
            if ($LASTEXITCODE -ne 0) { Write-Host "   FAIL  npm i -g $($p.spec)" -ForegroundColor Red }
        }
    }
} else {
    Write-Host "   brak npm -- pomijam serwery helixa" -ForegroundColor Yellow
}

# Dopisuje katalog do PATH uzytkownika (rejestr) i biezacej sesji.
function Add-UserPath {
    param([string]$Dir)
    New-Item -ItemType Directory -Force -Path $Dir | Out-Null
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if (($userPath -split ';') -notcontains $Dir) {
        [Environment]::SetEnvironmentVariable("Path", "$userPath;$Dir", "User")
    }
    if (($env:PATH -split ';') -notcontains $Dir) { $env:PATH += ";$Dir" }
}

# gopls -- `go install` wrzuca do $(go env GOPATH)\bin, scoop tego nie dopisuje do PATH.
Write-Host "== Go: gopls =="
Add-UserPath (Join-Path (go env GOPATH) "bin")
if (Get-Command gopls -ErrorAction SilentlyContinue) {
    Write-Host "   juz jest  gopls"
} else {
    go install golang.org/x/tools/gopls@latest
}

# cargo -- toolchain msvc linkuje przez Build Tools z nvim\install.ps1,
# dlatego PO nim. Binarki w %USERPROFILE%\.cargo\bin.
Write-Host "== Rust: cargo =="
rustup default stable
Add-UserPath "$env:USERPROFILE\.cargo\bin"

if (Get-Command omny -ErrorAction SilentlyContinue) {
    Write-Host "   juz jest  omny"
} else {
    cargo install --locked omnyssh
}

# hx-lsp: snippety i akcje dla helixa
if (Get-Command hx-lsp -ErrorAction SilentlyContinue) {
    Write-Host "   juz jest  hx-lsp"
} else {
    cargo install --locked hx-lsp
}

# =============================
# CONFIGS (symlinki -- tryb dewelopera albo admin)
# =============================
Write-Host "== Linking configs =="
& "$DotfilesDir\link-configs.ps1"

# =============================
# YAZI - wtyczki i flavory z package.toml
# =============================
Write-Host "== Yazi: plugins =="
ya pkg install
ya cache clear

Write-Host "== DONE! Restart terminal =="
