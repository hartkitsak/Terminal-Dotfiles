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

## Installation

```powershell
# Install (remote — no clone needed)
irm https://raw.githubusercontent.com/hartkitsak/nova/master/install.ps1 | iex
```

```powershell
# Uninstall (remote)
irm https://raw.githubusercontent.com/hartkitsak/nova/master/uninstall.ps1 | iex
```

```powershell
# Install (local)
git clone https://github.com/hartkitsak/nova.git
.\nova\install.ps1
```

```powershell
# Uninstall (local)
.\nova\uninstall.ps1
```

### install.ps1

`install.ps1` is a 5-phase setup script. Each phase is independent and wrapped in try/catch — one failure won't stop the rest. Use `-SkipTools`, `-SkipStarship`, `-SkipFont`, `-SkipConfig`, or `-SkipCleanup` to skip specific phases.

#### Phase 1 — Tools

Installs CLI tools via winget (silent, no prompts):

| Tool | winget ID |
|------|-----------|
| **fzf** | `junegunn.fzf` |
| **zoxide** | `ajeetdsouza.zoxide` |
| **ripgrep** | `BurntSushi.ripgrep.MSVC` |

Skips if the tool is already on `PATH`.

#### Phase 2 — Starship

Downloads the latest `starship` binary from GitHub Releases to `~/.starship/bin/` and adds it to User PATH. Skips if `starship` is already on `PATH`.

#### Phase 3 — FiraCode Nerd Font

Downloads the latest FiraCode Nerd Font release (18 TTF files) to a temp directory, then copies them to `%LOCALAPPDATA%\Microsoft\Windows\Fonts\`. For each font:

- If the file + registry key already exist → **skips** (`[SAME]`)
- If the file is in use by another process → **skips gracefully** (`[SKIP]`)
- Registers the font per-user via HKCU registry
- Cleans any stale HKLM font entries from previous admin installs
- Broadcasts a `WM_FONTCHANGE` notification so applications pick up new fonts immediately

No admin required — all operations are per-user.

#### Phase 4 — Config

Copies configuration files to their target locations:

| File | Source | Destination |
|------|--------|-------------|
| PowerShell Profile | `profile\Microsoft.PowerShell_profile.ps1` | `$PROFILE` |
| Starship | `config\starship.toml` | `~\.config\starship.toml` |
| Windows Terminal | `config\windows-terminal.settings.json` | Windows Terminal LocalState |

Before overwriting, compares MD5 hashes — if the destination is identical, the file is skipped. Existing files are backed up with a `.bak.<timestamp>` suffix.

#### Phase 5 — Clean PATH

Scans the User PATH for stale winget source entries (from previous uninstall/upgrade cycles of fzf and zoxide) and removes them.

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

### uninstall.ps1

`uninstall.ps1` is a 5-phase teardown script. Use `-SkipConfig`, `-SkipStarship`, `-SkipFont`, `-SkipTools`, or `-SkipCleanup` to skip specific phases. If not running as Administrator, a warning is shown — some operations may be skipped.

#### Phase 1 — Config

Removes the installed config files, then searches for `.bak.<timestamp>` backups and restores the most recent one.

#### Phase 2 — Starship

Deletes the entire `~/.starship/` directory.

#### Phase 3 — FiraCode Nerd Font

Removes all FiraCode Nerd Font registry entries from both HKLM and HKCU, then deletes matching font files from `%LOCALAPPDATA%\Microsoft\Windows\Fonts\`.

#### Phase 4 — Tools

Uninstalls tools via winget:

| Tool | winget ID |
|------|-----------|
| **starship** | `Starship.Starship` |
| **fzf** | `junegunn.fzf` |
| **zoxide** | `ajeetdsouza.zoxide` |
| **ripgrep** | `BurntSushi.ripgrep.MSVC` |

If winget uninstall succeeds but the tool is still listed, it retries with an admin elevation prompt (via `RunAs`).

#### Phase 5 — Clean PATH

Removes stale PATH entries matching `starship`, `fzf`, or `zoxide` winget paths from both User and Machine PATH.

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
