<#
.SYNOPSIS
  Installs this Neovim config and the external tools it expects (Windows).

.DESCRIPTION
  Plugins are NOT installed by this script -- vim.pack clones them on first
  start, pinned to the revisions in nvim-pack-lock.json. What this handles is
  everything vim.pack cannot: the language servers, formatters and CLI tools
  that live outside Neovim.

  Safe to re-run. Every step checks before acting, so nothing is reinstalled
  or overwritten without reason.

.PARAMETER SkipTools
  Only place the config and install plugins. No scoop / npm / pip calls.

.PARAMETER SkipPlugins
  Only install tools. Do not start Neovim.

.PARAMETER Force
  Replace an existing config without asking. The old one is still backed up.

.EXAMPLE
  .\install.ps1
  .\install.ps1 -SkipTools
#>
[CmdletBinding()]
param(
  [switch]$SkipTools,
  [switch]$SkipPlugins,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$script:Failed = @()
$script:Skipped = @()

function Say    { param($m) Write-Host $m }
function Step   { param($m) Write-Host "`n== $m" -ForegroundColor Cyan }
function Ok     { param($m) Write-Host "   ok    $m" -ForegroundColor Green }
function Info   { param($m) Write-Host "   ..    $m" -ForegroundColor DarkGray }
function Warn   { param($m) Write-Host "   warn  $m" -ForegroundColor Yellow; $script:Skipped += $m }
function Fail   { param($m) Write-Host "   FAIL  $m" -ForegroundColor Red; $script:Failed += $m }
function Have   { param($c) [bool](Get-Command $c -ErrorAction SilentlyContinue) }

# ---------------------------------------------------------------------------
Step 'Prerequisites'

if (-not (Have 'nvim')) {
  Fail 'Neovim is not in PATH. Install it first: scoop install neovim'
  exit 1
}

$verLine = (& nvim --version | Select-Object -First 1)
if ($verLine -match 'v(\d+)\.(\d+)') {
  $major = [int]$Matches[1]; $minor = [int]$Matches[2]
  if ($major -gt 0 -or $minor -ge 12) {
    Ok "$verLine"
  } else {
    Fail "$verLine -- this config needs 0.12+ (it is built on vim.pack)"
    exit 1
  }
} else {
  Warn "Could not parse the Neovim version from: $verLine"
}

if (Have 'git') { Ok 'git' } else { Fail 'git is required -- vim.pack clones plugins with it'; exit 1 }

# ---------------------------------------------------------------------------
Step 'Config location'

$target = Join-Path $env:LOCALAPPDATA 'nvim'
$source = $PSScriptRoot

if ($source -ieq $target) {
  Ok "already in place: $target"
} else {
  if (Test-Path $target) {
    # An init.vim next to an init.lua is not merged -- Neovim loads one or the
    # other, so an old Vim config left behind silently wins or loses.
    $backup = "$target.bak"

    if (-not $Force) {
      Say "   A config already exists at $target"
      Say "   It will be moved to $backup"
      $answer = Read-Host '   Continue? [y/N]'
      if ($answer -notmatch '^(y|yes)$') { Say 'Aborted.'; exit 1 }
    }

    # Usuń poprzedni backup
    Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue

    Move-Item -LiteralPath $target -Destination $backup
    Ok "existing config backed up to $backup"
  }

  New-Item -ItemType Directory -Force -Path $target | Out-Null
  Copy-Item -Path (Join-Path $source '*') -Destination $target -Recurse -Force
  Ok "config copied to $target"
}

# ---------------------------------------------------------------------------
if (-not $SkipTools) {

  Step 'CLI tools (scoop)'

  if (-not (Have 'scoop')) {
    Warn 'scoop not found -- skipping. Install these yourself, or get scoop from https://scoop.sh'
    Warn '  ripgrep fd tree-sitter lua-language-server gcc nodejs python'
  } else {
    # tree-sitter CLI + a C compiler are what let nvim-treesitter build parsers;
    # without them highlighting falls back to the handful bundled with Neovim.
    $scoopPkgs = @(
      @{ name = 'ripgrep';             probe = 'rg';                  why = '<leader>fg live grep' },
      @{ name = 'fd';                  probe = 'fd';                  why = 'faster <leader>ff' },
      @{ name = 'tree-sitter';         probe = 'tree-sitter';         why = 'building treesitter parsers' },
      @{ name = 'gcc';                 probe = 'gcc';                 why = 'compiling those parsers' },
      @{ name = 'lua-language-server'; probe = 'lua-language-server'; why = 'Lua LSP' },
      @{ name = 'nodejs';              probe = 'node';                why = 'most language servers' },
      @{ name = 'python';              probe = 'python';              why = 'Python LSP' }
    )
    foreach ($p in $scoopPkgs) {
      if (Have $p.probe) {
        Ok "$($p.probe) -- already installed"
      } else {
        Info "installing $($p.name) ($($p.why))"
        try { & scoop install $p.name *>&1 | Out-Null; Ok "$($p.name)" }
        catch { Fail "scoop install $($p.name): $_" }
      }
    }
  }

  Step 'Language servers and formatter (npm)'

  if (-not (Have 'npm')) {
    Warn 'npm not found -- skipping every node-based language server'
  } else {
    # typescript@5 is NOT a typo. Plain `typescript` now resolves to 7.x, the
    # native Go rewrite, whose lib/ has no tsserver.js at all --
    # typescript-language-server needs that file and refuses to start without
    # it ("Could not find a valid TypeScript installation").
    $npmPkgs = @(
      @{ spec = 'intelephense';                 probe = 'intelephense';               why = 'PHP' },
      @{ spec = 'typescript@5';                 probe = 'tsc';                        why = 'TS compiler -- pin 5.x' },
      @{ spec = 'typescript-language-server';   probe = 'typescript-language-server';  why = 'JS/TS' },
      @{ spec = 'vscode-langservers-extracted'; probe = 'vscode-html-language-server'; why = 'HTML/CSS/JSON/ESLint' },
      @{ spec = '@olrtg/emmet-language-server'; probe = 'emmet-language-server';       why = 'Emmet' },
      @{ spec = 'prettier';                     probe = 'prettier';                   why = '<leader>cf formatting' }
    )
    foreach ($p in $npmPkgs) {
      if (Have $p.probe) {
        Ok "$($p.probe) -- already installed"
      } else {
        Info "npm i -g $($p.spec) ($($p.why))"
        try { & npm install -g $p.spec *>&1 | Out-Null; Ok "$($p.spec)" }
        catch { Fail "npm i -g $($p.spec): $_" }
      }
    }
  }

  Step 'Python tooling (pip)'

  if (-not (Have 'pip')) {
    Warn 'pip not found -- skipping pyright and ruff'
  } else {
    foreach ($p in @(
      @{ spec = 'pyright'; probe = 'pyright-langserver'; why = 'Python LSP' },
      @{ spec = 'ruff';    probe = 'ruff';               why = 'Python lint + format' }
    )) {
      if (Have $p.probe) {
        Ok "$($p.probe) -- already installed"
      } else {
        Info "pip install $($p.spec) ($($p.why))"
        try { & pip install --quiet $p.spec *>&1 | Out-Null; Ok "$($p.spec)" }
        catch { Fail "pip install $($p.spec): $_" }
      }
    }
  }

  # phpactor is deliberately absent: its language-server mode needs the SIGINT
  # constant from the pcntl extension, which does not exist on Windows. It
  # exits 255 before the LSP handshake. intelephense is the one that works.
}

# ---------------------------------------------------------------------------
if (-not $SkipPlugins) {
  Step 'Plugins and treesitter parsers'
  Info 'starting Neovim headless -- first run clones 19 plugins and builds parsers'
  try {
    & nvim --headless -c 'qa!' 2>&1 | Where-Object { $_ -match 'Installing|Error|error' } | ForEach-Object { Info $_ }
    Ok 'plugins installed'
  } catch {
    Fail "headless start failed: $_"
  }
}

# ---------------------------------------------------------------------------
Step 'Result'

if (-not $SkipPlugins) {
  Say ''
  Say '   Language servers that are configured but not installed:'
  & nvim --headless -c 'LspMissing' -c 'qa!' 2>&1 | ForEach-Object { Say "   $_" }
}

Say ''
if ($script:Failed.Count -gt 0) {
  Write-Host "   $($script:Failed.Count) step(s) failed:" -ForegroundColor Red
  $script:Failed | ForEach-Object { Write-Host "     - $_" -ForegroundColor Red }
}
if ($script:Skipped.Count -gt 0) {
  Write-Host "   $($script:Skipped.Count) step(s) skipped:" -ForegroundColor Yellow
  $script:Skipped | ForEach-Object { Write-Host "     - $_" -ForegroundColor Yellow }
}
if ($script:Failed.Count -eq 0 -and $script:Skipped.Count -eq 0) {
  Write-Host '   Everything installed. Run: nvim' -ForegroundColor Green
} else {
  Write-Host '   Run `nvim` and then `:checkhealth` to see what is still missing.' -ForegroundColor Cyan
}
Say ''

exit ($(if ($script:Failed.Count -gt 0) { 1 } else { 0 }))
