# Instalacja Helix (budowa ze źródeł z użyciem Rustup)

## Instalacja Rusta (narzędzie rustup)

Nie używaj:

    sudo apt install cargo

Wersja z repozytorium będzie zbyt stara. Zamiast tego uruchom w
terminalu:

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

Podczas instalacji wybierz opcję **1 (default)**.

------------------------------------------------------------------------

## Odświeżenie środowiska (source)

Aby komenda `cargo` była widoczna, wczytaj ścieżki:

    source $HOME/.cargo/env

**Zalecane:** Dodaj poniższą linię do pliku `~/.zshrc` lub `~/.bashrc`,
aby nie robić tego ręcznie za każdym razem:

    export PATH="$HOME/.cargo/bin:$PATH"

------------------------------------------------------------------------

## Pobieranie kodu Helixa

    cd ~
    git clone https://github.com/helix-editor/helix
    cd helix

------------------------------------------------------------------------

## Budowanie i instalacja

Będąc w folderze `~/helix`, uruchom:

    cargo install --path helix-term --locked

Binarka `hx` zostanie zapisana w:

    ~/.cargo/bin/hx

------------------------------------------------------------------------

## Konfiguracja runtime (kluczowy krok)

Helix musi wiedzieć, gdzie znajdują się tematy i gramatyki. Wykonaj:

    mkdir -p ~/.config/helix
    rm -rf ~/.config/helix/runtime
    ln -s ~/helix/runtime ~/.config/helix/runtime

------------------------------------------------------------------------

## Porządki z poprzednią wersją

Jeśli miałeś Helixa instalowanego przez `apt`, usuń go:

    sudo apt remove helix

Sprawdź, czy system widzi nową wersję:

    which hx
    hx --version

------------------------------------------------------------------------

## Diagnostyka

Uruchom:

    hx --health

Sprawdź, czy pola **Runtime** i **Highlight** są poprawnie wykryte.
