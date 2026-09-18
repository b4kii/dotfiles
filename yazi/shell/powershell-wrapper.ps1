# Optional Yazi PowerShell wrapper.
# Put this function in $PROFILE and run `y` instead of `yazi`.
# After quitting with `q`, PowerShell changes to the directory you ended in.
# Quit with `Q` when you do not want to change the shell directory.

function y {
    $tmp = (New-TemporaryFile).FullName

    yazi.exe @args --cwd-file="$tmp"

    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }

    Remove-Item -Path $tmp
}
