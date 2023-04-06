# Prompt
Import-Module posh-git
Import-Module oh-my-posh

Set-PoshPrompt powerlevel10k_lean

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

function vsc-sync {
	cp C:\Users\baki\AppData\Roaming\Code\User\settings.json C:\Users\baki\dotfiles\vscode-settings
	cp C:\Users\baki\AppData\Roaming\Code\User\keybindings.json C:\Users\baki\dotfiles\vscode-settings
}

function ex {
	explorer .
}

function ws($FolderName) {
	webstorm64.exe $FolderName
}
