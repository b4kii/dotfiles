# Yazi cross-platform config - Windows + Linux

Prepared for a terminal workflow with WezTerm + Starship + Yazi.

The same `yazi.toml`, `theme.toml`, and `keymap.toml` are used on Windows and Linux.
Only installation paths and system dependencies differ.

## What is configured

- Manager layout: `1 : 3 : 5`
  - parent directory: 1 part
  - current directory: 3 parts
  - preview: 5 parts
- Large preview panel for code, logs, Markdown and images.
- Long lines wrap in preview.
- Natural sorting and directories first.
- Image preview tuned for quality (`lanczos3`, quality 85).
- VS Code Dark+ Yazi flavor.
- `!` opens a shell in the current directory:
  - Linux: `$SHELL`
  - Windows: PowerShell 7 (`pwsh.exe`)

Yazi has built-in code/text and image preview. Extra tools add PDF, JSON, video, archive, SVG and richer image previews.

---

# Windows - Scoop

## 1. Install Yazi and all recommended helpers

If Scoop is already installed:

```powershell
scoop install yazi
scoop install ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick
```

What they provide:

| Package | Purpose in Yazi |
| --- | --- |
| `ffmpeg` | video thumbnails |
| `7zip` | archive preview/extraction |
| `jq` | JSON preview |
| `poppler` | PDF preview |
| `fd` | search files by name |
| `ripgrep` | search file contents |
| `fzf` | fast interactive navigation |
| `zoxide` | directory history navigation |
| `resvg` | SVG preview |
| `imagemagick` | HEIC/JPEG XL/font preview |

## 2. Git and file.exe

Yazi relies on `file(1)` to detect MIME types. On Windows the recommended implementation is the `file.exe` bundled with Git for Windows.

Check Git:

```powershell
git --version
(Get-Command git).Source
```

If Git is missing and you use Scoop:

```powershell
scoop install git
```

Typical Scoop path:

```text
C:\Users\<USER>\scoop\apps\git\current\usr\bin\file.exe
```

Typical Git installer path:

```text
C:\Program Files\Git\usr\bin\file.exe
```

Use this one-time PowerShell setup to find it and persist `YAZI_FILE_ONE`:

```powershell
$candidates = @(
    "$env:USERPROFILE\scoop\apps\git\current\usr\bin\file.exe",
    "C:\Program Files\Git\usr\bin\file.exe"
)

$fileExe = $candidates |
    Where-Object { Test-Path $_ } |
    Select-Object -First 1

if (-not $fileExe) {
    throw "Git file.exe not found"
}

[Environment]::SetEnvironmentVariable(
    "YAZI_FILE_ONE",
    $fileExe,
    "User"
)

# Makes it available immediately in the CURRENT terminal too.
$env:YAZI_FILE_ONE = $fileExe
```

`SetEnvironmentVariable(..., "User")` is persistent. You do this only once. The `$env:YAZI_FILE_ONE = ...` line is only for the current PowerShell process.

Verify:

```powershell
$env:YAZI_FILE_ONE
& $env:YAZI_FILE_ONE --version
```

Restart WezTerm after setting the persistent environment variable.

## 3. Install the config manually

From this directory:

```powershell
$configDir = "$env:APPDATA\yazi\config"
New-Item -ItemType Directory -Force $configDir

Copy-Item .\yazi.toml $configDir -Force
Copy-Item .\theme.toml $configDir -Force
Copy-Item .\keymap.toml $configDir -Force
```

Windows config location:

```text
%APPDATA%\yazi\config\
```

## 4. Install VS Code Dark+

```powershell
ya pkg add 956MB/vscode-dark-plus
```

The `theme.toml` file already selects this flavor.

## 5. Clear preview cache and run

```powershell
ya cache clear
yazi
```

## Automatic Windows installation

Instead of steps 1-5, run the supplied installer from PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install-windows.ps1
```

It:

1. installs Yazi and recommended helper programs through Scoop,
2. installs Git if needed,
3. finds Git's `file.exe`,
4. stores `YAZI_FILE_ONE` persistently for the user,
5. backs up existing Yazi config files,
6. installs this config,
7. installs VS Code Dark+,
8. clears Yazi preview cache.

---

# Linux

Config location:

```text
~/.config/yazi/
```

## Arch Linux

```bash
sudo pacman -S --needed yazi file ffmpeg 7zip jq poppler fd ripgrep fzf zoxide resvg imagemagick
```

For clipboard support, use the package appropriate for your display server:

Wayland:

```bash
sudo pacman -S --needed wl-clipboard
```

X11:

```bash
sudo pacman -S --needed xclip
```

## Debian / Ubuntu

Install current stable Yazi from the official Yazi APT repository:

```bash
curl -fsSL https://yazi-rs.github.io/builds/yazi-keyring.gpg | sudo tee /usr/share/keyrings/yazi-keyring.gpg >/dev/null

