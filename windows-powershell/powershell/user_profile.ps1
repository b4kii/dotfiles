# Prompt
Import-Module posh-git
Import-Module oh-my-posh

Set-PoshPrompt kali

# Icons
Import-Module Terminal-Icons

# AutoCompletion
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider 'Ctrl+f' -PSReadLineChordReverseHistory 'Ctrl+r'

# Aliases
Set-Alias vi nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias lg lazygit

function sync-data {
    $homeDir = $env:USERPROFILE

    $recentBackupFile = Get-Childitem -Path C:\Users\baki\Documents\PowerToys\Backup\ | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    $paths = @(
        "$homeDir\AppData\Roaming\Code\User\settings.json",
        "$homeDir\AppData\Roaming\Code\User\keybindings.json",
        $recentBackupFile
    )

    $destinations = @(
        "$homeDir\dotfiles\vscode",
        "$homeDir\dotfiles\vscode",
        "$homeDir\dotfiles\powertoys"
    )

    for ($i = 0; $i -lt $paths.Length; $i++) {
        Copy-Item -Path $paths[$i] -Destination $destinations[$i] -Recurse
    }
}

function ex {
	explorer .
}


