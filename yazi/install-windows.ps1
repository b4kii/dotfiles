$ErrorActionPreference = "Stop"

Write-Host "== Yazi cross-platform config: Windows installer =="

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    throw "Scoop is not installed. Install Scoop first, then run this script again."
}

# Git provides the file.exe implementation recommended by Yazi on Windows.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Git..."
    scoop install git
}

Write-Host "Installing/updating Yazi prerequisites..."
$packages = @(
    "yazi",
    "ffmpeg",
    "7zip",
    "jq",
    "poppler",
    "fd",
    "ripgrep",
    "fzf",
    "zoxide",
    "resvg",
    "imagemagick"
)

foreach ($package in $packages) {
    if (scoop list $package 2>$null | Select-String -Quiet "^$package\s") {
        Write-Host "Already installed: $package"
    } else {
        scoop install $package
    }
}

# Locate Git's file.exe.
$candidates = @(
    "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe",
    "C:\Program Files\Git\usr\bin\file.exe"
)

$fileExe = $candidates |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $fileExe) {
    throw "Could not find Git file.exe. Checked Scoop and C:\Program Files\Git."
}

Write-Host "Using file.exe: $fileExe"

# Persistent for this Windows user.
[Environment]::SetEnvironmentVariable("YAZI_FILE_ONE", $fileExe, "User")
# Also make it available in this current process.
$env:YAZI_FILE_ONE = $fileExe

$configDir = Join-Path $env:APPDATA "yazi\config"
New-Item -ItemType Directory -Force -Path $configDir | Out-Null

foreach ($name in @("yazi.toml", "theme.toml", "keymap.toml")) {
    $target = Join-Path $configDir $name
    $backup = "$target.bak"

    # Usuń poprzedni backup
    Remove-Item $backup -Force -ErrorAction SilentlyContinue

    if (Test-Path $target) {
        Copy-Item $target $backup -Force
        Write-Host "Backup: $backup"
    }

    Copy-Item (Join-Path $PSScriptRoot $name) $target -Force
    Write-Host "Installed: $target"
}

$flavorDir = Join-Path $configDir "flavors\kanagawa.yazi"
if (-not (Test-Path $flavorDir)) {
    Write-Host "Installing VS Code Dark+ Yazi flavor..."
	ya pkg add dangooddd/kanagawa
} else {
    Write-Host "VS Code Dark+ flavor already present."
}

Write-Host "Clearing Yazi preview cache..."
ya cache clear

Write-Host ""
Write-Host "Verification:"
yazi --version
& $env:YAZI_FILE_ONE --version

Write-Host ""
Write-Host "Done. Restart WezTerm so every new PowerShell session inherits YAZI_FILE_ONE."
Write-Host "Then run: yazi"
Write-Host "Optional shell wrapper: shell\powershell-wrapper.ps1"
