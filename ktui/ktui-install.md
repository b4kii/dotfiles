# Instalacja `kanban-tui` na Windows (PowerShell) 
http://github.com/Zaloog/kanban-tui

## 1. Zainstaluj Python

Pobierz Python:
https://www.python.org/downloads/

Podczas instalacji zaznacz:
```
Add Python to PATH
```

Sprawdź:
```powershell
python --version
```

---

## 2. Zainstaluj uv

```powershell
pip install uv
```

Sprawdź:
```powershell
python -m uv --version
```

---

## 3. Zainstaluj kanban-tui

```powershell
python -m uv tool install kanban-tui
```

---

## 4. Dodaj uv tools do PATH (uniwersalne)

uv instaluje narzędzia do katalogu:

```
%USERPROFILE%\.local\bin
```

Dodaj ten katalog do PATH:

```powershell
$userBin = Join-Path $env:USERPROFILE ".local\bin"

[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", "User") + ";$userBin",
    "User"
)
```

Zamknij i otwórz terminal ponownie.

---

## 5. Uruchom aplikację

```powershell
ktui
```

lub:

```powershell
kanban-tui
```

---

## 6. Jeśli nie działa

Sprawdź pliki:

```powershell
Get-ChildItem "$env:USERPROFILE\.local\bin"
```

Jeśli widzisz `ktui.exe`, ale komenda nie działa — otwórz nowy terminal.
