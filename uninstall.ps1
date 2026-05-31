param(
    [switch]$SkipConfig,
    [switch]$SkipStarship,
    [switch]$SkipFont,
    [switch]$SkipTools,
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/hartkitsak/Terminal-Dotfiles.git"
$scriptPath = try { Split-Path -Parent $PSCommandPath -ErrorAction Stop } catch { $null }

# Auto-clone when piped via irm | iex (must be before admin check — $PSCommandPath is null)
if (-not $scriptPath -or -not (Test-Path (Join-Path $scriptPath "profile\Microsoft.PowerShell_profile.ps1"))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is required. Install it first: winget install Git.Git" }
    $cloneDir = Join-Path $env:TEMP "Terminal-Dotfiles"
    Write-Host "=== Cloning repo to $cloneDir ===" -ForegroundColor Cyan
    if (Test-Path "$cloneDir\.git") { git -C $cloneDir pull } else { git clone $repoUrl $cloneDir }
    & "$cloneDir\uninstall.ps1" @PSBoundParameters
    return
}

# Admin check (winget uninstall needs admin)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "  [WARN] Not running as Administrator. Some operations may fail." -ForegroundColor Yellow
}

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
        try {
            if (Test-Path $c.Path) {
                Remove-Item -Path $c.Path -Force
                Write-Host "  [REMOVED] $($c.Name)" -ForegroundColor Red
            }
        } catch {
            Write-Host "  [WARN] Could not remove $($c.Name): $_" -ForegroundColor Yellow
        }

        try {
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
        } catch {
            Write-Host "  [WARN] Could not restore backup for $($c.Name): $_" -ForegroundColor Yellow
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
        "$env:USERPROFILE\.starship"
    )

    foreach ($dir in $starshipDirs) {
        if (Test-Path $dir) {
            try {
                Remove-Item -Path $dir -Recurse -Force
                Write-Host "  [REMOVED] $dir" -ForegroundColor Red
            } catch {
                Write-Host "  [WARN] Could not remove $($dir): $_" -ForegroundColor Yellow
            }
        } else {
            Write-Host "  [NONE] $dir" -ForegroundColor Gray
        }
    }
}

