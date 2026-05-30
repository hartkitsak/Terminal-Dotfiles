param(
    [switch]$Force,
    [switch]$SkipConfig,
    [switch]$SkipStarship,
    [switch]$SkipFont,
    [switch]$SkipTools,
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

# ─── Phase 1: Config files ──────────────────────────────────────────
if (-not $SkipConfig) {
    Write-Host "`n=== Phase 1: Remove config files ===" -ForegroundColor Cyan

    $Configs = @(
        @{ Name = "PowerShell Profile"; Path = $PROFILE }
        @{ Name = "Starship";           Path = Join-Path $env:USERPROFILE ".config\starship.toml" }
        @{ Name = "Windows Terminal";   Path = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" }
    )

    foreach ($c in $Configs) {
        $restored = $false

        if (Test-Path $c.Path) {
            if (-not $Force) {
                $choice = Read-Host "  Remove $($c.Name)? (y/n/a)"
                if ($choice -eq 'a') { $Force = $true }
                elseif ($choice -ne 'y' -and $choice -ne '') {
                    Write-Host "  [SKIP] $($c.Name)" -ForegroundColor Yellow
                    continue
                }
            }
            Remove-Item -Path $c.Path -Force
            Write-Host "  [REMOVED] $($c.Name)" -ForegroundColor Red
        }

        $baseName = Split-Path -Leaf $c.Path
        $destDir  = Split-Path -Parent $c.Path
        $bakFiles = Get-ChildItem -Path $destDir -Filter "$baseName.bak.*" -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending
        $latestBak = $bakFiles | Select-Object -First 1
        if ($latestBak) {
            $origPath = Join-Path $destDir $baseName
            Rename-Item -Path $latestBak.FullName -NewName $baseName -Force
            Write-Host "  [RESTORED] $($latestBak.Name)" -ForegroundColor Green
            $restored = $true
        }

        if ((-not (Test-Path $c.Path)) -and (-not $restored)) {
            Write-Host "  [NONE] $($c.Name)" -ForegroundColor Gray
        }
    }
}

# ─── Phase 2: Starship (files) ──────────────────────────────────────
if (-not $SkipStarship) {
    Write-Host "`n=== Phase 2: Remove starship ===" -ForegroundColor Cyan

    $starshipDirs = @(
        "$env:ProgramFiles\starship",
        "$env:USERPROFILE\.starship"
    )

    foreach ($dir in $starshipDirs) {
        if (Test-Path $dir) {
            if (-not $Force) {
                $choice = Read-Host "  Remove $dir? (y/n/a)"
                if ($choice -eq 'a') { $Force = $true }
                elseif ($choice -ne 'y') {
                    Write-Host "  [SKIP] $dir" -ForegroundColor Yellow
                    continue
                }
            }
            Remove-Item -Path $dir -Recurse -Force
            Write-Host "  [REMOVED] $dir" -ForegroundColor Red
        }
        else {
            Write-Host "  [NONE] $dir" -ForegroundColor Gray
        }
    }
}

# ─── Phase 3: JetBrainsMono Nerd Font ──────────────────────────────
if (-not $SkipFont) {
    Write-Host "`n=== Phase 3: Remove JetBrainsMono NF ===" -ForegroundColor Cyan

    $fontDirs = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Fonts",
        "$env:SystemRoot\Fonts"
    )

    $totalRemoved = 0
    foreach ($dir in $fontDirs) {
        $fonts = Get-ChildItem -Path $dir -Filter "JetBrains*Nerd*" -ErrorAction SilentlyContinue
        foreach ($f in $fonts) {
            if (-not $Force) {
                $choice = Read-Host "  Remove font $($f.Name)? (y/n/a)"
                if ($choice -eq 'a') { $Force = $true }
                elseif ($choice -ne 'y') {
                    Write-Host "  [SKIP] $($f.Name)" -ForegroundColor Yellow
                    continue
                }
            }
            Remove-Item -Path $f.FullName -Force
            $totalRemoved++
        }
    }

    $regFonts = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    $fontKeys = Get-ItemProperty -Path $regFonts -ErrorAction SilentlyContinue |
        Get-Member -MemberType NoteProperty |
        Where-Object { $_.Name -like "*JetBrains*Nerd*" }
    $regCount = 0
    foreach ($key in $fontKeys) {
        Remove-ItemProperty -Path $regFonts -Name $key.Name -Force -ErrorAction SilentlyContinue
        $regCount++
    }
    if ($regCount -gt 0) {
        Write-Host "  [CLEAN] $regCount registry entries removed" -ForegroundColor DarkYellow
    }

    if ($totalRemoved -gt 0) {
        Write-Host "  [REMOVED] $totalRemoved font files" -ForegroundColor Red
    }
    else {
        Write-Host "  [NONE] JetBrainsMono NF fonts" -ForegroundColor Gray
    }
}

# ─── Phase 4: Tools (winget) ────────────────────────────────────────
if (-not $SkipTools) {
    Write-Host "`n=== Phase 4: Uninstall tools ===" -ForegroundColor Cyan

    $WingetTools = @(
        @{ Id = "junegunn.fzf";              Name = "fzf" }
        @{ Id = "ajeetdsouza.zoxide";        Name = "zoxide" }
        @{ Id = "BurntSushi.ripgrep.MSVC";   Name = "ripgrep" }
    )

    foreach ($t in $WingetTools) {
        $toolPath = Get-Command $t.Name -ErrorAction SilentlyContinue
        if (-not $toolPath) {
            Write-Host "  [NONE] $($t.Name)" -ForegroundColor Gray
            continue
        }
        if (-not $Force) {
            $choice = Read-Host "  Uninstall $($t.Name)? (y/n/a)"
            if ($choice -eq 'a') { $Force = $true }
            elseif ($choice -ne 'y') {
                Write-Host "  [SKIP] $($t.Name)" -ForegroundColor Yellow
                continue
            }
        }
        try {
            winget uninstall --id $t.Id --silent | Out-Null
            Write-Host "  [UNINSTALLED] $($t.Name)" -ForegroundColor Red
        }
        catch {
            Write-Host "  [FAIL] $($t.Name): $_" -ForegroundColor Red
        }
    }
}

# ─── Phase 5: Clean PATH ────────────────────────────────────────────
if (-not $SkipCleanup) {
    Write-Host "`n=== Phase 5: Clean PATH ===" -ForegroundColor Cyan

    $envReg = "Registry::HKEY_CURRENT_USER\Environment"
    $currentPath = (Get-ItemProperty -Path $envReg -Name PATH -ErrorAction SilentlyContinue).PATH
    if (-not $currentPath) { $currentPath = "" }

    $stalePatterns = @(
        "junegunn\.fzf.*Microsoft\.Winget\.Source",
        "ajeetdsouza\.zoxide.*Microsoft\.Winget\.Source",
        "starship"
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
        Write-Host "  [OK] Removed PATH entries" -ForegroundColor Green
    }
    else {
        Write-Host "  [CLEAN] PATH clean" -ForegroundColor Green
    }
}

Write-Host "`n[DONE] Uninstall complete" -ForegroundColor Cyan
