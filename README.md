# Terminal-Dotfiles

Personal Windows development environment dotfiles.

## Quick Install

```powershell
irm https://raw.githubusercontent.com/hartkitsak/Terminal-Dotfiles/master/go.ps1 | iex
```

Or clone then install:

```powershell
git clone https://github.com/hartkitsak/Terminal-Dotfiles.git D:\dev-setup\Terminal-Dotfiles
.\D:\dev-setup\Terminal-Dotfiles\install.ps1
```

## Files

| File | Description |
|------|-------------|
| `go.ps1` | Bootstrap — clones repo and runs install |
| `install.ps1` | Installs configs, tools, fonts |
| `uninstall.ps1` | Deep clean — removes everything |
| `Microsoft.PowerShell_profile.ps1` | PowerShell profile with PSReadLine, zoxide, PSFzf, fzf, starship, aliases |
| `starship.toml` | Starship prompt config (minimal, Tokyo Night theme) |
| `windows-terminal.settings.json` | Windows Terminal settings (Tokyo Night Storm, JetBrainsMono NF) |

## Usage

```powershell
# Install everything
.\install.ps1

# Uninstall everything
.\uninstall.ps1

# Skip confirmation prompts
.\install.ps1 -Force
.\uninstall.ps1 -Force

# Skip specific phases
.\install.ps1 -SkipConfig -SkipTools
.\uninstall.ps1 -SkipFont -SkipStarship
```

## What install.ps1 does

1. **Config** — Copies config files to their proper locations (PowerShell profile, starship, Windows Terminal)
2. **Tools** — Installs fzf, zoxide, ripgrep via winget
3. **Starship** — Downloads latest starship binary if missing
4. **Font** — Downloads and installs JetBrainsMono Nerd Font
5. **PATH** — Cleans stale PATH entries

## What uninstall.ps1 does

1. **Config** — Removes config files, restores `.bak.*` backups
2. **Starship** — Removes starship binaries
3. **Font** — Removes JetBrainsMono NF fonts (system + user + registry)
4. **Tools** — Uninstalls fzf, zoxide, ripgrep via winget
5. **PATH** — Removes related PATH entries
