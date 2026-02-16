$PSStyle.FileInfo.Directory = ""

# AutoCompletion
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None

# Fzf
Import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider 'Alt+f' -PSReadLineChordReverseHistory 'Alt+r'

function ex {
	explorer .
}

Set-Alias vi nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias lg lazygit

Invoke-Expression (&starship init powershell)
