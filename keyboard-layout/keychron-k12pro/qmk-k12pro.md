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



## FIRMAWARE
# Keychron K12 Pro — backup firmware’u i zmiana ustawień myszy w QMK

Tak. **Plan bezpieczeństwa jest prosty: najpierw backup VIA layoutu, potem build custom firmware’u z keymapy `via`, a jak coś popsujesz, wracasz oficjalnym firmware’em przez DFU / QMK Toolbox.**

---

## 1. Jak wrócić do fabrycznego firmware’u

Oficjalna instrukcja Keychrona dla **K12 Pro**:

```text
https://keychron.be/pages/how-to-factory-reset-and-flash-firmware-for-your-k12-pro-keyboard
```

Tam są linki do:

```text
K12 Pro ANSI White Backlit Version Firmware
K12 Pro ANSI RGB Version Firmware
K12 Pro ANSI White Backlit Keymap JSON
K12 Pro ANSI RGB Keymap JSON
```

Najważniejsze: **pobierz dokładnie firmware dla swojej wersji**:

```text
K12 Pro ANSI RGB
```

albo:

```text
K12 Pro ANSI White Backlight
```

Nie pomyl RGB z White.

---

## 2. Procedura awaryjna powrotu do stock firmware’u

```text
1. Pobierz oficjalny firmware K12 Pro z Keychrona.
2. Pobierz QMK Toolbox.
3. Odłącz klawiaturę.
4. Otwórz QMK Toolbox.
5. Ustaw przełącznik klawiatury na Off.
6. Przytrzymaj reset pod spacją albo użyj kombinacji wejścia w bootloader.
7. Przełącz klawiaturę na Cable.
8. QMK Toolbox powinien pokazać: "***DFU device connected".
9. Kliknij Open i wybierz oficjalny plik firmware.
10. Kliknij Flash.
11. Nie odłączaj kabla podczas flashowania.
12. Po flashu zrób factory reset: fn1 + J + Z przez 4 sekundy.
```

Ogólna instrukcja Keychrona do flashowania przez QMK Toolbox:

```text
https://keychronsupport.zendesk.com/hc/en-us/articles/36489941127703-How-to-flash-the-keyboard-firmware-with-the-QMK-toolbox
```

Dopóki klawiatura wchodzi w **DFU / bootloader**, zwykle da się ją odratować przez ponowny flash.

Najbardziej prawdopodobny problem przy takich zmianach to nie pełny brick, tylko:

```text
- źle działająca mysz,
- niedziałające VIA,
- utrata layoutu VIA,
- zły mapping klawiszy,
- niepasujące ustawienia RGB / White.
```

Wtedy po prostu wgrywasz stock firmware albo swój poprzedni build.

---

## 3. Najpierw zrób backup obecnego layoutu z VIA

Skoro masz layout już gotowy, **nie ruszaj go w kodzie na start**.

W VIA zrób:

```text
Save / Export layout
```

i zachowaj plik `.json`.

To jest ważne, bo po flashowaniu albo po `fn1 + J + Z` layout z VIA może wrócić do defaultu.

Przed grzebaniem miej lokalnie trzy rzeczy:

```text
1. swój VIA layout export.json
2. oficjalny Keychron K12 Pro firmware .bin
3. oficjalny Keychron K12 Pro VIA JSON
```

Oficjalne firmware’y i JSON-y Keychrona:

```text
https://www.keychron.com/pages/firmware-and-json-files-of-the-keychron-qmk-k-pro-and-k-max-series-keyboards
```

---

## 4. Jak zmienić tylko wartości myszy i nie ruszać layoutu

Najlepszy sposób: **kopiujesz keymapę `via` i zmieniasz tylko `config.h`**.

Repo:

```text
https://github.com/Keychron/qmk_firmware
```

Branch:

```text
wireless_playground
```

Katalog K12 Pro:

```text
keyboards/keychron/k12_pro
```

Bezpośredni link:

```text
https://github.com/Keychron/qmk_firmware/tree/wireless_playground/keyboards/keychron/k12_pro
```

---

## 5. Clone repo

```bash
git clone --recurse-submodules -b wireless_playground --single-branch https://github.com/Keychron/qmk_firmware.git keychron_qmk
cd keychron_qmk
```

---

## 6. Skopiowanie keymapy VIA

Dla wersji **RGB**:

```bash
cp -r keyboards/keychron/k12_pro/ansi/rgb/keymaps/via \
      keyboards/keychron/k12_pro/ansi/rgb/keymaps/mymouse
```

Dla wersji **White Backlight**:

```bash
cp -r keyboards/keychron/k12_pro/ansi/white/keymaps/via \
      keyboards/keychron/k12_pro/ansi/white/keymaps/mymouse
```

Dzięki temu bazujesz na keymapie kompatybilnej z VIA, ale możesz zmienić tylko parametry firmware’u.

---

## 7. Edycja ustawień Mouse Keys

Dla wersji RGB edytuj:

```text
keyboards/keychron/k12_pro/ansi/rgb/keymaps/mymouse/config.h
```

Dla wersji White edytuj:

```text
keyboards/keychron/k12_pro/ansi/white/keymaps/mymouse/config.h
```

Dodaj albo zmień tam:

