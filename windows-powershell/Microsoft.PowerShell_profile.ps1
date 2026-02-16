$PSStyle.FileInfo.Directory = ""

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None

Import-Module PSFzf
Set-PsFzfOption -PSReadLineChordProvider 'Alt+f' -PSReadLineChordReverseHistory 'Alt+r'

function ex {
	explorer .
}

