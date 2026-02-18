# param([string]$file)

# if (-not $file -or -not (Test-Path $file -PathType Leaf)) { return }

# $historyBranch = "history"
# $worktreeDir = ".git-history"
# $daysToKeep = 7

# # 1. Inicjalizacja repo (jeśli brak)
# if (-not (Test-Path ".git")) {
#     git init -b main | Out-Null
#     Set-Content .gitignore "$worktreeDir/`n"
#     git add .gitignore
#     git commit -m "initial commit" | Out-Null
# }

# # 2. Upewnij się, że .git-history jest w .gitignore
# if (-not (Select-String -Path ".gitignore" -Pattern $worktreeDir -Quiet)) {
#     Add-Content ".gitignore" "`n$worktreeDir/"
# }

# # 3. Tworzenie worktree (Side-Step Method)
# if (-not (Test-Path $worktreeDir)) {
#     $branchExists = git show-ref --verify --quiet "refs/heads/$historyBranch"
#     if ($LASTEXITCODE -ne 0) {
#         $emptyTree = git hash-object -t tree /dev/null
#         $initialCommit = git commit-tree $emptyTree -m "Initial history root"
#         git branch $historyBranch $initialCommit
#     }
#     git worktree add $worktreeDir $historyBranch | Out-Null
# }

# # 4. Kopiowanie pliku
# $dest = Join-Path $worktreeDir $file
# $destDir = Split-Path $dest
# if ($destDir -and -not (Test-Path $destDir)) {
#     New-Item -ItemType Directory -Force -Path $destDir | Out-Null
# }
# Copy-Item $file $dest -Force

# # 5. Operacje wewnątrz worktree
# Push-Location $worktreeDir
#     # A. Commitowanie nowej zmiany
#     git add .
#     git diff --cached --quiet
#     if ($LASTEXITCODE -ne 0) {
#         $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#         git commit -m "autosave $file at $timestamp" | Out-Null
#     }

#     # B. CZYSZCZENIE: Usuwanie commitów starszych niż 7 dni
#     # Szukamy skrótu commita, który był 7 dni temu
#     $cutoffDate = (Get-Date).AddDays(-$daysToKeep).ToString("yyyy-MM-dd HH:mm:ss")
#     $oldCommit = git rev-list -n 1 --before="$cutoffDate" $historyBranch

#     if ($oldCommit) {
#         # Jeśli znaleźliśmy stare commity, robimy "płytkie" czyszczenie.
#         # Najbezpieczniejszą metodą w skrypcie bez interakcji jest stworzenie nowego 
#         # punktu startowego (orphan) z aktualnego stanu i porzucenie bardzo starej historii.
#         # Ale żeby nie komplikować struktury w Lazygit, po prostu pozwalamy mu rosnąć, 
#         # chyba że chcesz agresywnego usuwania - wtedy odkomentuj poniższe linie:
        
#         # git checkout --orphan history_temp $oldCommit | Out-Null
#         # git commit -m "Cleanup: History before $cutoffDate removed" | Out-Null
#         # git rebase --onto history_temp $oldCommit $historyBranch | Out-Null
#         # git branch -D history_temp | Out-Null
#     }
# Pop-Location

# # 6. Zwrot treści dla Helixa
# # Get-Content $file -Raw

param([string]$file)

# --- KONFIGURACJA ---
$daysToKeep = 7
$historyBranch = "history"
$worktreeDir = ".git-history"

# 1. Szybkie sprawdzenie czy plik istnieje
if (-not $file) { return }
$absolutePath = Resolve-Path $file -ErrorAction SilentlyContinue
if (-not $absolutePath) { return }
$fileDir = Split-Path $absolutePath.Path

# 2. Sprawdzenie czy jesteśmy w repozytorium Git
Push-Location $fileDir
    git rev-parse --is-inside-work-tree 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Pop-Location
        return 
    }
    $gitRoot = git rev-parse --show-toplevel
Pop-Location

Set-Location $gitRoot

# 3. Upewnij się, że .git-history jest ignorowany
if (-not (Select-String -Path ".gitignore" -Pattern $worktreeDir -Quiet)) {
    Add-Content ".gitignore" "`n$worktreeDir/"
}

# 4. Tworzenie worktree jeśli nie istnieje
if (-not (Test-Path $worktreeDir)) {
    $branchExists = git show-ref --verify --quiet "refs/heads/$historyBranch"
    if ($LASTEXITCODE -ne 0) {
        $emptyTree = git hash-object -t tree /dev/null
        $initialCommit = git commit-tree $emptyTree -m "Initial history root"
        git branch $historyBranch $initialCommit
    }
    git worktree add $worktreeDir $historyBranch 2>&1 | Out-Null
}

# 5. Kopiowanie pliku
$relativePath = [System.IO.Path]::GetRelativePath($gitRoot, $absolutePath.Path)
$dest = Join-Path (Join-Path $gitRoot $worktreeDir) $relativePath
$destDir = Split-Path $dest

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}
Copy-Item $absolutePath.Path $dest -Force

# 6. Operacje wewnątrz worktree
Push-Location $worktreeDir
    git add .
    git diff --cached --quiet
    if ($LASTEXITCODE -ne 0) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        git commit -m "autosave: $relativePath at $timestamp" | Out-Null
        
        $cutoffDate = (Get-Date).AddDays(-$daysToKeep).ToString("yyyy-MM-dd HH:mm:ss")
        $oldCommit = git rev-list -n 1 --before="$cutoffDate" $historyBranch
        
        if ($oldCommit) {
            # Tworzymy nowy "pusty" punkt startowy na bazie stanu sprzed X dni
            # To agresywne cięcie, które sprawia, że historia nie rośnie w nieskończoność
            git checkout --orphan history_temp $oldCommit | Out-Null
            git commit -m "Cleanup: History before $cutoffDate removed" | Out-Null
            git rebase --onto history_temp $oldCommit $historyBranch | Out-Null
            git branch -D history_temp | Out-Null
        }
    }
Pop-Location
