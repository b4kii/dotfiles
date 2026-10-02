# =========================================
# DOTFILES - SYMLINKI KONFIGURACJI (WINDOWS)
# =========================================
#
# Jedna kopia pliku zamiast dwoch: edytujesz config tam, gdzie zawsze, a zmiana
# od razu jest zmiana w repo. Zadnego recznego przeklejania.
#
# Wymaga trybu dewelopera albo uruchomienia jako administrator -- Windows nie
# pozwala zwyklemu uzytkownikowi tworzyc dowiazan symbolicznych.

$ErrorActionPreference = 'Stop'

$Dotfiles = "$env:USERPROFILE\dotfiles"

if (-not (Test-Path $Dotfiles)) {
    throw "Nie ma $Dotfiles -- sklonuj repo albo popraw sciezke."
}

# ---------------------------------------------------------------------------
# Sprawdzenie uprawnien ZANIM cokolwiek ruszymy.
function Test-CanSymlink {
    $probe = Join-Path $env:TEMP ("symlink-probe-" + [guid]::NewGuid())
    $target = Join-Path $env:TEMP ("symlink-target-" + [guid]::NewGuid())
    try {
        New-Item -ItemType File -Path $target -Force | Out-Null
        New-Item -ItemType SymbolicLink -Path $probe -Target $target -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        Remove-Item -LiteralPath $probe  -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $target -Force -ErrorAction SilentlyContinue
    }
}

if (-not (Test-CanSymlink)) {
    throw @'
Brak uprawnien do tworzenia dowiazan symbolicznych.

Wlacz tryb dewelopera:
  Ustawienia > System > Dla deweloperow > Tryb dewelopera
albo uruchom ten skrypt w terminalu otwartym jako administrator.
'@
}

# ---------------------------------------------------------------------------
function Link-File {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (-not (Test-Path $Source)) {
        Write-Host "  POMIJAM  brak zrodla: $Source" -ForegroundColor Yellow
        return
    }

    $item = Get-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue

    if ($item -and $item.LinkType -eq 'SymbolicLink') {
        if ($item.Target -contains $Source) {
            Write-Host "  juz jest  $Destination"
            return
        }
        Remove-Item -LiteralPath $Destination -Force   # stary link, nie dane
    }
    elseif ($item) {
        $backup = "$Destination.bak"
        if (Test-Path $backup) {
            Remove-Item -LiteralPath $backup -Recurse -Force
        }
        Move-Item -LiteralPath $Destination -Destination $backup
        Write-Host "  kopia zapasowa -> $backup" -ForegroundColor DarkGray
    }

    $parent = Split-Path $Destination
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
    Write-Host "  Linked    $Destination" -ForegroundColor Green
}

Write-Host "== Creating symlinks =="

# PowerShell
Link-File `
  "$Dotfiles\powershell\Microsoft.PowerShell_profile.ps1" `
  "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"

# WezTerm
Link-File `
  "$Dotfiles\wezterm\.wezterm.lua" `
  "$env:USERPROFILE\.wezterm.lua"

# Starship
Link-File `
  "$Dotfiles\starship\starship.toml" `
  "$env:USERPROFILE\.config\starship.toml"

# Yazi -- na Windowsie config jest w %APPDATA%\yazi\config\, nie w %APPDATA%\yazi\.
# package.toml tez, bo z niego `ya pkg install` bierze wtyczki i flavory.
foreach ($name in 'yazi.toml', 'keymap.toml', 'theme.toml', 'package.toml') {
    Link-File "$Dotfiles\yazi\$name" "$env:APPDATA\yazi\config\$name"
}

# Lazygit
Link-File `
  "$Dotfiles\lazygit\config.yml" `
  "$env:APPDATA\lazygit\config.yml"

# Neovim -- caly katalog jednym dowiazaniem.
# nvim\install.ps1 URUCHAMIAJ PRZED linkowaniem, nie po -- inaczej odsunie
# symlink jako .bak i wgra zwykla kopie.
Link-File `
  "$Dotfiles\nvim" `
  "$env:LOCALAPPDATA\nvim"

# Helix -- %APPDATA%\helix\. themes\ jednym dowiazaniem, nowe motywy dzialaja od razu.
Link-File "$Dotfiles\helix\config.toml"    "$env:APPDATA\helix\config.toml"
Link-File "$Dotfiles\helix\languages.toml" "$env:APPDATA\helix\languages.toml"
Link-File "$Dotfiles\helix\themes"         "$env:APPDATA\helix\themes"

Write-Host "== DONE =="
