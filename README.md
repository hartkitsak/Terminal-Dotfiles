<div align="center">

# ⚡ nova

**Windows dev environment · PowerShell profile · CLI toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)]()
[![Windows Terminal](https://img.shields.io/badge/Windows%20Terminal-4D4D4D?style=flat&logo=windowsterminal&logoColor=white)]()

</div>

---

## Overview

One-command setup that installs and configures a modern Windows dev environment: PowerShell profile with zoxide + PSFzf, Starship prompt, FiraCode Nerd Font, Windows Terminal settings, and CLI tools (fzf, zoxide, ripgrep). No admin required for most operations.

## Installation

### Remote

```powershell
irm https://raw.githubusercontent.com/hartkitsak/nova/master/install.ps1 | iex
```

### Local

```powershell
git clone https://github.com/hartkitsak/nova.git
.\nova\install.ps1
```

> **Uninstall:** `irm .../uninstall.ps1 \| iex` (remote) or `.\nova\uninstall.ps1` (local)

## What's Included

| Component | Description |
|-----------|-------------|
| **PowerShell Profile** | PSReadLine prediction, zoxide, PSFzf (Ctrl+t / Ctrl+r), custom functions + aliases |
| **Starship Prompt** | Minimal single-line prompt |
| **Windows Terminal** | FiraCode Nerd Font Mono 12pt, 90% opacity, acrylic |
| **FiraCode Nerd Font** | 18 TTF files, per-user install via HKCU, no admin required |
| **CLI Tools** | fzf, zoxide, ripgrep (installed via winget) |

## install.ps1

5 independent phases, wrapped in try/catch. Use `-SkipTools`, `-SkipStarship`, `-SkipFont`, `-SkipConfig`, or `-SkipCleanup` to skip specific phases.

| # | Phase | Description |
|---|-------|-------------|
| 1 | **Tools** | winget install fzf, zoxide, ripgrep (silent, skips if on PATH) |
| 2 | **Starship** | Download latest binary → `~/.starship/bin` → add to User PATH |
| 3 | **FiraCode Nerd Font** | Download release → extract 18 TTF → copy to LocalState → register HKCU → clean stale HKLM → broadcast font change |
| 4 | **Config** | Copy profile, starship.toml, terminal settings (MD5 skip if identical, backs up as `.bak.<timestamp>`) |
| 5 | **Clean PATH** | Remove stale winget source entries from User PATH |

## uninstall.ps1

5 phases, admin-aware (warns instead of blocking). Use `-SkipConfig`, `-SkipStarship`, `-SkipFont`, `-SkipTools`, or `-SkipCleanup`.

| # | Phase | Description |
|---|-------|-------------|
| 1 | **Config** | Remove installed files → restore latest `.bak.*` backup |
| 2 | **Starship** | Delete `~/.starship/` directory |
| 3 | **FiraCode Nerd Font** | Remove registry entries (HKLM + HKCU) → delete font files |
| 4 | **Tools** | winget uninstall fzf, zoxide, ripgrep, starship (auto-retry with admin elevation if needed) |
| 5 | **Clean PATH** | Clean User + Machine PATH of stale entries |

## Aliases

| Alias | Maps to |
|-------|---------|
| `ll` | `Get-ChildItem` |
| `gs` | `git` |
| `gco` | `git checkout` |
| `gcmsg` | `git commit -m` |
| `v` | `nvim` |

## Functions

| Function | Description |
|----------|-------------|
| `ff` | Fuzzy find files via ripgrep + fzf |
| `cdf` | Fuzzy `cd` into subdirectories |
| `..` | Go up one directory |
| `...` | Go up two directories |
| `take <dir>` | Create and `cd` into a directory |

## Project Structure

```
nova/
├── install.ps1                     # 5-phase setup
├── uninstall.ps1                   # 5-phase teardown
├── profile/
│   └── Microsoft.PowerShell_profile.ps1
├── config/
│   ├── starship.toml
│   └── windows-terminal.settings.json
└── .gitignore
```
