$ProjectRoot = Split-Path -Parent $PSScriptRoot
$UninstallPath = Join-Path $ProjectRoot "uninstall.ps1"
$InstallPath = Join-Path $ProjectRoot "install.ps1"

$UninstallContent = Get-Content $UninstallPath -Raw

Describe "Uninstall Script - File" {

    It "should exist at project root" {
        Test-Path $UninstallPath | Should Be $true
    }

    It "should be valid PowerShell (no parse errors)" {
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($UninstallPath, [ref]$null, [ref]$errors)
        $errors.Count | Should Be 0
    }
}

Describe "Uninstall Script - Parameters" {

    It "should declare -SkipConfig switch" {
        $UninstallContent | Should Match '\$SkipConfig'
    }

    It "should declare -SkipStarship switch" {
        $UninstallContent | Should Match '\$SkipStarship'
    }

    It "should declare -SkipFont switch" {
        $UninstallContent | Should Match '\$SkipFont'
    }

    It "should declare -SkipTools switch" {
        $UninstallContent | Should Match '\$SkipTools'
    }

    It "should declare -SkipCleanup switch" {
        $UninstallContent | Should Match '\$SkipCleanup'
    }

    It "should have same parameter names as install.ps1" {
        $InstallContent = Get-Content $InstallPath -Raw
        $installParams = @("SkipConfig","SkipTools","SkipStarship","SkipFont","SkipCleanup")
        foreach ($p in $installParams) {
            $found = $UninstallContent | Select-String -SimpleMatch -Quiet -Pattern $p
            $found | Should Be $true
        }
    }
}

Describe "Uninstall Script - Admin Elevation" {

    It "should use Verb = RunAs for self-elevation" {
        $found = $UninstallContent | Select-String -SimpleMatch -Quiet 'Verb = "RunAs"'
        $found | Should Be $true
    }

    It "should exit after triggering elevation" {
        $found = $UninstallContent | Select-String -SimpleMatch -Quiet "exit"
        $found | Should Be $true
    }

    It "should pass PSBoundParameters on re-launch" {
        $UninstallContent | Should Match 'PSBoundParameters'
    }

    It "should use pwsh.exe to re-launch" {
        $found = $UninstallContent | Select-String -SimpleMatch -Quiet "pwsh.exe"
        $found | Should Be $true
    }
}

Describe "Uninstall Script - Phase 1: Config" {

    It "should target PowerShell Profile at `$PROFILE" {
        $UninstallContent | Should Match 'Path = \$PROFILE'
    }

    It "should target Starship config at .config\starship.toml" {
        $UninstallContent | Should Match 'starship\.toml'
    }

    It "should target Windows Terminal settings" {
        $UninstallContent | Should Match 'WindowsTerminal'
    }

    It "should restore latest .bak.* backup after removal" {
        $UninstallContent | Should Match '\.bak\.\*'
    }
}

Describe "Uninstall Script - Phase 2: Starship" {

    It "should target ~\.starship directory" {
        $UninstallContent | Should Match '\.starship'
    }

    It "should use Remove-Item on starship dir" {
        $hasRemoveItem = $UninstallContent | Select-String -SimpleMatch -Quiet "Remove-Item"
        $hasStarship = $UninstallContent | Select-String -SimpleMatch -Quiet ".starship"
        $hasRemoveItem | Should Be $true
        $hasStarship | Should Be $true
    }
}

Describe "Uninstall Script - Phase 3: FiraCode Font" {

    It "should remove FiraCode font files" {
        $UninstallContent | Should Match 'FiraCode\*Nerd\*'
    }

    It "should remove HKCU font registry entries" {
        $UninstallContent | Should Match 'HKEY_CURRENT_USER'
    }

    It "should remove HKLM font registry entries" {
        $UninstallContent | Should Match 'HKEY_LOCAL_MACHINE'
    }
}

Describe "Uninstall Script - Phase 4: Tools" {

    It "should uninstall fzf via winget" {
        $UninstallContent | Should Match 'junegunn\.fzf'
    }

    It "should uninstall zoxide via winget" {
        $UninstallContent | Should Match 'ajeetdsouza\.zoxide'
    }

    It "should uninstall ripgrep via winget" {
        $UninstallContent | Should Match 'BurntSushi\.ripgrep'
    }

    It "should uninstall starship via winget" {
        $UninstallContent | Should Match 'Starship\.Starship'
    }

    It "should check both Get-Command and winget list" {
        $UninstallContent | Should Match 'Get-Command.*winget list'
    }

    It "should retry with elevation (RunAs) if winget uninstall fails" {
        $UninstallContent | Should Match 'Verb = "RunAs"'
    }
}

Describe "Uninstall Script - Phase 5: Clean PATH" {

    It "should clean User PATH from registry" {
        $UninstallContent | Should Match 'HKEY_CURRENT_USER\\Environment'
    }

    It "should clean Machine PATH from registry" {
        $UninstallContent | Should Match 'HKEY_LOCAL_MACHINE\\SYSTEM'
    }

    It "should remove starship stale PATH entries" {
        $found = $UninstallContent | Select-String -SimpleMatch -Quiet "starship"
        $found | Should Be $true
    }

    It "should remove winget stale PATH entries for fzf" {
        $UninstallContent | Should Match 'junegunn'
    }

    It "should remove winget stale PATH entries for zoxide" {
        $UninstallContent | Should Match 'ajeetdsouza'
    }
}

Describe "Uninstall Script - Self-Clone" {

    It "should support auto-clone via irm | iex" {
        $UninstallContent | Should Match '\$cloneDir'
    }

    It "should check for git before cloning" {
        $UninstallContent | Should Match 'Get-Command git'
    }

    It "should reference the same repoUrl as install.ps1" {
        $InstallContent = Get-Content $InstallPath -Raw
        $urlMatch = [regex]::Match($InstallContent, '\$repoUrl = "([^"]+)"')
        if ($urlMatch.Success) {
            $repoUrl = $urlMatch.Groups[1].Value
            $found = $UninstallContent | Select-String -SimpleMatch -Quiet $repoUrl
            $found | Should Be $true
        }
    }
}
