$Dotfiles = "$env:USERPROFILE\dotfiles"

function Link-File {
    param (
        [string]$Source,
        [string]$Destination
    )

    if (Test-Path $Destination) {
        Remove-Item $Destination -Recurse -Force
    }

    $parent = Split-Path $Destination
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $Destination -Target $Source | Out-Null
    Write-Host "Linked $Destination"
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

# Helix
Link-File `
  "$Dotfiles\helix\config.toml" `
  "$env:APPDATA\helix\config.toml"

Link-File `
  "$Dotfiles\helix\languages.toml" `
  "$env:APPDATA\helix\languages.toml"

Link-File `
  "$Dotfiles\helix\themes\custom_theme.toml" `
  "$env:APPDATA\helix\themes\custom_theme.toml"

# Yazi
Link-File `
  "$Dotfiles\yazi\yazi.toml" `
  "$env:APPDATA\yazi\yazi.toml"

# Lazygit (jeśli chcesz)
Link-File `
  "$Dotfiles\lazygit\config.yml" `
  "$env:APPDATA\lazygit\config.yml"

Write-Host "== DONE =="
