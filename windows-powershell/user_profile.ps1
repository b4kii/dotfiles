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
Set-PsFzfOption -PSReadLineChordProvider 'Alt+f' -PSReadLineChordReverseHistory 'Alt+r'

function ex {
	explorer .
}
