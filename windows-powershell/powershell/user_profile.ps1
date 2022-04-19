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

function cdp {set-location "D:\Projects"}
function cdd {set-location "C:\Users\baki\Desktop"}
function cdn {set-location "C:\Users\baki\AppData\Local\nvim"}
