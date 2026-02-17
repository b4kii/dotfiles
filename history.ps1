param([string]$file)

if (-not $file -or -not (Test-Path $file -PathType Leaf)) { return }

$historyBranch = "history"
$worktreeDir = ".git-history"
$daysToKeep = 7

# 1. Inicjalizacja repo (jeśli brak)
if (-not (Test-Path ".git")) {
    git init -b main | Out-Null
    Set-Content .gitignore "$worktreeDir/`n"
    git add .gitignore
    git commit -m "initial commit" | Out-Null
}

# 2. Upewnij się, że .git-history jest w .gitignore
if (-not (Select-String -Path ".gitignore" -Pattern $worktreeDir -Quiet)) {
    Add-Content ".gitignore" "`n$worktreeDir/"
}

# 3. Tworzenie worktree (Side-Step Method)
if (-not (Test-Path $worktreeDir)) {
    $branchExists = git show-ref --verify --quiet "refs/heads/$historyBranch"
    if ($LASTEXITCODE -ne 0) {
        $emptyTree = git hash-object -t tree /dev/null
        $initialCommit = git commit-tree $emptyTree -m "Initial history root"
        git branch $historyBranch $initialCommit
    }
    git worktree add $worktreeDir $historyBranch | Out-Null
}

# 4. Kopiowanie pliku
$dest = Join-Path $worktreeDir $file
$destDir = Split-Path $dest
if ($destDir -and -not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}
Copy-Item $file $dest -Force

# 5. Operacje wewnątrz worktree
Push-Location $worktreeDir
    # A. Commitowanie nowej zmiany
    git add .
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "autosave $file at $timestamp" | Out-Null
    }

    # B. CZYSZCZENIE: Usuwanie commitów starszych niż 7 dni
    # Szukamy skrótu commita, który był 7 dni temu
    $cutoffDate = (Get-Date).AddDays(-$daysToKeep).ToString("yyyy-MM-dd HH:mm:ss")
    $oldCommit = git rev-list -n 1 --before="$cutoffDate" $historyBranch

    if ($oldCommit) {
        # Jeśli znaleźliśmy stare commity, robimy "płytkie" czyszczenie.
        # Najbezpieczniejszą metodą w skrypcie bez interakcji jest stworzenie nowego 
        # punktu startowego (orphan) z aktualnego stanu i porzucenie bardzo starej historii.
        # Ale żeby nie komplikować struktury w Lazygit, po prostu pozwalamy mu rosnąć, 
        # chyba że chcesz agresywnego usuwania - wtedy odkomentuj poniższe linie:
        
        # git checkout --orphan history_temp $oldCommit | Out-Null
        # git commit -m "Cleanup: History before $cutoffDate removed" | Out-Null
        # git rebase --onto history_temp $oldCommit $historyBranch | Out-Null
        # git branch -D history_temp | Out-Null
    }
Pop-Location

# 6. Zwrot treści dla Helixa
Get-Content $file -Raw
