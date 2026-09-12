# WM layer — wersja poprawiona pod Keychron / VIA

W Keychron/VIA zamiast skrótów typu `LCG(...)` i `LSG(...)` używaj pełnego zapisu zagnieżdżonego, np. `LCTL(LGUI(KC_LEFT))`. Na Twojej K12 Pro taka forma działa stabilniej.

```text
LCTL(LGUI(KC_LEFT))    = Win+Ctrl+Left        = poprzedni pulpit
LCTL(LGUI(KC_RGHT))    = Win+Ctrl+Right       = następny pulpit
LCTL(LGUI(KC_F4))      = Win+Ctrl+F4          = zamknij aktualny pulpit

LSFT(LGUI(KC_LEFT))    = Win+Shift+Left       = przenieś okno na lewy monitor
LSFT(LGUI(KC_RGHT))    = Win+Shift+Right      = przenieś okno na prawy monitor

###############################################################################

LGUI(KC_LEFT)          = Win+Left             = przypnij okno w lewo
LGUI(KC_DOWN)          = Win+Down             = przywróć / minimalizuj okno
LGUI(KC_UP)            = Win+Up               = maksymalizuj okno
LGUI(KC_RGHT)          = Win+Right            = przypnij okno w prawo


LGUI(KC_D)             = Win+D                = pokaż pulpit
LCTL(LGUI(KC_D))       = Win+Ctrl+D           = nowy pulpit

###############################################################################

LALT(KC_TAB)           = Alt+Tab              = przełączanie okien
LGUI(KC_TAB)           = Win+Tab              = Task View
```

Pełny blok do wklejania na layer WM:

```text
LGUI(KC_TAB)           LCTL(LGUI(KC_LEFT))    LCTL(LGUI(KC_RGHT))    LCTL(LGUI(KC_D))    LCTL(LGUI(KC_F4))    LGUI(KC_D)
LGUI(KC_LEFT)          LGUI(KC_DOWN)          LGUI(KC_UP)            LGUI(KC_RGHT)       LGUI(KC_Z)           LALT(KC_TAB)
LSFT(LGUI(KC_LEFT))    LSFT(LGUI(KC_RGHT))    LGUI(KC_E)             LGUI(KC_R)          LGUI(KC_V)           KC_PSCR
```

