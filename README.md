# Terminal-Dotfiles

Personal Windows development environment dotfiles — Catppuccin Mocha theme, FiraCode Nerd Font Mono, starship prompt, CLI tools.

## Quick Install

```powershell
# Install everything (no prompts, auto-clones from TEMP)
irm https://raw.githubusercontent.com/hartkitsak/Terminal-Dotfiles/master/install.ps1 | iex

# Uninstall everything (no prompts)
irm https://raw.githubusercontent.com/hartkitsak/Terminal-Dotfiles/master/uninstall.ps1 | iex
```

Or clone and run locally:

```powershell
git clone https://github.com/hartkitsak/Terminal-Dotfiles.git
.\install.ps1
```

## Structure

```
Terminal-Dotfiles/
├── install.ps1                  # Installs tools → starship → font → config → path
├── uninstall.ps1                # Removes config → starship → font → tools → path
├── profile/
│   └── Microsoft.PowerShell_profile.ps1   # PSReadLine (Catppuccin Mocha), zoxide, PSFzf, starship
└── config/
    ├── starship.toml                      # Starship prompt (Catppuccin Mocha — blue/mauve/green/peach)
    └── windows-terminal.settings.json     # Terminal config (FiraCode NF Mono 12pt, Catppuccin Mocha scheme)
```

## Usage

```powershell
# Install everything
.\install.ps1

# Skip specific phases
.\install.ps1 -SkipTools -SkipStarship -SkipFont -SkipConfig -SkipCleanup

# Uninstall everything (restores .bak.* backups)
.\uninstall.ps1

# Skip specific uninstall phases
.\uninstall.ps1 -SkipStarship -SkipFont -SkipTools -SkipConfig -SkipCleanup
```

## What install.ps1 does

| # | Phase | Description |
|---|-------|-------------|
| 1 | **Tools** | Installs `fzf`, `zoxide`, `ripgrep` via winget (no prompts) |
| 2 | **Starship** | Downloads latest starship binary to `~/.starship/bin`, adds to User PATH |
| 3 | **FiraCode Nerd Font** | Downloads 18 TTF files, extracts to `%LOCALAPPDATA%\Microsoft\Windows\Fonts`, registers per-user via HKCU registry, broadcasts font change notification |
| 4 | **Config** | Copies PowerShell profile, starship.toml, and Windows Terminal settings.json (backs up existing with `.bak.timestamp`) |
| 5 | **Clean PATH** | Removes stale winget source entries from User PATH |

All phases are wrapped in try/catch — one failure won't abort the script.

## What uninstall.ps1 does

| # | Phase | Description |
|---|-------|-------------|
| 1 | **Config** | Removes config files, restores latest `.bak.*` backup |
| 2 | **Starship** | Removes `~/.starship` directory |
| 3 | **FiraCode Nerd Font** | Removes font registry entries (HKLM + HKCU), deletes font files |
| 4 | **Tools** | Uninstalls fzf, zoxide, ripgrep via winget (auto-retries with admin elevation if needed) |
| 5 | **Clean PATH** | Removes related PATH entries from User and Machine PATH |

## Theme

- **Terminal colors**: Catppuccin Mocha — background `#1e1e2e`, foreground `#cdd6f4`, all 16 ANSI colors
- **Starship prompt**: `directory` (mauve `#cba6f7`), `git_branch` (green `#a6e3a1`), `git_status` (peach `#fab387`), prompt character (blue `#89b4fa`)
- **PSReadLine**: Catppuccin Mocha palette across 17 color keys (command, parameter, operator, string, number, variable, member, keyword, type, comment, etc.)
- **Terminal font**: FiraCode Nerd Font Mono, 12pt
- **All profiles** use Catppuccin Mocha scheme (set in `profiles.defaults`)
