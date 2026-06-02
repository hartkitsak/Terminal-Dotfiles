<div align="center">

# ⚡ nova

**Windows dev environment · PowerShell profile · CLI toolkit**

[![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)]()
[![Windows Terminal](https://img.shields.io/badge/Windows%20Terminal-4D4D4D?style=flat&logo=windowsterminal&logoColor=white)]()

</div>

## Features

- **PowerShell profile** — PSReadLine prediction (history + list), zoxide, PSFzf (Ctrl+t / Ctrl+r), custom functions (`ff`, `cdf`, `take`, `..`, `...`) and aliases (`ll`, `gs`, `gco`, `gcmsg`, `v`)
- **Starship prompt** — minimal, fast, single-line format
- **Windows Terminal** — FiraCode Nerd Font Mono 12pt, 90% opacity, acrylic
- **FiraCode Nerd Font** — auto-installed per-user (no admin required)
- **One-command setup** — `irm` + `iex` or clone & run

## Quick Start

```powershell
# Remote — no clone needed
irm https://raw.githubusercontent.com/hartkitsak/nova/master/install.ps1 | iex

# Uninstall
irm https://raw.githubusercontent.com/hartkitsak/nova/master/uninstall.ps1 | iex
```

```powershell
# Local
git clone https://github.com/hartkitsak/nova.git
.\nova\install.ps1
```

## Structure

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

## What install.ps1 does

| # | Phase | Description |
|---|-------|-------------|
| 1 | **Tools** | Installs `fzf`, `zoxide`, `ripgrep` via winget (no prompts) |
| 2 | **Starship** | Downloads latest starship binary to `~/.starship/bin`, adds to User PATH |
| 3 | **FiraCode Nerd Font** | Downloads 18 TTF files, extracts to `%LOCALAPPDATA%\Microsoft\Windows\Fonts`, registers per-user via HKCU, cleans stale HKLM entries, broadcasts font change notification |
| 4 | **Config** | Copies PowerShell profile, starship.toml, and Windows Terminal settings.json (skips if MD5 matches, backs up existing as `.bak.<timestamp>`) |
| 5 | **Clean PATH** | Removes stale winget source entries from User PATH |

All phases are wrapped in try/catch — one failure won't abort the script.

## What uninstall.ps1 does

| # | Phase | Description |
|---|-------|-------------|
| 1 | **Config** | Removes config files, restores latest `.bak.*` backup |
| 2 | **Starship** | Removes `~/.starship` directory |
| 3 | **FiraCode Nerd Font** | Removes font registry entries (HKLM + HKCU), deletes font files |
| 4 | **Tools** | Uninstalls starship, fzf, zoxide, ripgrep via winget (auto-retries with admin elevation if needed) |
| 5 | **Clean PATH** | Cleans related PATH entries from both User and Machine PATH |

Skips phases that would fail without admin — warns instead of blocking.

## Aliases & Functions

| Alias | Maps to |
|-------|---------|
| `ll` | `Get-ChildItem` |
| `gs` | `git` |
| `gco` | `git checkout` |
| `gcmsg` | `git commit -m` |
| `v` | `nvim` |

| Function | Description |
|----------|-------------|
| `ff` | Fuzzy find files via ripgrep + fzf |
| `cdf` | Fuzzy `cd` into subdirectories |
| `..` | Go up one directory |
| `...` | Go up two directories |
| `take <dir>` | Create and `cd` into a directory |
