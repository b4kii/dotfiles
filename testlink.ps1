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
#
# Bez tego pierwszy Link-File kasuje cel, potem wywala sie na tworzeniu
# dowiazania i zostajesz bez pliku i bez linku.
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

    # Bez tego literowka w sciezce zrodlowej dawala poprawnie wygladajacy link,
    # ktory wskazuje w prozne -- a oryginal juz skasowany.
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
        # TU byl `Remove-Item -Recurse -Force`, czyli kasowanie prawdziwego
        # pliku bez pytania. Jesli wersja w repo byla starsza niz ta na dysku,
        # traciles nowsza bezpowrotnie. Teraz laduje obok jako .bak.
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

# Yazi
Link-File `
  "$Dotfiles\yazi\yazi.toml" `
  "$env:APPDATA\yazi\yazi.toml"

Link-File `
  "$Dotfiles\yazi\keymap.toml" `
  "$env:APPDATA\yazi\keymap.toml"

Link-File `
  "$Dotfiles\yazi\theme.toml" `
  "$env:APPDATA\yazi\theme.toml"

# Lazygit
Link-File `
  "$Dotfiles\lazygit\config.yml" `
  "$env:APPDATA\lazygit\config.yml"

# Neovim -- caly katalog jednym dowiazaniem, nie plik po pliku
#
# UWAGA, kolejnosc ma znaczenie: nvim\install.ps1 ZAWSZE umieszcza konfiguracje
# w AppData\Local\nvim (porownuje $PSScriptRoot z celem, a uruchamiany z repo
# nigdy nie jest z nim rowny). Odpalony po tym skrypcie zobaczy tu symlink,
# odsunie go jako .bak i wgra zwykla kopie -- dowiazanie przepadnie.
#
# Wiec: nvim\install.ps1 URUCHAMIAJ PRZED linkowaniem, nie po. Potem do
# aktualizacji wtyczek i serwerow wystarczy `-SkipPlugins` / recznie.
Link-File `
  "$Dotfiles\nvim" `
  "$env:LOCALAPPDATA\nvim"

# Vim
Link-File `
  "$Dotfiles\vim\_vimrc" `
  "$env:USERPROFILE\_vimrc"

# IdeaVim
Link-File `
  "$Dotfiles\jetbrains\.ideavimrc" `
  "$env:USERPROFILE\.ideavimrc"

# VS Code
Link-File `
  "$Dotfiles\vscode\settings.json" `
  "$env:APPDATA\Code\User\settings.json"

Link-File `
  "$Dotfiles\vscode\keybindings.json" `
  "$env:APPDATA\Code\User\keybindings.json"

# Helix -- wyrzucony razem z instalacja helixa z install.ps1.
# Odkomentuj, jesli wracasz do niego:
#
# Link-File "$Dotfiles\helix\config.toml"               "$env:APPDATA\helix\config.toml"
# Link-File "$Dotfiles\helix\languages.toml"            "$env:APPDATA\helix\languages.toml"
# Link-File "$Dotfiles\helix\themes\custom_theme.toml"  "$env:APPDATA\helix\themes\custom_theme.toml"

# ahk\ nie jest linkowane: skrypty AutoHotkey nie maja kanonicznej lokalizacji,
# odpalasz je ze sciezki, ktora sam wybierzesz (np. skrot w Autostarcie).

Write-Host "== DONE =="
