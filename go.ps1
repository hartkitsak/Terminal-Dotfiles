$InstallDir = "D:\dev-setup\Terminal-Dotfiles"
$RepoUrl    = "https://github.com/hartkitsak/Terminal-Dotfiles.git"

$ErrorActionPreference = "Stop"

# Detect if already cloned
if (Test-Path "$InstallDir\.git") {
    $repoPath = $InstallDir
}
else {
    Write-Host "Cloning dotfiles to $InstallDir ..." -ForegroundColor Cyan
    if (Test-Path $InstallDir) {
        git -C $InstallDir pull 2>$null
    }
    else {
        git clone $RepoUrl $InstallDir
    }
    $repoPath = $InstallDir
}

& "$repoPath\install.ps1"
