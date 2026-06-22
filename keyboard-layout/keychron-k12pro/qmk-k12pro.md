Dla **K12 Pro** źródła są w oficjalnym forku Keychrona na branchu:

```text
wireless_playground
```

Konkretny katalog:

```text
keyboards/keychron/k12_pro
```

Repo:

```text
https://github.com/Keychron/qmk_firmware/tree/wireless_playground/keyboards/keychron/k12_pro
```

Na branchach `master` i `2025q3` możesz tego nie znaleźć, bo Keychron trzyma część modeli, zwłaszcza wireless / Pro, właśnie na branchu `wireless_playground`.

---

## Targety dla K12 Pro

Dla wersji **ANSI RGB**:

```bash
make keychron/k12_pro/ansi/rgb:default
```

Dla wersji **ANSI White Backlight**:

```bash
make keychron/k12_pro/ansi/white:default
```

Flashowanie:

```bash
make keychron/k12_pro/ansi/rgb:default:flash
```

albo:

```bash
make keychron/k12_pro/ansi/white:default:flash
```

---

## Kroki

Sklonuj konkretnie branch `wireless_playground`:

```bash
git clone --recurse-submodules -b wireless_playground --single-branch https://github.com/Keychron/qmk_firmware.git keychron_qmk
cd keychron_qmk
```

Dla wersji RGB, żeby zachować VIA, skopiuj keymapę `via`:

```bash
cp -r keyboards/keychron/k12_pro/ansi/rgb/keymaps/via \
      keyboards/keychron/k12_pro/ansi/rgb/keymaps/mymouse
```

Dla wersji White analogicznie:

```bash
cp -r keyboards/keychron/k12_pro/ansi/white/keymaps/via \
      keyboards/keychron/k12_pro/ansi/white/keymaps/mymouse
```

---

## Zmiana prędkości i akceleracji Mouse Keys

Edytuj plik:

```text
keyboards/keychron/k12_pro/ansi/rgb/keymaps/mymouse/config.h
```

albo dla wersji White:

```text
keyboards/keychron/k12_pro/ansi/white/keymaps/mymouse/config.h
```

Dodaj albo zmień tam parametry Mouse Keys, np.:

```c
#pragma once

#define MOUSEKEY_DELAY 10
#define MOUSEKEY_INTERVAL 16
#define MOUSEKEY_MOVE_DELTA 4
#define MOUSEKEY_MAX_SPEED 8
#define MOUSEKEY_TIME_TO_MAX 0

#define MOUSEKEY_WHEEL_DELAY 10
#define MOUSEKEY_WHEEL_INTERVAL 60
#define MOUSEKEY_WHEEL_DELTA 1
#define MOUSEKEY_WHEEL_MAX_SPEED 3
#define MOUSEKEY_WHEEL_TIME_TO_MAX 0
```

Najważniejsze rzeczy:

```c
#define MOUSEKEY_TIME_TO_MAX 0
```

wyłącza akcelerację kursora.

```c
#define MOUSEKEY_WHEEL_TIME_TO_MAX 0
```

wyłącza akcelerację scrolla.

---

## Budowanie własnego firmware

Dla wersji RGB:

```bash
make keychron/k12_pro/ansi/rgb:mymouse
```

Dla wersji White:

```bash
make keychron/k12_pro/ansi/white:mymouse
```

Flashowanie RGB:

```bash
make keychron/k12_pro/ansi/rgb:mymouse:flash
```

Flashowanie White:

```bash
make keychron/k12_pro/ansi/white:mymouse:flash
```

---

## Wejście w DFU / bootloader

Według README Keychrona dla K12 Pro:

1. Podłącz klawiaturę po USB.
2. Przełącznik trybu ustaw na `Off`.
3. Przytrzymaj `Esc`.
4. Przełącz klawiaturę na `Cable`.
5. Puść `Esc`.

Alternatywnie można użyć fizycznego przycisku reset pod spacją.

---

## Backup / firmware fabryczny

Przed flashowaniem pobierz sobie oficjalny firmware i JSON dla dokładnej wersji klawiatury:

```text
https://www.keychron.com/pages/firmware-and-json-files-of-the-keychron-qmk-k-pro-and-k-max-series-keyboards
```

Są tam osobne pliki dla:

```text
K12 Pro ANSI White Backlight
K12 Pro ANSI RGB Backlight
```

To jest ważne, żeby mieć możliwość powrotu do fabrycznego firmware’u, gdyby custom build źle działał.

---

## Podsumowanie

Użyj:

```text
repo:   https://github.com/Keychron/qmk_firmware
branch: wireless_playground
```

Target RGB:

```text
keychron/k12_pro/ansi/rgb
```

Target White:

```text
keychron/k12_pro/ansi/white
```

Nie szukaj tego na `master` ani `2025q3`, bo dla K12 Pro właściwy branch to obecnie:

```text
wireless_playground
```
