$PSStyle.FileInfo.Directory = ""

# AutoCompletion
# -PredictionSource rzuca blad PRZERYWAJACY, gdy konsola nie obsluguje VT albo
# jest przekierowana (pwsh ... | something, zadania w tle, CI). Bez try/catch
# profil umiera w tym miejscu i nie ma ani aliasow, ani promptu, ani fzf.
try { Set-PSReadLineOption -PredictionSource History -ErrorAction Stop } catch {}
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineOption -BellStyle None

Set-PSReadLineKeyHandler -Chord Ctrl+d -Function DeleteChar

# Fzf - ladowany leniwie. Import-Module PSFzf kosztuje 372 ms przy KAZDYM
# starcie, a chordy sa potrzebne dopiero gdy ich uzyjesz. Stub ponizej dociaga
# modul przy pierwszym Alt+r / Alt+t / Alt+c i podmienia sie na prawdziwy
# handler. Koszt: ten pierwszy raz w sesji trzeba wcisnac skrot dwa razy.
$initPsFzf = {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadLineChordReverseHistory 'Alt+r'
    Set-PsFzfOption -PSReadLineChordProvider 'Alt+t'
    Set-PsFzfOption -PSReadLineChordSetLocation 'Alt+c'
}

foreach ($chord in 'Alt+r', 'Alt+t', 'Alt+c') {
    Set-PSReadLineKeyHandler -Chord $chord -ScriptBlock $initPsFzf
}

function y {
    $tmp = (New-TemporaryFile).FullName

    [Console]::Write("$([char]27)]7;$([char]27)\")

    & "$HOME\scoop\apps\yazi\current\yazi.exe" @args --cwd-file="$tmp"

    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if ($cwd -and $cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
        Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
    }

    Remove-Item -Path $tmp
}

Set-Alias n nvim
Set-Alias ll ls
Set-Alias g git
Set-Alias lg lazygit
Set-Alias ff fastfetch
Set-Alias ex explorer

$prompt = ""
function Invoke-Starship-PreCommand {
    $current_location = $executionContext.SessionState.Path.CurrentLocation
    if ($current_location.Provider.Name -eq "FileSystem") {
        $ansi_escape = [char]27
        $provider_path = $current_location.ProviderPath -replace "\\", "/"
        $prompt = "$ansi_escape]7;file://${env:COMPUTERNAME}/${provider_path}$ansi_escape\"
    }
    $host.ui.Write($prompt)
}

# `starship init powershell` to tylko stub, ktory odpala starship.exe DRUGI raz
# z --print-full-init. Cache'ujemy ten drugi wynik - jest deterministyczny, a
# STARSHIP_SESSION_KEY powstaje przy wykonaniu skryptu, nie przy generowaniu.
# Cache odswieza sie sam po aktualizacji starshipa (porownanie dat pliku).
$starshipInit = Join-Path $env:TEMP 'starship_init.ps1'
$starshipExe = (Get-Command starship -CommandType Application -ErrorAction SilentlyContinue).Source
if ($starshipExe -and (-not (Test-Path $starshipInit) -or
    (Get-Item $starshipExe).LastWriteTime -gt (Get-Item $starshipInit).LastWriteTime)) {
    & $starshipExe init powershell --print-full-init | Set-Content -LiteralPath $starshipInit
}
if (Test-Path $starshipInit) { . $starshipInit }
