# Terminal-Dotfiles

Personal Windows development environment dotfiles.

## Quick Install

```powershell
# Install everything (no prompts)
irm https://raw.githubusercontent.com/hartkitsak/Terminal-Dotfiles/master/install.ps1 | iex

# Uninstall everything (no prompts)
irm https://raw.githubusercontent.com/hartkitsak/Terminal-Dotfiles/master/uninstall.ps1 | iex
```

Or clone then run:

```powershell
git clone https://github.com/hartkitsak/Terminal-Dotfiles.git D:\dev-setup\Terminal-Dotfiles
D:\dev-setup\Terminal-Dotfiles\install.ps1
```

## Structure

```
Terminal-Dotfiles/
├── install.ps1                # Installs configs, tools, fonts
├── uninstall.ps1              # Deep clean — removes everything
├── profile/
│   └── Microsoft.PowerShell_profile.ps1   # PSReadLine, zoxide, PSFzf, starship, aliases
└── config/
    ├── starship.toml                     # Starship prompt (minimal)
    └── windows-terminal.settings.json    # Terminal config (CaskaydiaCove NFM, no theme)
```

## Usage

```powershell
# Install everything
.\install.ps1

# Uninstall everything (restores .bak.* backups)
.\uninstall.ps1

# Skip specific phases
.\install.ps1 -SkipConfig -SkipTools
.\uninstall.ps1 -SkipFont -SkipStarship
```

## What install.ps1 does

1. **Config** — Copies config files to their proper locations (PowerShell profile, starship, Windows Terminal)
2. **Tools** — Installs fzf, zoxide, ripgrep via winget
3. **Starship** — Downloads latest starship binary if missing
4. **Font** — Downloads and installs CaskaydiaCove Nerd Font
5. **PATH** — Cleans stale PATH entries

## What uninstall.ps1 does

1. **Config** — Removes config files, restores `.bak.*` backups
2. **Starship** — Removes starship binaries
3. **Font** — Removes CaskaydiaCove NF fonts (system + user + registry)
4. **Tools** — Uninstalls fzf, zoxide, ripgrep via winget
5. **PATH** — Removes related PATH entries
