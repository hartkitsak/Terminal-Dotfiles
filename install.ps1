param(
    [switch]$SkipConfig,
    [switch]$SkipTools,
    [switch]$SkipStarship,
    [switch]$SkipFont,
    [switch]$SkipCleanup
)

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/hartkitsak/nova.git"
$scriptPath = try { Split-Path -Parent $PSCommandPath -ErrorAction Stop } catch { $null }

# Auto-clone when piped via irm | iex (no local files)
if (-not $scriptPath -or -not (Test-Path (Join-Path $scriptPath "profile\Microsoft.PowerShell_profile.ps1"))) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw "Git is required. Install it first: winget install Git.Git" }
    $cloneDir = Join-Path $env:TEMP "nova"
    Write-Host "=== Cloning repo to $cloneDir ===" -ForegroundColor Cyan
    if (Test-Path "$cloneDir\.git") { git -C $cloneDir pull } else { git clone $repoUrl $cloneDir }
    & "$cloneDir\install.ps1" @PSBoundParameters
    return
}
$DOTFILES = $scriptPath

$BackupSuffix = ".bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# ─── Phase 1: Tools (winget) ────────────────────────────────────────
if (-not $SkipTools) {
    Write-Host "`n[1/5] Tools" -ForegroundColor Cyan

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

# ─── Phase 2: Starship (manual) ─────────────────────────────────────
if (-not $SkipStarship) {
    Write-Host "`n[2/5] Starship" -ForegroundColor Cyan

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

# ─── Phase 3: FiraCode Nerd Font ─────────────────────────────────────
if (-not $SkipFont) {
    Write-Host "`n[3/5] FiraCode Nerd Font" -ForegroundColor Cyan

    $FontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $HklmReg = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    $HkcuReg = "Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    $Zipped = "$env:TEMP\FiraCode.zip"
    $ExtractDir = "$env:TEMP\FiraCode-NF"

    try {
        New-Item -ItemType Directory -Path $FontDir -Force | Out-Null
        New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null

        Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip" -OutFile $Zipped -ErrorAction Stop
        Expand-Archive -Path $Zipped -DestinationPath $ExtractDir -Force
        Remove-Item $Zipped -Force

        $WeightMap = @{
            "Light"    = "Light"
            "Regular"  = "Regular"
            "Medium"   = "Med"
            "Retina"   = "Ret"
            "SemiBold" = "SemBd"
            "Bold"     = "Bold"
        }

        $ttfFiles = Get-ChildItem -Path $ExtractDir -Filter "*.ttf" | Where-Object { $_.Name -match "^FiraCode.*Nerd" }
        $count = 0; $regCount = 0

        foreach ($f in $ttfFiles) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($f.Name)
            if ($baseName -match "^FiraCodeNerdFont(Mono|Propo)?-(.+)$") {
                $variant = $matches[1]
                $weight = $matches[2]
                $win32Face = if ($WeightMap.ContainsKey($weight)) { $WeightMap[$weight] } else { $weight }
                $family = if ($variant) { "FiraCode Nerd Font $variant" } else { "FiraCode Nerd Font" }
                $key = "$family $win32Face (TrueType)"
            } else {
                continue
            }

            $targetPath = Join-Path $FontDir $f.Name
            $alreadyInstalled = (Test-Path $targetPath) -and ((Get-ItemProperty -Path $HkcuReg -Name $key -ErrorAction SilentlyContinue) -or (Get-ItemProperty -Path $HklmReg -Name $key -ErrorAction SilentlyContinue))

            if ($alreadyInstalled) {
                Write-Host "  [SAME]  $($f.Name)" -ForegroundColor Green
                $count++; $regCount++
                continue
            }

            try {
                Copy-Item -Path $f.FullName -Destination $targetPath -Force
                $count++
            } catch {
                Write-Host "  [SKIP]  $($f.Name) (in use)" -ForegroundColor Yellow
                continue
            }

            try {
                New-ItemProperty -Path $HkcuReg -Name $key -PropertyType String -Value $targetPath -Force -ErrorAction Stop | Out-Null
                $regCount++
            } catch {
                Write-Host "  [WARN] Could not register font: $key" -ForegroundColor Yellow
            }
        }

        # Clean old HKLM entries (from previous admin installs)
        try {
            $hklmKeys = Get-ItemProperty -Path $HklmReg -ErrorAction SilentlyContinue | Get-Member -MemberType NoteProperty | Where-Object { $_.Name -match "^FiraCode" }
            foreach ($k in $hklmKeys) { Remove-ItemProperty -Path $HklmReg -Name $k.Name -Force -ErrorAction SilentlyContinue }
        } catch {}

        Remove-Item -Path $ExtractDir -Recurse -Force

        try {
            Add-Type @"
                using System;
                using System.Runtime.InteropServices;
                public static class FontNotify {
                    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
                    public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam, uint fuFlags, uint uTimeout, out IntPtr lpdwResult);
                    public static void Notify() {
                        const uint WM_FONTCHANGE = 0x001D;
                        const uint SMTO_ABORTIFHUNG = 0x0002;
                        IntPtr result;
                        SendMessageTimeout((IntPtr)0xFFFF, WM_FONTCHANGE, IntPtr.Zero, IntPtr.Zero, SMTO_ABORTIFHUNG, 5000, out result);
                    }
                }
"@
            [FontNotify]::Notify()
        } catch {
            Write-Host "  [WARN] Font cache not refreshed (reboot may be needed)" -ForegroundColor Yellow
        }
        Write-Host "  [OK] $count font files copied, $regCount registry entries written" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] Font install: $_" -ForegroundColor Red
    }
}

# ─── Phase 4: Config ────────────────────────────────────────────────
if (-not $SkipConfig) {
    Write-Host "`n[4/5] Config files" -ForegroundColor Cyan

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

# ─── Phase 5: Clean stale PATH entries ──────────────────────────────
if (-not $SkipCleanup) {
    Write-Host "`n[5/5] Clean PATH" -ForegroundColor Cyan

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