echo 'deb [signed-by=/usr/share/keyrings/yazi-keyring.gpg] https://yazi-rs.github.io/builds/ stable main' | sudo tee /etc/apt/sources.list.d/yazi.list >/dev/null

sudo apt update
sudo apt install yazi
```

Install preview/search helpers:

```bash
sudo apt install file ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick
```

Install `resvg` when available in your Debian/Ubuntu release:

```bash
sudo apt install resvg
```

On Debian/Ubuntu, `fd-find` normally installs `fdfind`, while Yazi expects `fd`. Add a compatibility symlink if needed:

```bash
mkdir -p ~/.local/bin
ln -sf "$(command -v fdfind)" ~/.local/bin/fd
export PATH="$HOME/.local/bin:$PATH"
```

Persist the PATH line in `~/.bashrc` or `~/.zshrc` if `~/.local/bin` is not already in PATH.

Clipboard on Wayland:

```bash
sudo apt install wl-clipboard
```

Clipboard on X11:

```bash
sudo apt install xclip
```

## Install config manually

```bash
mkdir -p ~/.config/yazi
cp ./yazi.toml ~/.config/yazi/yazi.toml
cp ./theme.toml ~/.config/yazi/theme.toml
cp ./keymap.toml ~/.config/yazi/keymap.toml
```

Install VS Code Dark+:

```bash
ya pkg add 956MB/vscode-dark-plus
```

Then:

```bash
ya cache clear
yazi
```

## Automatic Linux installation

The supplied helper supports Arch/pacman, Debian/Ubuntu/apt, and Fedora/RHEL-compatible dnf:

```bash
chmod +x ./install-linux.sh
./install-linux.sh
```

---

# Optional: shell wrapper `y`

Yazi can return the directory you ended in to the parent shell. This is useful because after navigating somewhere in Yazi and pressing `q`, your terminal can remain in that directory.

## PowerShell

The ready function is in:

```text
shell/powershell-wrapper.ps1
```

Open your profile:

```powershell
notepad $PROFILE
```

Copy the function from `shell/powershell-wrapper.ps1` into the profile, restart the shell, and use:

```powershell
y
```

instead of:

```powershell
yazi
```

## Bash / Zsh

Copy the function from:

```text
shell/bash-zsh-wrapper.sh
```

into `~/.bashrc` or `~/.zshrc`.

Then reload the shell and run:

```bash
y
```

---

# Useful default Yazi keys

| Key | Action |
| --- | --- |
| `j` / Down | next file |
| `k` / Up | previous file |
| `l` / Right | enter directory |
| `h` / Left | parent directory |
| `J` | scroll preview down |
| `K` | scroll preview up |
| `.` | hidden files on/off |
| `s` | search filenames with `fd` |
| `S` | search contents with `ripgrep` |
| `z` | navigate with `fzf` |
| `Z` | navigate with `zoxide` |
| `Space` | select file |
| `Tab` | file information / MIME |
| `!` | shell in current directory (custom config) |
| `F1` / `~` | help |
| `q` | quit |

---

# Image preview and WezTerm

WezTerm has built-in image protocol support understood by Yazi, so JPG/PNG/WebP image preview does not require a separate Yazi image plugin.

The current preview settings are:

```toml
[preview]
wrap = "yes"
tab_size = 4
max_width = 1200
max_height = 1000
image_delay = 30
image_filter = "lanczos3"
image_quality = 85
```

If you change `max_width` or `max_height`, run:

```text
ya cache clear
```

---

# Nerd Font

A Nerd Font is recommended for Yazi icons. If Starship icons already display correctly in your WezTerm setup, you probably already have a compatible font configured.

If Yazi displays empty squares or missing glyphs, configure a Nerd Font in your terminal.

---

# File overview

```text
yazi-cross-platform/
|-- yazi.toml
|-- theme.toml
|-- keymap.toml
|-- install-windows.ps1
|-- install-linux.sh
|-- README.md
`-- shell/
    |-- powershell-wrapper.ps1
    `-- bash-zsh-wrapper.sh
