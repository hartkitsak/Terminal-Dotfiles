param(
    [switch]$SkipConfig,
    [switch]$SkipStarship,
    [switch]$SkipFont,
    [switch]$SkipTools,
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/hartkitsak/nova.git"
$scriptPath = try { Split-Path -Parent $PSCommandPath -ErrorAction Stop } catch { $null }

# Auto-clone when piped via irm | iex (must be before admin check — $PSCommandPath is null)
if (-not $scriptPath -or -not (Test-Path (Join-Path $scriptPath "profile\Microsoft.PowerShell_profile.ps1"))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is required. Install it first: winget install Git.Git" }
    $cloneDir = Join-Path $env:TEMP "nova"
    Write-Host "=== Cloning repo to $cloneDir ===" -ForegroundColor Cyan
    if (Test-Path "$cloneDir\.git") { git -C $cloneDir pull } else { git clone $repoUrl $cloneDir }
    & "$cloneDir\uninstall.ps1" @PSBoundParameters
    return
}

# Self-elevate to admin (winget uninstall / PATH / fonts need admin)
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "pwsh.exe"
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
        if ($kv.Value -is [switch] -and $kv.Value) { $argList += " -$($kv.Key)" }
    }
    $psi.Arguments = $argList
    $psi.Verb = "RunAs"
    $psi.UseShellExecute = $true
    $null = [System.Diagnostics.Process]::Start($psi)
    exit
}

# ─── Phase 1: Config files ──────────────────────────────────────────
if (-not $SkipConfig) {
    Write-Host "`n[1/5] Config files" -ForegroundColor Cyan

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
    Write-Host "`n[2/5] Starship" -ForegroundColor Cyan

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

# ─── Phase 3: FiraCode Nerd Font ────────────────────────────────────
if (-not $SkipFont) {
    Write-Host "`n[3/5] FiraCode Nerd Font" -ForegroundColor Cyan

    $FontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $RegPaths = @(
        "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
        "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    )

    # Remove registry entries from both HKLM and HKCU
    $count = 0
    foreach ($FontReg in $RegPaths) {
        try {
            $fontKeys = Get-ItemProperty -Path $FontReg -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match "^FiraCode" }
            foreach ($k in $fontKeys) {
                Remove-ItemProperty -Path $FontReg -Name $k.Name -Force -ErrorAction SilentlyContinue
                $count++
            }
        } catch {}
    }
    if ($count -gt 0) {
        Write-Host "  [OK] Removed $count font registry entries" -ForegroundColor Red
    } else {
        Write-Host "  [NONE] No FiraCode font registry entries" -ForegroundColor Gray
    }

    # Remove font files
    try {
        $fontFiles = Get-ChildItem -Path $FontDir -Filter "FiraCode*Nerd*" -ErrorAction SilentlyContinue
        $delCount = 0
        foreach ($f in $fontFiles) {
            Remove-Item -Path $f.FullName -Force -ErrorAction SilentlyContinue
            $delCount++
        }
        if ($delCount -gt 0) {
            Write-Host "  [OK] Removed $delCount font files" -ForegroundColor Red
        } else {
            Write-Host "  [NONE] No FiraCode font files found" -ForegroundColor Gray
        }
    } catch {
        Write-Host "  [WARN] Font file cleanup: $_" -ForegroundColor Yellow
    }
}

# ─── Phase 4: Tools (winget) ────────────────────────────────────────
if (-not $SkipTools) {
    Write-Host "`n[4/5] Tools" -ForegroundColor Cyan

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
    Write-Host "`n[5/5] Clean PATH" -ForegroundColor Cyan

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
