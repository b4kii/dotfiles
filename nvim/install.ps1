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

.PARAMETER SkipMsvc
  Never offer to install Visual Studio Build Tools. Treesitter parsers cannot
  be compiled without them; the rest of the config is unaffected.

.PARAMETER Force
  Answer yes to every prompt: replace an existing config (the old one is still
  backed up) and install Build Tools without asking.

.EXAMPLE
  .\install.ps1
  .\install.ps1 -SkipTools
#>
[CmdletBinding()]
param(
  [switch]$SkipTools,
  [switch]$SkipPlugins,
  [switch]$SkipMsvc,
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

# Native commands do NOT throw on failure -- they set $LASTEXITCODE. Wrapping
# `scoop install` in try/catch therefore reports success for every failed
# install, which is how a missing compiler can slip through a run that looked
# completely green.
function Invoke-Tool {
  param([string]$Exe, [string[]]$Arguments)
  $global:LASTEXITCODE = 0
  & $Exe @Arguments *>&1 | Out-Null
  return ($LASTEXITCODE -eq 0)
}

# scoop and npm add their shim directories to the PATH stored in the registry,
# but the PATH of an already-running process is a copy made at launch. Without
# re-reading it, everything installed above stays invisible for the rest of
# this script -- and to the headless Neovim at the end, which inherits it.
#
# ADDITIVE on purpose. Replacing $env:PATH with the registry value drops every
# entry that only exists in this session -- an nvm shim, a venv, a directory
# someone exported by hand -- and takes tools that worked a second ago with it.
function Sync-Path {
  $seen = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]($env:PATH -split ';' | Where-Object { $_ }),
    [StringComparer]::OrdinalIgnoreCase)
  $extra = @()
  $candidates = @()
  foreach ($scope in 'Machine', 'User') {
    $p = [Environment]::GetEnvironmentVariable('Path', $scope)
    if ($p) { $candidates += ($p -split ';') }
  }
  $candidates += if ($env:SCOOP) { Join-Path $env:SCOOP 'shims' }
                 else { Join-Path $env:USERPROFILE 'scoop\shims' }
  foreach ($d in $candidates) {
    if ($d -and $seen.Add($d)) { $extra += $d }
  }
  if ($extra) { $env:PATH = (@($env:PATH) + $extra) -join ';' }
  # Get-Command caches lookups; drop the cache so Have() sees the new binaries.
  Get-Command -Name '*' -CommandType Application -ErrorAction SilentlyContinue | Out-Null
}

