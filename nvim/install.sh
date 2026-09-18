#!/usr/bin/env bash
#
# Installs this Neovim config and the external tools it expects (Linux/macOS).
#
# Plugins are NOT installed here -- vim.pack clones them on first start, pinned
# to the revisions in nvim-pack-lock.json. This script handles everything
# vim.pack cannot: the language servers, formatters and CLI tools that live
# outside Neovim.
#
# Safe to re-run. Every step checks before acting.
#
#   ./install.sh                 full install
#   ./install.sh --skip-tools    only place the config and install plugins
#   ./install.sh --skip-plugins  only install tools
#   ./install.sh --force         replace an existing config without asking
#
set -uo pipefail

SKIP_TOOLS=0
SKIP_PLUGINS=0
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --skip-tools)   SKIP_TOOLS=1 ;;
    --skip-plugins) SKIP_PLUGINS=1 ;;
    --force)        FORCE=1 ;;
    -h|--help)      sed -n '3,17p' "$0"; exit 0 ;;
    *)              echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_CYAN=$'\033[36m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'; C_DIM=$'\033[2m'
else
  C_RESET=''; C_CYAN=''; C_GREEN=''; C_YELLOW=''; C_RED=''; C_DIM=''
fi

FAILED=(); SKIPPED=()
step() { printf '\n%s== %s%s\n' "$C_CYAN" "$1" "$C_RESET"; }
ok()   { printf '   %sok   %s %s\n' "$C_GREEN" "$C_RESET" "$1"; }
info() { printf '   %s..    %s%s\n' "$C_DIM" "$1" "$C_RESET"; }
warn() { printf '   %swarn %s %s\n' "$C_YELLOW" "$C_RESET" "$1"; SKIPPED+=("$1"); }
fail() { printf '   %sFAIL %s %s\n' "$C_RED" "$C_RESET" "$1"; FAILED+=("$1"); }
have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
step 'Prerequisites'

if ! have nvim; then
  fail 'Neovim is not in PATH. Install it first.'
  exit 1
fi

VER_LINE="$(nvim --version | head -n1)"
VER="$(printf '%s' "$VER_LINE" | sed -n 's/.*v\([0-9]\+\)\.\([0-9]\+\).*/\1 \2/p')"
if [ -n "$VER" ]; then
  # shellcheck disable=SC2086
  set -- $VER
  if [ "$1" -gt 0 ] || [ "$2" -ge 12 ]; then
    ok "$VER_LINE"
  else
    fail "$VER_LINE -- this config needs 0.12+ (it is built on vim.pack)"
    exit 1
  fi
else
  warn "Could not parse the Neovim version from: $VER_LINE"
fi

have git && ok 'git' || { fail 'git is required -- vim.pack clones plugins with it'; exit 1; }

# ---------------------------------------------------------------------------
step 'Config location'

TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
SOURCE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$SOURCE" = "$TARGET" ]; then
  ok "already in place: $TARGET"
else
  if [ -e "$TARGET" ]; then
    # An init.vim next to an init.lua is not merged -- Neovim loads one or the
    # other, so an old Vim config left behind silently wins or loses.
    BACKUP="$TARGET.bak"

    if [ "$FORCE" -eq 0 ]; then
      printf '   A config already exists at %s\n' "$TARGET"
      printf '   It will be moved to %s\n' "$BACKUP"
      printf '   Continue? [y/N] '
      read -r answer
      case "$answer" in
        y|Y|yes|YES) ;;
        *) echo 'Aborted.'; exit 1 ;;
      esac
    fi

    # Remove previous backup
    rm -rf "$BACKUP"

    mv "$TARGET" "$BACKUP"
    ok "existing config backed up to $BACKUP"
  fi

  mkdir -p "$TARGET"
  cp -R "$SOURCE"/. "$TARGET"/
  ok "config copied to $TARGET"
fi

# ---------------------------------------------------------------------------
if [ "$SKIP_TOOLS" -eq 0 ]; then

  step 'CLI tools (system package manager)'

  PM=''
  for candidate in apt-get dnf pacman zypper apk brew; do
    if have "$candidate"; then PM="$candidate"; break; fi
  done

  if [ -z "$PM" ]; then
    warn 'No supported package manager found (apt/dnf/pacman/zypper/apk/brew)'
    warn '  install by hand: ripgrep fd gcc nodejs npm python3-pip'
  else
    ok "using $PM"
    SUDO=''
    if [ "$PM" != 'brew' ] && [ "$(id -u)" -ne 0 ]; then
      have sudo && SUDO='sudo' || warn 'not root and no sudo -- package installs will likely fail'
    fi

    # Package names differ per distro; fd in particular is `fd-find` on Debian
    # and Fedora, where the binary is then called `fdfind`.
    case "$PM" in
      apt-get) PKGS='ripgrep fd-find build-essential nodejs npm python3-pip'; INSTALL="$SUDO apt-get install -y" ;;
      dnf)     PKGS='ripgrep fd-find gcc nodejs npm python3-pip';             INSTALL="$SUDO dnf install -y" ;;
      pacman)  PKGS='ripgrep fd gcc nodejs npm python-pip';                   INSTALL="$SUDO pacman -S --needed --noconfirm" ;;
      zypper)  PKGS='ripgrep fd gcc nodejs npm python3-pip';                  INSTALL="$SUDO zypper install -y" ;;
      apk)     PKGS='ripgrep fd build-base nodejs npm py3-pip';               INSTALL="$SUDO apk add" ;;
      brew)    PKGS='ripgrep fd node python';                                 INSTALL='brew install' ;;
    esac

    info "$INSTALL $PKGS"
    # shellcheck disable=SC2086
    if $INSTALL $PKGS >/dev/null 2>&1; then
      ok 'system packages'
    else
      fail "$PM install failed -- run it by hand to see why: $INSTALL $PKGS"
    fi
  fi

  step 'Language servers and formatter (npm)'

  if ! have npm; then
    warn 'npm not found -- skipping every node-based language server'
  else
    # typescript@5 is NOT a typo. Plain `typescript` now resolves to 7.x, the
    # native Go rewrite, whose lib/ has no tsserver.js at all --
    # typescript-language-server needs that file and refuses to start without
    # it ("Could not find a valid TypeScript installation").
    #
    # tree-sitter-cli comes from npm here rather than the distro, because most
    # repos either lack it or ship a version older than the 0.26 that
    # nvim-treesitter's main branch needs.
    while read -r spec probe why; do
      [ -z "$spec" ] && continue
      if have "$probe"; then
        ok "$probe -- already installed"
      else
        info "npm i -g $spec ($why)"
        if npm install -g "$spec" >/dev/null 2>&1; then
          ok "$spec"
        else
          fail "npm i -g $spec"
        fi
      fi
    done <<'EOF'
