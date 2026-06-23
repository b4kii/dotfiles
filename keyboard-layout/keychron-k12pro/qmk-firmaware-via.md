## How to flash 

### Przygotuj środowisko

#### Zainstaluj qmk msys 

`https://github.com/qmk/qmk_distro_msys/releases`
### Zainstaluj qmk toolbox
`https://github.com/qmk/qmk_toolbox/releases/download/0.2.2/qmk_toolbox.exe`

```bash
git clone --recurse-submodules -b wireless_playground --single-branch https://github.com/Keychron/qmk_firmware.git keychron_qmk
cd keychron_qmk
```
### Pobierz default firmware
`https://cdn.shopify.com/s/files/1/0059/0630/1017/files/k12_pro_ansi_rgb_v1.00.bin?v=1684118986`

### Utwórz nowy layout
qmk list-keyboards
qmk new-keymap -kb <keyboard>

Ścieżka:

keyboards/keychron/k12_pro/ansi/rgb/keymaps/b4kii/

Minimum:
    keymap.c - layout
    config.h - stałe
        #define DYNAMIC_KEYMAP_LAYER_COUNT 5
        #define MOUSEKEY_DELAY 10
        #define MOUSEKEY_INTERVAL 20
        #define MOUSEKEY_MOVE_DELTA 4
        #define MOUSEKEY_MAX_SPEED 6
        #define MOUSEKEY_TIME_TO_MAX 0

    rules.mk
        MOUSEKEY_ENABLE = yes
        VIA_ENABLE = yes

### Zbuduj firmware firmware
qmk compile -kb <keyboard> -km default
qmk compile -kb keychron/k12_pro/ansi/rgb -km b4kii

### Flash 
https://keychron.be/pages/how-to-factory-reset-and-flash-firmware-for-your-k12-pro-keyboard