```c
#pragma once

#undef MOUSEKEY_DELAY
#undef MOUSEKEY_INTERVAL
#undef MOUSEKEY_MOVE_DELTA
#undef MOUSEKEY_MAX_SPEED
#undef MOUSEKEY_TIME_TO_MAX

#undef MOUSEKEY_WHEEL_DELAY
#undef MOUSEKEY_WHEEL_INTERVAL
#undef MOUSEKEY_WHEEL_DELTA
#undef MOUSEKEY_WHEEL_MAX_SPEED
#undef MOUSEKEY_WHEEL_TIME_TO_MAX

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

---

## 8. Co oznaczają te wartości

```c
#define MOUSEKEY_TIME_TO_MAX 0
```

Wyłącza akcelerację kursora.

```c
#define MOUSEKEY_WHEEL_TIME_TO_MAX 0
```

Wyłącza akcelerację scrolla.

```c
#define MOUSEKEY_INTERVAL 16
```

Wpływa na płynność ruchu. Niższa wartość = częstsze update’y.

```c
#define MOUSEKEY_MOVE_DELTA 4
```

Podstawowy krok ruchu kursora.

```c
#define MOUSEKEY_MAX_SPEED 8
```

Maksymalna prędkość kursora.

```c
#define MOUSEKEY_WHEEL_INTERVAL 60
```

Interwał scrolla.

```c
#define MOUSEKEY_WHEEL_DELTA 1
```

Podstawowy krok scrolla.

Dokumentacja QMK Mouse Keys:

```text
https://docs.qmk.fm/features/mouse_keys
```

---

## 9. Dlaczego używać `#undef`

Daję `#undef`, bo konfiguracje QMK składają się z kilku poziomów:

```text
QMK default
keyboard
folder / wariant
keymap
```

Keymap ma najwyższy priorytet, ale przy redefinicjach bezpieczniej jawnie zrobić:

```c
#undef SOME_OPTION
#define SOME_OPTION value
```

Dokumentacja QMK Config Options:

```text
https://docs.qmk.fm/config_options
```

---

## 10. Build custom firmware

Dla wersji **RGB**:

```bash
make keychron/k12_pro/ansi/rgb:mymouse
```

Dla wersji **White Backlight**:

```bash
make keychron/k12_pro/ansi/white:mymouse
```

---

## 11. Flash custom firmware

Dla wersji **RGB**:

```bash
make keychron/k12_pro/ansi/rgb:mymouse:flash
```

Dla wersji **White Backlight**:

```bash
make keychron/k12_pro/ansi/white:mymouse:flash
```

Możesz też zbudować firmware i wgrać plik przez QMK Toolbox.

---

## 12. Co z twoim istniejącym layoutem?

Są dwa przypadki.

### Przypadek A: layout robiłeś w VIA

Jeżeli layout robiłeś w **VIA**, to on siedzi jako dynamic keymap w pamięci klawiatury, a nie w `keymap.c`.

Wtedy robisz custom firmware z keymapy `via`, zmieniasz tylko `config.h`, flashujesz, a potem:

```text
- jeżeli layout został: nic nie robisz
- jeżeli layout zniknął: importujesz swój zapisany VIA layout JSON
```

Czyli nie musisz przepisywać całego layoutu do C.

### Przypadek B: layout masz jako kod QMK

Jeżeli layout masz już jako kod QMK w `keymap.c`, to kopiujesz swój `keymap.c` do:

Dla RGB:

```text
keyboards/keychron/k12_pro/ansi/rgb/keymaps/mymouse/keymap.c
```

Dla White:

```text
keyboards/keychron/k12_pro/ansi/white/keymaps/mymouse/keymap.c
```

I obok niego dodajesz albo edytujesz:

```text
config.h
```

Ale jeżeli cały layout jest już wygodnie ustawiony w VIA, to najlepiej **nie przenosić go teraz do C**.

Zostaw VIA layout jako VIA layout, a w firmware zmień tylko parametry myszy.

---

## 13. Najbezpieczniejszy workflow

```text
1. Export layoutu z VIA do pliku JSON.
2. Pobierz oficjalny firmware Keychrona dla twojej wersji K12 Pro.
3. Pobierz oficjalny K12 Pro VIA JSON.
4. Sklonuj repo Keychrona z branchem wireless_playground.
5. Zbuduj najpierw czysty build z keymapy via bez zmian.
6. Dopiero potem skopiuj via -> mymouse.
7. Zmień tylko config.h.
8. Zbuduj mymouse.
9. Flash.
10. Test myszy.
11. Jak jest źle, zmieniasz wartości i flashujesz ponownie.
12. Jak wszystko się wysypie, flashujesz oficjalny firmware Keychrona przez QMK Toolbox.
13. Importujesz swój layout VIA JSON.
```

---

## 14. Minimalny sensowny wariant testowy

Jeżeli chcesz tylko wyłączyć akcelerację i nie przesadzać ze zmianami, zacząłbym od tego:

```c
#pragma once

#undef MOUSEKEY_TIME_TO_MAX
#undef MOUSEKEY_WHEEL_TIME_TO_MAX

#define MOUSEKEY_TIME_TO_MAX 0
#define MOUSEKEY_WHEEL_TIME_TO_MAX 0
```

To jest najmniej inwazyjna zmiana.

Jeżeli samo wyłączenie akceleracji nie wystarczy, dopiero wtedy zmieniałbym:

```c
#define MOUSEKEY_MOVE_DELTA 4
#define MOUSEKEY_MAX_SPEED 8
#define MOUSEKEY_INTERVAL 16
```

---

## 15. Podsumowanie

Nie musisz ruszać gotowego layoutu, jeżeli zależy ci tylko na prędkości albo akceleracji myszy.

Najbezpieczniej:

```text
- eksportujesz layout z VIA,
- pobierasz stock firmware,
- kopiujesz keymapę via,
- zmieniasz tylko config.h,
- budujesz i flashujesz custom firmware,
- w razie problemu wracasz stock firmware’em przez QMK Toolbox.
```

Target RGB:

```text
keychron/k12_pro/ansi/rgb:mymouse
```

Target White:

```text
keychron/k12_pro/ansi/white:mymouse
```