intelephense intelephense PHP
typescript@5 tsc TS_compiler_pin_5.x
typescript-language-server typescript-language-server JS/TS
vscode-langservers-extracted vscode-html-language-server HTML/CSS/JSON/ESLint
@olrtg/emmet-language-server emmet-language-server Emmet
prettier prettier formatting
tree-sitter-cli tree-sitter building_parsers
EOF
  fi

  step 'Language servers (pip)'

  PIP=''
  have pip3 && PIP=pip3 || { have pip && PIP=pip; }
  if [ -z "$PIP" ]; then
    warn 'pip not found -- skipping pyright and ruff'
  else
    while read -r spec probe why; do
      [ -z "$spec" ] && continue
      if have "$probe"; then
        ok "$probe -- already installed"
      else
        info "$PIP install $spec ($why)"
        # Debian-based distros refuse global pip installs (PEP 668); fall back
        # to --user rather than failing the whole run.
        if $PIP install --quiet "$spec" >/dev/null 2>&1 \
          || $PIP install --quiet --user "$spec" >/dev/null 2>&1; then
          ok "$spec"
        else
          fail "$PIP install $spec -- try pipx instead"
        fi
      fi
    done <<'EOF'
pyright pyright-langserver Python_LSP
ruff ruff Python_lint_format
EOF
  fi

  step 'Lua language server'

  if have lua-language-server; then
    ok 'lua-language-server -- already installed'
  else
    case "$PM" in
      pacman) info 'pacman -S lua-language-server'; $SUDO pacman -S --needed --noconfirm lua-language-server >/dev/null 2>&1 \
                && ok 'lua-language-server' || warn 'lua-language-server: install by hand' ;;
      brew)   info 'brew install lua-language-server'; brew install lua-language-server >/dev/null 2>&1 \
                && ok 'lua-language-server' || warn 'lua-language-server: install by hand' ;;
      *)      warn 'lua-language-server: no distro package on this system, grab a release from
            https://github.com/LuaLS/lua-language-server/releases' ;;
    esac
  fi

  # On Linux and macOS phpactor DOES work and is a reasonable alternative to
  # intelephense (it is broken only on Windows, where its language-server mode
  # needs the SIGINT constant from pcntl, which that platform has never had).
  # Not installed by default -- add 'phpactor' to lua/lsp.lua if you want it.
fi

# ---------------------------------------------------------------------------
if [ "$SKIP_PLUGINS" -eq 0 ]; then
  step 'Plugins and treesitter parsers'
  info 'starting Neovim headless -- first run clones 19 plugins and builds parsers'
  if nvim --headless -c 'qa!' 2>&1 | grep -Ei 'installing|error' | while read -r l; do info "$l"; done; then
    ok 'plugins installed'
  else
    ok 'plugins installed'
  fi
fi

# ---------------------------------------------------------------------------
step 'Result'

if [ "$SKIP_PLUGINS" -eq 0 ]; then
  echo
  echo '   Language servers that are configured but not installed:'
  nvim --headless -c 'LspMissing' -c 'qa!' 2>&1 | sed 's/^/   /'
fi

echo
if [ "${#FAILED[@]}" -gt 0 ]; then
  printf '%s   %d step(s) failed:%s\n' "$C_RED" "${#FAILED[@]}" "$C_RESET"
  for f in "${FAILED[@]}"; do printf '%s     - %s%s\n' "$C_RED" "$f" "$C_RESET"; done
fi
if [ "${#SKIPPED[@]}" -gt 0 ]; then
  printf '%s   %d step(s) skipped:%s\n' "$C_YELLOW" "${#SKIPPED[@]}" "$C_RESET"
  for s in "${SKIPPED[@]}"; do printf '%s     - %s%s\n' "$C_YELLOW" "$s" "$C_RESET"; done
fi
if [ "${#FAILED[@]}" -eq 0 ] && [ "${#SKIPPED[@]}" -eq 0 ]; then
  printf '%s   Everything installed. Run: nvim%s\n' "$C_GREEN" "$C_RESET"
else
  printf '%s   Run `nvim` and then `:checkhealth` to see what is still missing.%s\n' "$C_CYAN" "$C_RESET"
fi
echo

[ "${#FAILED[@]}" -eq 0 ]