# The tree-sitter CLI compiles parsers with MSVC `cl.exe` and nothing else on
# Windows: its `cc` backend resolves that compiler through vswhere and the
# registry, NOT through PATH. Two consequences that are easy to get wrong:
#
#   * `cl` is normally absent from PATH even on a machine where every parser
#     builds fine -- putting it there is what vcvarsall.bat is for, and the
#     build does not need it.
#   * a MinGW gcc in PATH is never consulted. Probing for one is what used to
#     make this script report a healthy toolchain right before nvim-treesitter
#     died on every parser with
#       "Failed to execute the C compiler ... Error: program not found"
#     naming cl.exe. Forcing it with CC=gcc does switch compilers, and then
#     MinGW's ld rejects the \\?\-prefixed output path the CLI hands it
#     ("cannot open output file ... Invalid argument"). So gcc is not an
#     answer here at all; Build Tools are.
function Find-Msvc {
  if ($env:CC) { return "CC=$env:CC" }   # an explicit CC wins inside the CLI
  $pf = ${env:ProgramFiles(x86)}
  if ($pf) {
    $vswhere = Join-Path $pf 'Microsoft Visual Studio\Installer\vswhere.exe'
    if (Test-Path $vswhere) {
      # -requires, not a bare -latest: Build Tools can be installed with no C++
      # workload at all, and that install has no cl.exe in it.
      $found = & $vswhere -products * -latest `
        -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
        -property installationPath 2>$null
      if ($found) { return "MSVC at $found" }
    }
  }
  if (Have 'cl') { return 'cl.exe (in PATH)' }
  return $null
}

# ---------------------------------------------------------------------------
Step 'Prerequisites'

# Before the first probe, not just before the installs. A tool installed by an
# earlier run of this script -- or by hand in another window -- is on the
# registry PATH but not on this shell's, so without it the checks below report
# things as missing that are sitting right there. That is how a run could end
# with "No C compiler found" printed underneath a successful `scoop install`.
Sync-Path

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

# Checked up front because the failure mode is otherwise baffling: the
# tree-sitter CLI installs fine, then every parser build dies with
#   "Failed to execute the C compiler ... Error: program not found"
# See Find-Msvc for why only MSVC counts on Windows.
$msvc = Find-Msvc
if ($msvc) {
  Ok "C compiler: $msvc"
} else {
  Info 'no MSVC toolchain yet -- the Build Tools step below offers to install it'
}

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
    #
    # Exactly ONE backup is kept. A timestamped name per run just piles up
    # directories nobody ever looks at, so the previous backup is replaced.
    $backup = "$target.bak"
    $hadBackup = Test-Path $backup

    if (-not $Force) {
      Say "   A config already exists at $target"
      Say "   It will be moved to $backup"
      if ($hadBackup) { Say "   The previous backup at $backup will be REPLACED" }
      $answer = Read-Host '   Continue? [y/N]'
      if ($answer -notmatch '^(y|yes)$') { Say 'Aborted.'; exit 1 }
    }

    if ($hadBackup) {
      Remove-Item -LiteralPath $backup -Recurse -Force -ErrorAction SilentlyContinue
      # Report rather than letting Move-Item fail with a confusing message.
      if (Test-Path $backup) {
        Fail "could not remove the old backup at $backup -- move it away and re-run"
        exit 1
      }
    }

    Move-Item -LiteralPath $target -Destination $backup
    Ok $(if ($hadBackup) { "existing config backed up to $backup (previous backup replaced)" }
         else { "existing config backed up to $backup" })
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
    Warn '  ripgrep fd tree-sitter lua-language-server nodejs python'
  } else {
    # tree-sitter CLI + a C compiler are what let nvim-treesitter build parsers;
    # without them highlighting falls back to the handful bundled with Neovim.
    #
    # `gcc` is deliberately absent: the CLI never calls it on Windows (see
    # Find-Msvc), so installing it bought nothing here except the false
    # impression that the toolchain was ready. The compiler comes from the
    # Build Tools step below instead.
    $scoopPkgs = @(
      @{ name = 'ripgrep';             probe = 'rg';                  why = '<leader>fg live grep' },
      @{ name = 'fd';                  probe = 'fd';                  why = 'faster <leader>ff' },
      @{ name = 'tree-sitter';         probe = 'tree-sitter';         why = 'building treesitter parsers' },
      @{ name = 'lua-language-server'; probe = 'lua-language-server'; why = 'Lua LSP' },
      @{ name = 'nodejs';              probe = 'node';                why = 'most language servers' },
      @{ name = 'python';              probe = 'python';              why = 'Python LSP' }
    )
    foreach ($p in $scoopPkgs) {
      if (Have $p.probe) {
        Ok "$($p.probe) -- already installed"
      } else {
        Info "installing $($p.name) ($($p.why))"
        if (Invoke-Tool 'scoop' @('install', $p.name)) {
          Sync-Path
          if (Have $p.probe) {
            Ok "$($p.name)"
          } else {
            # Installed, but its shim is not reachable. Usually means scoop put
            # it somewhere this shell cannot see -- a new terminal will fix it.
            Warn "$($p.name) installed but '$($p.probe)' is still not on PATH -- open a new terminal"
          }
        } else {
          Fail "scoop install $($p.name) failed (exit $LASTEXITCODE)"
        }
      }
    }
  }

  # Everything installed above lands on the registry PATH, not this process's.
  # Refresh once more before the npm/pip sections so they see a fresh node.
  Sync-Path

  Step 'C toolchain for treesitter (Visual Studio Build Tools)'

  if ($msvc) {
    Ok "$msvc -- already installed"
  } elseif ($SkipMsvc) {
    Warn 'Build Tools skipped by -SkipMsvc -- treesitter parsers will not build'
  } elseif (-not (Have 'winget')) {
    Warn 'winget not found -- install Visual Studio Build Tools yourself (C++ workload)'
  } else {
    # The only step here that asks. Everything else is a scoop package measured
    # in tens of megabytes that needs no elevation; this is a multi-gigabyte
    # download and a UAC prompt, which is not something to spring on someone who
    # just wanted an editor config.
    Say '   nvim-treesitter compiles parsers with MSVC, and only MSVC -- a gcc'
    Say '   in PATH is ignored by the tree-sitter CLI. Build Tools is a few GB'
    Say '   and needs admin rights. Skip it and everything except parser'
    Say '   compilation still works (Neovim ships a handful of parsers).'
    $go = $Force
    if (-not $go) {
      $answer = Read-Host '   Install Visual Studio Build Tools now? [y/N]'
      $go = $answer -match '^(y|yes)$'
    }

    if (-not $go) {
      Warn 'Build Tools not installed -- treesitter parsers will be skipped'
    } else {
      # --override replaces the installer arguments wholesale, so the workload
      # has to be named here: a bare Build Tools install contains no C++ tools
      # and no cl.exe, which vswhere would then correctly refuse to report.
      Info 'winget install Microsoft.VisualStudio.BuildTools -- several GB, takes a while'
      $ok = Invoke-Tool 'winget' @(
        'install', '--id', 'Microsoft.VisualStudio.BuildTools', '-e',
        '--accept-package-agreements', '--accept-source-agreements',
        '--override', ('--quiet --wait --norestart --nocache ' +
          '--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended')
      )
      # winget exits 0 for "installed, reboot pending" too, so believe vswhere
      # over the exit code -- it is the same lookup the compiler itself does.
      $msvc = Find-Msvc
      if ($msvc) {
        Ok $msvc
      } elseif ($ok) {
        Warn 'winget reported success but no C++ tools are visible -- reboot and re-run: .\install.ps1 -SkipTools'
      } else {
        Fail "winget install Build Tools failed (exit $LASTEXITCODE)"
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
        if (Invoke-Tool 'npm' @('install', '-g', $p.spec)) {
          Sync-Path
          if (Have $p.probe) { Ok "$($p.spec)" }
          else { Warn "$($p.spec) installed but '$($p.probe)' is not on PATH -- open a new terminal" }
        } else {
          Fail "npm i -g $($p.spec) failed (exit $LASTEXITCODE)"
        }
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
        if (Invoke-Tool 'pip' @('install', '--quiet', $p.spec)) {
          Sync-Path
          if (Have $p.probe) { Ok "$($p.spec)" }
          else { Warn "$($p.spec) installed but '$($p.probe)' is not on PATH -- open a new terminal" }
        } else {
          Fail "pip install $($p.spec) failed (exit $LASTEXITCODE)"
        }
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

  # Re-check here, not just at the top: the Build Tools step may have installed
  # a compiler since. Said before starting Neovim rather than after, because the
  # alternative is a screen of red -- one "program not found" per parser.
  Sync-Path
  $ccNow = Find-Msvc
  if ($ccNow) {
    Ok "parsers will build with: $ccNow"
  } else {
    Warn 'no MSVC toolchain -- treesitter parsers will be skipped'
    Warn '  re-run this script and accept the Build Tools step, or install it by hand:'
    Warn '  winget install --id Microsoft.VisualStudio.BuildTools -e --override "--quiet --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"'
  }

  Info 'starting Neovim headless -- first run clones 19 plugins and builds parsers'
  if (Invoke-Tool 'nvim' @('--headless', '-c', 'qa!')) {
    Ok 'plugins installed'
  } else {
    # Neovim exits non-zero on a config error, which is worth surfacing.
    Fail "headless start returned exit $LASTEXITCODE -- run nvim and read the message"
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