```

The flavor itself is not copied into this repository. Install/update it using Yazi's package manager:

```text
ya pkg add 956MB/vscode-dark-plus
```

# Yazi Cheat Sheet

## Nawigacja

| Skrót     | Akcja                 |
| --------- | --------------------- |
| `j` / `↓` | następny plik         |
| `k` / `↑` | poprzedni plik        |
| `h` / `←` | katalog wyżej         |
| `l` / `→` | wejście do katalogu   |
| `Enter`   | otwórz plik / katalog |
| `gg`      | początek listy        |
| `G`       | koniec listy          |
| `Ctrl+u`  | pół strony w górę     |
| `Ctrl+d`  | pół strony w dół      |

## Zaznaczanie

| Skrót    | Akcja                               |
| -------- | ----------------------------------- |
| `Space`  | zaznacz / odznacz                   |
| `Ctrl+a` | zaznacz wszystko                    |
| `Ctrl+r` | odwróć zaznaczenie                  |
| `v`      | visual mode                         |
| `Esc`    | wyczyść zaznaczenie / wyjdź z trybu |

## Operacje na plikach

| Skrót | Akcja               |
| ----- | ------------------- |
| `y`   | kopiuj              |
| `x`   | wytnij              |
| `p`   | wklej               |
| `P`   | wklej z nadpisaniem |
| `d`   | przenieś do kosza   |
| `D`   | usuń permanentnie   |
| `r`   | zmień nazwę         |
| `a`   | nowy plik / katalog |

### Przykłady

```text
a -> test.php
a -> nowy-folder/
```

## Ukryte pliki

| Skrót | Akcja                      |
| ----- | -------------------------- |
| `.`   | pokaż / ukryj hidden files |

## Wyszukiwanie

| Skrót    | Akcja                               |
| -------- | ----------------------------------- |
| `f`      | filtruj bieżącą listę               |
| `/`      | szukaj nazwy na liście              |
| `n`      | następny wynik                      |
| `N`      | poprzedni wynik                     |
| `s`      | szukaj plików przez `fd`            |
| `S`      | szukaj w zawartości przez `ripgrep` |
| `Ctrl+s` | przerwij wyszukiwanie               |

## FZF / Zoxide

| Skrót | Akcja                            |
| ----- | -------------------------------- |
| `z`   | szybkie wyszukiwanie przez `fzf` |
| `Z`   | skok do katalogu przez `zoxide`  |

## Kopiowanie do schowka

| Skrót | Akcja                         |
| ----- | ----------------------------- |
| `cc`  | kopiuj pełną ścieżkę          |
| `cd`  | kopiuj ścieżkę katalogu       |
| `cf`  | kopiuj nazwę pliku            |
| `cn`  | kopiuj nazwę bez rozszerzenia |

## Szybkie katalogi

| Skrót         | Akcja                 |
| ------------- | --------------------- |
| `gh`          | katalog domowy        |
| `gc`          | `~/.config`           |
| `gd`          | `Downloads`           |
| `gt`          | kosz                  |
| `g` + `Space` | wpisz ścieżkę ręcznie |

## Sortowanie

| Skrót | Akcja                          |
| ----- | ------------------------------ |
| `, n` | naturalne                      |
| `, N` | naturalne odwrotnie            |
| `, a` | alfabetycznie                  |
| `, A` | alfabetycznie odwrotnie        |
| `, m` | po dacie modyfikacji           |
| `, M` | po dacie modyfikacji odwrotnie |
| `, s` | po rozmiarze                   |
| `, S` | po rozmiarze odwrotnie         |
| `, e` | po rozszerzeniu                |
| `, E` | po rozszerzeniu odwrotnie      |

## Taby

| Skrót    | Akcja               |
| -------- | ------------------- |
| `tt`     | nowy tab            |
| `tr`     | zmień nazwę taba    |
| `1..9`   | przejdź do taba     |
| `[`      | poprzedni tab       |
| `]`      | następny tab        |
| `{`      | przesuń tab w lewo  |
| `}`      | przesuń tab w prawo |
| `Ctrl+c` | zamknij tab         |

## Preview

| Skrót | Akcja                  |
| ----- | ---------------------- |
| `Tab` | szczegóły pliku        |
| `J`   | przewiń preview w dół  |
| `K`   | przewiń preview w górę |

## Shell

| Skrót | Akcja                            |
| ----- | -------------------------------- |
| `;`   | uruchom komendę shell            |
| `:`   | uruchom komendę i czekaj         |
| `!`   | otwórz shell w bieżącym katalogu |

> `!` to nasz custom keybind.

## Pomoc / wyjście

| Skrót | Akcja   |
| ----- | ------- |
| `F1`  | pomoc   |
| `~`   | pomoc   |
| `q`   | wyjście |
