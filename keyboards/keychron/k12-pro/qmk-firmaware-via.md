# FLASH

---

## Przygotuj środowisko

### Zainstaluj qmk msys

[qmk_msys](https://github.com/qmk/qmk_distro_msys/releases)

### Zainstaluj qmk toolbox

[qmk_toolbox](https://github.com/qmk/qmk_toolbox/releases/)

---

## Pobierz repozytorium

```bash
git clone --recurse-submodules -b wireless_playground --single-branch https://github.com/Keychron/qmk_firmware.git keychron_qmk
cd keychron_qmk
```

---

## Pobierz default firmware

`https://cdn.shopify.com/s/files/1/0059/0630/1017/files/k12_pro_ansi_rgb_v1.00.bin?v=1684118986`

---

## Utwórz nowy layout

```bash
qmk list-keyboards
qmk new-keymap -kb <keyboard>
```

### Ścieżka

```text
keyboards/keychron/k12_pro/ansi/rgb/keymaps/b4kii/
```

### Minimum

#### `keymap.c` - layout

#### `config.h` - stałe

```c
#define DYNAMIC_KEYMAP_LAYER_COUNT 5
#define MOUSEKEY_DELAY 10
#define MOUSEKEY_INTERVAL 20
#define MOUSEKEY_MOVE_DELTA 4
#define MOUSEKEY_MAX_SPEED 6
#define MOUSEKEY_TIME_TO_MAX 0
```

#### `rules.mk`

```makefile
MOUSEKEY_ENABLE = yes
VIA_ENABLE = yes
```

---

## Zbuduj firmware firmware

```bash
cd /c/Users/baki/keyboards/keychron_qmk
```

```bash
qmk compile -kb <keyboard> -km default
```

```bash
qmk compile -j 4 -kb keychron/k12_pro/ansi/rgb -km b4kii
```

### Firmware znajduje się w

```text
\keychron_qmk
```

---

### Flash firmware — krok po kroku
[FLASH](https://keychron.be/pages/how-to-factory-reset-and-flash-firmware-for-your-k12-pro-keyboard)

1. **Pobierz właściwy firmware dla Keychron K12 Pro.**  
   Wybierz wersję zgodną z klawiaturą:
   - ANSI White Backlight
   - ANSI RGB

2. **Pobierz i zainstaluj QMK Toolbox.**  
   Dostępne są wersje dla Windows i macOS.

3. **Odłącz kabel USB od klawiatury.**

4. **Uruchom QMK Toolbox.**

5. **Zdejmij keycap spacji.**  
   Po lewej stronie switcha spacji na PCB znajduje się fizyczny przycisk **Reset**.

6. **Wprowadź klawiaturę w tryb bootloadera.**
   - ustaw boczny przełącznik na **Off**,
   - podłącz kabel USB,
   - przytrzymaj przycisk **Reset** znajdujący się pod spacją,
   - trzymając **Reset**, przełącz klawiaturę z **Off** na **Cable**.

7. **Sprawdź QMK Toolbox.**  
   Klawiatura powinna wejść w tryb **DFU**, a QMK Toolbox powinien pokazać komunikat podobny do:

   ```text
   ***DFU device connected
   ```

8. **Wybierz firmware i rozpocznij flashowanie.**
   - kliknij **Open**,
   - wybierz pobrany firmware K12 Pro,
   - kliknij **Flash**.

   **Nie odłączaj kabla USB podczas flashowania.**

9. **Poczekaj na zakończenie flashowania.**  
   Po kilku sekundach QMK Toolbox powinien wyświetlić informację wskazującą, że proces zakończył się poprawnie.

10. **Po flashowaniu wykonaj ponownie Factory Reset.**

    ```text
    Fn1 + J + Z
    ```

    Przytrzymaj około **4 sekundy**, aż całe podświetlenie zamiga.