# ─── Phase 3: CaskaydiaCove Nerd Font ──────────────────────────────
if (-not $SkipFont) {
    Write-Host "`n=== Phase 3: Remove CaskaydiaCove NF ===" -ForegroundColor Cyan

    $fontDirs = @(
        "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    )

    $totalRemoved = 0
    foreach ($dir in $fontDirs) {
        try {
            $fonts = Get-ChildItem -Path $dir -Filter "CaskaydiaCove*Nerd*" -ErrorAction SilentlyContinue
            foreach ($f in $fonts) {
                Remove-Item -Path $f.FullName -Force
                $totalRemoved++
            }
        } catch {
            Write-Host "  [WARN] Error removing fonts from $($dir): $_" -ForegroundColor Yellow
        }
    }

    try {
        $regFonts = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
        $fontKeys = Get-ItemProperty -Path $regFonts -ErrorAction SilentlyContinue |
            Get-Member -MemberType NoteProperty |
            Where-Object { $_.Name -like "CaskaydiaCove NF*" }
        $regCount = 0
        foreach ($key in $fontKeys) {
            Remove-ItemProperty -Path $regFonts -Name $key.Name -Force -ErrorAction SilentlyContinue
            $regCount++
        }
        if ($regCount -gt 0) {
            Write-Host "  [CLEAN] $regCount registry entries removed" -ForegroundColor DarkYellow
        }
    } catch {
        Write-Host "  [WARN] Could not clean font registry: $_" -ForegroundColor Yellow
    }

    if ($totalRemoved -gt 0) {
        Write-Host "  [REMOVED] $totalRemoved font files" -ForegroundColor Red
    } else {
        Write-Host "  [NONE] CaskaydiaCove NF fonts" -ForegroundColor Gray
    }
}

# ─── Phase 4: Tools (winget) ────────────────────────────────────────
if (-not $SkipTools) {
    Write-Host "`n=== Phase 4: Uninstall tools ===" -ForegroundColor Cyan

    $WingetTools = @(
        @{ Id = "Starship.Starship";         Name = "starship" }
        @{ Id = "junegunn.fzf";              Name = "fzf" }
        @{ Id = "ajeetdsouza.zoxide";        Name = "zoxide" }
        @{ Id = "BurntSushi.ripgrep.MSVC";   Name = "ripgrep" }
    )

    foreach ($t in $WingetTools) {
        # Check both Get-Command and winget list (winget may not add to PATH immediately)
        $toolPath = Get-Command $t.Name -ErrorAction SilentlyContinue
        $inWinget = winget list --id $t.Id --accept-source-agreements 2>$null | Select-String -Pattern $t.Id -Quiet
        if (-not $toolPath -and -not $inWinget) {
            Write-Host "  [NONE] $($t.Name)" -ForegroundColor Gray
            continue
        }
        try {
            winget uninstall --id $t.Id --silent --accept-source-agreements 2>&1 | Out-Null
            Start-Sleep -Seconds 2
            $stillInWinget = winget list --id $t.Id --accept-source-agreements 2>$null | Select-String -Pattern $t.Id -Quiet
            if ($stillInWinget) {
                Write-Host "  [RETRY] $($t.Name) still in winget, elevating to admin..." -ForegroundColor Yellow
                $psi = New-Object System.Diagnostics.ProcessStartInfo
                $psi.FileName = "winget"
                $psi.Arguments = "uninstall --id $($t.Id) --silent --accept-source-agreements"
                $psi.Verb = "RunAs"
                $psi.UseShellExecute = $true
                $p = [System.Diagnostics.Process]::Start($psi)
                if ($p) { $p.WaitForExit() }
                Start-Sleep -Seconds 2
            }
            Write-Host "  [UNINSTALLED] $($t.Name)" -ForegroundColor Red
        } catch {
            Write-Host "  [FAIL] $($t.Name): $_" -ForegroundColor Red
        }
    }
}

# ─── Phase 5: Clean PATH ────────────────────────────────────────────
if (-not $SkipCleanup) {
    Write-Host "`n=== Phase 5: Clean PATH ===" -ForegroundColor Cyan

    $stalePatterns = @(
        "junegunn\.fzf.*Microsoft\.Winget\.Source",
        "ajeetdsouza\.zoxide.*Microsoft\.Winget\.Source",
        "starship"
    )

    # Clean User PATH
    try {
        $envReg = "Registry::HKEY_CURRENT_USER\Environment"
        $currentPath = (Get-ItemProperty -Path $envReg -Name PATH -ErrorAction SilentlyContinue).PATH
        if (-not $currentPath) { $currentPath = "" }

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
            $env:PATH = $newPath
            Write-Host "  [OK] Cleaned User PATH" -ForegroundColor Green
        } else {
            Write-Host "  [CLEAN] User PATH clean" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [FAIL] User PATH cleanup: $_" -ForegroundColor Red
    }

    # Clean Machine PATH
    try {
        $machineReg = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
        $currentMachinePath = (Get-ItemProperty -Path $machineReg -Name PATH -ErrorAction SilentlyContinue).PATH
        if (-not $currentMachinePath) { $currentMachinePath = "" }

        $newMachineParts = $currentMachinePath -split ';' | Where-Object {
            $keep = $true
            foreach ($pattern in $stalePatterns) {
                if ($_ -match $pattern) { $keep = $false; break }
            }
            $keep
        }
        $newMachinePath = $newMachineParts -join ';'

        if ($newMachinePath -ne $currentMachinePath) {
            Set-ItemProperty -Path $machineReg -Name PATH -Value $newMachinePath
            Write-Host "  [OK] Cleaned Machine PATH" -ForegroundColor Green
        } else {
            Write-Host "  [CLEAN] Machine PATH clean" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [FAIL] Machine PATH cleanup: $_" -ForegroundColor Red
    }
}

Write-Host "`n[DONE] Uninstall complete" -ForegroundColor Cyan
