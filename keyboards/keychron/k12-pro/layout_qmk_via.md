# Layout QMK/VIA dla 3x6 + thumb cluster 4+4

Poprawiona propozycja po uwzględnieniu dwóch rzeczy:

- `LCtrl` masz już w miejscu CapsLocka, więc nie ma sensu dublować go na thumb clusterze.
- `Sym` najlepiej trzymać lewym kciukiem obok `Space`, bo wtedy prawa ręka może wygodnie wpisywać symbole programistyczne.

Założenie: układ **3x6 + 4 kciuki na lewo + 4 kciuki na prawo**.

---

## Podejście 1 — rekomendowane: Shift zostaje na prawym kciuku

To jest wersja, którą bym wybrał jako pierwszą, bo mówisz, że `Shift` na prawym kciuku jest dla Ciebie wygodny.

```text
BASE — podejście 1

LEWA 3x6                         PRAWA 3x6
Tab     Q     W     E     R     T        Y     U     I     O     P     Bsp
LCtrl   A     S     D     F     G        H     J     K     L     ;     Enter
LShift  Z     X     C     V     B        N     M     ,     .     /     Del

LEWY KCIUK                        PRAWY KCIUK
Num/Fn  LAlt   Sym   Space        RShift   Nav   WM/Win   RAlt/Esc
```

Logika thumb clusterów:

```text
LEWY KCIUK:
Num/Fn | LAlt | Sym | Space

PRAWY KCIUK:
RShift | Nav | WM/Win | RAlt/Esc
```

Dlaczego to ma sens:

```text
LCtrl zostaje pod CapsLockiem
Sym jest obok Space
Shift zostaje na prawym kciuku
Nav jest dostępny prawą ręką
WM/Win jest dostępny prawą ręką
RAlt zostaje dostępny do polskich znaków / AltGr
```

Przykładowe keycode’y QMK/VIA:

```text
LEWY KCIUK:
MO(2) | KC_LALT | MO(1) | KC_SPC

PRAWY KCIUK:
KC_RSFT | MO(4) | LT(3, KC_RGUI) | MT(MOD_RALT, KC_ESC)
```

Jeżeli `MT(MOD_RALT, KC_ESC)` nie działa dobrze w Keychron/VIA, uprość prawy kciuk do:

```text
KC_RSFT | MO(4) | LT(3, KC_RGUI) | KC_RALT
```

Wtedy `Esc` możesz dać np. na `Sym + Q`, `Nav + Bsp` albo inny wygodny klawisz layerowy.

---

## Podejście 2 — czystsze warstwowo, ale bez Shifta na kciuku

To jest wersja bardziej logicznie uporządkowana, ale może być mniej wygodna dla Ciebie, jeżeli faktycznie lubisz fizyczny `Shift` na thumb clusterze.

```text
BASE — podejście 2

LEWA 3x6                         PRAWA 3x6
Tab     Q     W     E     R     T        Y     U     I     O     P     Bsp
LCtrl   A     S     D     F     G        H     J     K     L     ;     Enter
LShift  Z     X     C     V     B        N     M     ,     .     /     RShift

LEWY KCIUK                        PRAWY KCIUK
Num/Fn  LAlt   Sym   Space        RAlt   Nav   WM/Win   Esc
```

Logika thumb clusterów:

```text
LEWY KCIUK:
Num/Fn | LAlt | Sym | Space

PRAWY KCIUK:
RAlt | Nav | WM/Win | Esc
```

Przykładowe keycode’y QMK/VIA:

```text
LEWY KCIUK:
MO(2) | KC_LALT | MO(1) | KC_SPC

PRAWY KCIUK:
KC_RALT | MO(4) | LT(3, KC_RGUI) | KC_ESC
```

Jeżeli chcesz odzyskać `RShift` bez trzymania go na kciuku, możesz zrobić `/` jako tap-hold:

```text
MT(MOD_RSFT, KC_SLSH)
```

Czyli:

```text
tap  = /
hold = Right Shift
```

---

# Symbol layer — wersja programistyczna

Najwygodniej trzymać `Sym` lewym kciukiem, a symbole programistyczne wpisywać głównie prawą ręką.

```text
LAYER 1 — SYM / PROGRAMMING

LEWA 3x6                         PRAWA 3x6
`      ~      !      @      #      $        <      >      [      ]      \      |
%      ^      &      *      ?      .        (      )      {      }      =      +
Esc    Tab    -      _      /      ,        '      "      :      ;      -      _
```

Najważniejsze mapowanie po prawej ręce:

```text
Sym + Y      = <
Sym + U      = >
Sym + I      = [
Sym + O      = ]
Sym + P      = \
Sym + Bsp    = |

Sym + H      = (
Sym + J      = )
Sym + K      = {
Sym + L      = }
Sym + ;      = =
Sym + Enter  = +

Sym + N      = '
Sym + M      = "
Sym + ,      = :
Sym + .      = ;
Sym + /      = -
Sym + Del    = _
```

To daje bardzo szybki dostęp do:

```text
() [] {} <> '' "" : ; = + \ |
```

czyli rzeczy, które często pojawiają się w JS/TS, Pythonie, Rust, C/C++, Go itd.

---

# Num/Fn layer

Nie mieszałbym wszystkich liczb i symboli na jednej warstwie. Lepiej mieć osobny `Num/Fn`, np. pod lewym zewnętrznym kciukiem.

```text
LAYER 2 — NUM / FN

LEWA 3x6                         PRAWA 3x6
F1     F2     F3     F4     F5     F6       7      8      9      -      =      Bsp
F7     F8     F9     F10    F11    F12      4      5      6      +      *      Enter
Esc    Tab    Home   End    PgUp   PgDn     1      2      3      0      .      /
```

Logika:

```text
Num/Fn + prawa ręka = numpad
Num/Fn + lewa ręka  = F1-F12 oraz dodatkowa nawigacja
```

---

---

# WM layer — wersja poprawiona pod Keychron / VIA

W Keychron/VIA zamiast skrótów typu `LCG(...)` i `LSG(...)` używaj pełnego zapisu zagnieżdżonego, np. `LCTL(LGUI(KC_LEFT))`. Na Twojej K12 Pro taka forma działa stabilniej.

```text
LCTL(LGUI(KC_LEFT))    = Win+Ctrl+Left        = poprzedni pulpit
LCTL(LGUI(KC_RGHT))    = Win+Ctrl+Right       = następny pulpit
LCTL(LGUI(KC_D))       = Win+Ctrl+D           = nowy pulpit
LCTL(LGUI(KC_F4))      = Win+Ctrl+F4          = zamknij aktualny pulpit
LGUI(KC_D)             = Win+D                = pokaż pulpit

LGUI(KC_LEFT)          = Win+Left             = przypnij okno w lewo
LGUI(KC_DOWN)          = Win+Down             = przywróć / minimalizuj okno
LGUI(KC_UP)            = Win+Up               = maksymalizuj okno
LGUI(KC_RGHT)          = Win+Right            = przypnij okno w prawo

LSFT(LGUI(KC_LEFT))    = Win+Shift+Left       = przenieś okno na lewy monitor
LSFT(LGUI(KC_RGHT))    = Win+Shift+Right      = przenieś okno na prawy monitor

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
