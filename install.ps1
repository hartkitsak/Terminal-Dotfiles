param(
    [switch]$SkipConfig,
    [switch]$SkipTools,
    [switch]$SkipStarship,
    [switch]$SkipFont,
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/hartkitsak/Terminal-Dotfiles.git"
$scriptPath = try { Split-Path -Parent $PSCommandPath -ErrorAction Stop } catch { $null }

# Auto-clone when piped via irm | iex (no local files)
if (-not $scriptPath -or -not (Test-Path (Join-Path $scriptPath "profile\Microsoft.PowerShell_profile.ps1"))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is required. Install it first: winget install Git.Git" }
    $cloneDir = Join-Path $env:TEMP "Terminal-Dotfiles"
    Write-Host "=== Cloning repo to $cloneDir ===" -ForegroundColor Cyan
    if (Test-Path "$cloneDir\.git") { git -C $cloneDir pull } else { git clone $repoUrl $cloneDir }
    & "$cloneDir\install.ps1" @PSBoundParameters
    return
}
$DOTFILES = $scriptPath

$BackupSuffix = ".bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ─── Phase 1: Config ────────────────────────────────────────────────
if (-not $SkipConfig) {
    Write-Host "`n=== Phase 1: Config files ===" -ForegroundColor Cyan

    $Configs = @(
        @{ Name = "PowerShell Profile"; Source = Join-Path $DOTFILES "profile\Microsoft.PowerShell_profile.ps1"; Dest = $PROFILE }
        @{ Name = "Starship";           Source = Join-Path $DOTFILES "config\starship.toml";                         Dest = Join-Path $env:USERPROFILE ".config\starship.toml" }
        @{ Name = "Windows Terminal";   Source = Join-Path $DOTFILES "config\windows-terminal.settings.json";       Dest = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" }
    )

    foreach ($c in $Configs) {
        if (-not (Test-Path $c.Source)) {
            Write-Host "  [SKIP] $($c.Name) source not found" -ForegroundColor Yellow
            continue
        }
        try {
            $destDir = Split-Path -Parent $c.Dest
            if (-not (Test-Path $destDir)) {
                New-Item -ItemType Directory -Path $destDir -Force | Out-Null
            }
            if (Test-Path $c.Dest) {
                $currentHash = (Get-FileHash $c.Dest -Algorithm MD5).Hash
                $sourceHash  = (Get-FileHash $c.Source -Algorithm MD5).Hash
                if ($currentHash -eq $sourceHash) {
                    Write-Host "  [SAME]  $($c.Name)" -ForegroundColor Green
                    continue
                }
                $bakName = "$(Split-Path -Leaf $c.Dest)$BackupSuffix"
                Rename-Item -Path $c.Dest -NewName $bakName -Force
                Write-Host "  [BACKUP] -> $($c.Name)" -ForegroundColor DarkYellow
            }
            Copy-Item -Path $c.Source -Destination $c.Dest -Force
            Write-Host "  [OK] $($c.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  [FAIL] $($c.Name): $_" -ForegroundColor Red
        }
    }
}

# ─── Phase 2: Tools (winget) ────────────────────────────────────────
if (-not $SkipTools) {
    Write-Host "`n=== Phase 2: Tools ===" -ForegroundColor Cyan

    $WingetTools = @(
        @{ Id = "junegunn.fzf";              Name = "fzf" }
        @{ Id = "ajeetdsouza.zoxide";        Name = "zoxide" }
        @{ Id = "BurntSushi.ripgrep.MSVC";   Name = "ripgrep" }
    )

    foreach ($t in $WingetTools) {
        $toolPath = Get-Command $t.Name -ErrorAction SilentlyContinue
        if ($toolPath) {
            Write-Host "  [ALREADY] $($t.Name)" -ForegroundColor Green
            continue
        }
        Write-Host "  [INSTALL] $($t.Name)..." -ForegroundColor Magenta
        try {
            winget install --id $t.Id --silent --accept-package-agreements --accept-source-agreements | Out-Null
            Write-Host "  [OK] $($t.Name)" -ForegroundColor Green
        } catch {
            Write-Host "  [FAIL] $($t.Name): $_" -ForegroundColor Red
        }
    }
}

# ─── Phase 3: Starship (manual) ─────────────────────────────────────
if (-not $SkipStarship) {
    Write-Host "`n=== Phase 3: Starship ===" -ForegroundColor Cyan

    $starshipBin = Get-Command starship -ErrorAction SilentlyContinue
    if ($starshipBin) {
        Write-Host "  [ALREADY] starship ($($starshipBin.Source))" -ForegroundColor Green
    }
    else {
        Write-Host "  [DOWNLOAD] starship..." -ForegroundColor Magenta
        $starshipDir = "$env:USERPROFILE\.starship"
        $binDir = "$starshipDir\bin"
        $zipPath = "$env:TEMP\starship.zip"
        try {
            $latest = Invoke-RestMethod -Uri "https://api.github.com/repos/starship/starship/releases/latest" -Headers @{ "User-Agent" = "powershell" }
            $asset = $latest.assets | Where-Object { $_.name -like "*x86_64-pc-windows-msvc*" -and $_.name -like "*.zip" } | Select-Object -First 1
            if (-not $asset) { throw "No .zip asset found for x86_64" }
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath
            New-Item -ItemType Directory -Path $binDir -Force | Out-Null
            Expand-Archive -Path $zipPath -DestinationPath $binDir -Force
            Remove-Item $zipPath -Force
            Write-Host "  [OK] starship -> $binDir" -ForegroundColor Green
            $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
            if ($userPath -notlike "*$binDir*") {
                [Environment]::SetEnvironmentVariable("PATH", "$userPath;$binDir", "User")
                $env:PATH = "$env:PATH;$binDir"
                Write-Host "  [PATH] Added $binDir to PATH" -ForegroundColor Green
            }
        } catch {
            Write-Host "  [FAIL] starship download: $_" -ForegroundColor Red
        }
    }
}

# ─── Phase 4: CaskaydiaCove Nerd Font ──────────────────────────────
if (-not $SkipFont) {
    Write-Host "`n=== Phase 4: CaskaydiaCove Nerd Font ===" -ForegroundColor Cyan

    $fontTarget = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $installedFonts = Get-ChildItem -Path $fontTarget -Filter "CaskaydiaCoveNerdFont*" -ErrorAction SilentlyContinue

    if ($installedFonts.Count -gt 0) {
        Write-Host "  [ALREADY] CaskaydiaCove NF ($($installedFonts.Count) files)" -ForegroundColor Green
    }
    else {
        Write-Host "  [DOWNLOAD] CaskaydiaCove Nerd Font..." -ForegroundColor Magenta
        $zipPath = "$env:TEMP\CascadiaCode.zip"
        $extractPath = "$env:TEMP\CascadiaCodeNF"
        try {
            Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip" -OutFile $zipPath
            New-Item -ItemType Directory -Path $extractPath -Force | Out-Null
            Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force
            New-Item -ItemType Directory -Path $fontTarget -Force | Out-Null
            $ttfs = Get-ChildItem -Path $extractPath -Filter "*.ttf"
            $fontCount = 0
            foreach ($f in $ttfs) {
                $dest = Join-Path $fontTarget $f.Name
                Copy-Item -Path $f.FullName -Destination $dest -Force
                $regFonts = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
                $regName = "$($f.BaseName) (TrueType)"
                Set-ItemProperty -Path $regFonts -Name $regName -Value $f.Name -Force
                $fontCount++
            }
            Remove-Item $zipPath -Force
            Remove-Item $extractPath -Recurse -Force
            Write-Host "  [OK] $fontCount font files installed" -ForegroundColor Green
        } catch {
            Write-Host "  [FAIL] CaskaydiaCove NF download: $_" -ForegroundColor Red
        }
    }
}

# ─── Phase 5: Clean stale PATH entries ──────────────────────────────
if (-not $SkipCleanup) {
    Write-Host "`n=== Phase 5: Clean PATH ===" -ForegroundColor Cyan

    try {
        $envReg = "Registry::HKEY_CURRENT_USER\Environment"
        $currentPath = (Get-ItemProperty -Path $envReg -Name PATH -ErrorAction SilentlyContinue).PATH
        if (-not $currentPath) { $currentPath = "" }

        $stalePatterns = @(
            "junegunn\.fzf.*Microsoft\.Winget\.Source",
            "ajeetdsouza\.zoxide.*Microsoft\.Winget\.Source"
        )

        $newPathParts = $currentPath -split ';' | Where-Object {
            $keep = $true
            foreach ($pattern in $stalePatterns) {
                if ($_ -match $pattern) { $keep = $false; break }
            }
            $keep
        }
        $newPath = $newPathParts -join ';'

        if ($newPath -ne $currentPath) {
            Set-ItemProperty -Path $envReg -Name PATH -Value $newPath
            Write-Host "  [OK] Removed stale PATH entries" -ForegroundColor Green
        } else {
            Write-Host "  [CLEAN] No stale PATH entries found" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [FAIL] PATH cleanup: $_" -ForegroundColor Red
    }
}

Write-Host "`n[DONE] Restart your terminal or run: . `$PROFILE" -ForegroundColor Cyan
