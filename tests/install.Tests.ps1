$ProjectRoot = Split-Path -Parent $PSScriptRoot
$ProfilePath = Join-Path $ProjectRoot "profile\Microsoft.PowerShell_profile.ps1"
$InstallPath = Join-Path $ProjectRoot "install.ps1"
$UninstallPath = Join-Path $ProjectRoot "uninstall.ps1"

$ProfileContent = Get-Content $ProfilePath -Raw

Describe "Profile Script - Functions" {

    It "should define function '..'" {
        $ProfileContent | Should Match "function \.\.\s*\{"
    }

    It "should define function '...'" {
        $ProfileContent | Should Match "function \.\.\.\s*\{"
    }

    It "should define function 'take'" {
        $ProfileContent | Should Match "function take\s*\{"
    }

    It "should define function 'ff'" {
        $ProfileContent | Should Match "function ff\s*\{"
    }

    It "should define function 'cdf'" {
        $ProfileContent | Should Match "function cdf\s*\{"
    }
}

Describe "Profile Script - Aliases" {

    It "should define alias ll -> Get-ChildItem" {
        $ProfileContent | Should Match "Set-Alias ll Get-ChildItem"
    }

    It "should define alias gs -> git" {
        $ProfileContent | Should Match "Set-Alias gs git"
    }

    It "should define function gco" {
        $ProfileContent | Should Match "function gco\s*\{"
    }

    It "should define function gcmsg" {
        $ProfileContent | Should Match "function gcmsg\s*\{"
    }
}

Describe "Profile Script - Tools Init" {

    It "should init zoxide" {
        $ProfileContent | Should Match "zoxide init"
    }

    It "should load PSFzf" {
        $ProfileContent | Should Match "Import-Module PSFzf"
    }

    It "should init starship" {
        $ProfileContent | Should Match "starship init"
    }

    It "should load PSReadLine" {
        $ProfileContent | Should Match "Set-PSReadLineOption"
    }
}

Describe "Install Script" {

    It "should exist at project root" {
        Test-Path $InstallPath | Should Be $true
    }

    It "should declare SkipTools parameter" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match '\$SkipTools'
    }

    It "should declare SkipConfig parameter" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match '\$SkipConfig'
    }

    It "should declare SkipStarship parameter" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match '\$SkipStarship'
    }

    It "should declare SkipFont parameter" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match '\$SkipFont'
    }

    It "should declare SkipCleanup parameter" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match '\$SkipCleanup'
    }

    It "should install fzf via winget" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match "junegunn\.fzf"
    }

    It "should install zoxide via winget" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match "ajeetdsouza\.zoxide"
    }

    It "should install ripgrep via winget" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match "BurntSushi\.ripgrep"
    }

    It "should download FiraCode Nerd Font" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match "FiraCode"
    }

    It "should self-elevate to admin" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match "Verb = .RunAs."
    }

    It "should exit after elevation" {
        $InstallContent = Get-Content $InstallPath -Raw
        ($InstallContent | Select-String -SimpleMatch "exit").Count | Should BeGreaterThan 0
    }

    It "should pass bound parameters on re-launch" {
        $InstallContent = Get-Content $InstallPath -Raw
        $InstallContent | Should Match "PSBoundParameters"
    }
}

Describe "Config Files" {

    It "should have starship.toml" {
        $path = Join-Path $ProjectRoot "config\starship.toml"
        Test-Path $path | Should Be $true
    }

    It "should have windows-terminal.settings.json" {
        $path = Join-Path $ProjectRoot "config\windows-terminal.settings.json"
        Test-Path $path | Should Be $true
    }

    It "should have PowerShell profile" {
        $path = Join-Path $ProjectRoot "profile\Microsoft.PowerShell_profile.ps1"
        Test-Path $path | Should Be $true
    }
}

Describe "Starship Config" {

    $starshipContent = Get-Content (Join-Path $ProjectRoot "config\starship.toml") -Raw

    It "should disable add_newline or set to false" {
        $starshipContent | Should Match "add_newline"
    }

    It "should define os module" {
        $starshipContent | Should Match "\[os\]"
    }

    It "should define directory module" {
        $starshipContent | Should Match "\[directory\]"
    }

    It "should define git_branch module" {
        $starshipContent | Should Match "\[git_branch\]"
    }

    It "should define character module" {
        $starshipContent | Should Match "\[character\]"
    }

}
