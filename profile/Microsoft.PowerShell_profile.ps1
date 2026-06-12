if ($Host.Name -eq "ConsoleHost" -and $Host.UI.SupportsVirtualTerminal) {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    $zoxidePath = (Get-Command zoxide).Source
    $zoxideItem = Get-Item $zoxidePath -Force -ErrorAction SilentlyContinue
    if ($zoxideItem.LinkType) { $zoxidePath = $zoxideItem.Target }
    Invoke-Expression (& { (& $zoxidePath init powershell | Out-String) })
}

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

$env:FZF_DEFAULT_OPTS = "--height=40% --layout=reverse --border --inline-info"

function ff {
    $rgPath = (Get-Command rg -ErrorAction SilentlyContinue).Source
    $fzfPath = (Get-Command fzf -ErrorAction SilentlyContinue).Source
    if (-not $rgPath -or -not $fzfPath) { return }
    $rgItem = Get-Item $rgPath -Force -ErrorAction SilentlyContinue
    if ($rgItem.LinkType) { $rgPath = $rgItem.Target }
    $fzfItem = Get-Item $fzfPath -Force -ErrorAction SilentlyContinue
    if ($fzfItem.LinkType) { $fzfPath = $fzfItem.Target }
    & $rgPath --files | & $fzfPath
}

function cdf {
    $fzfPath = (Get-Command fzf -ErrorAction SilentlyContinue).Source
    if (-not $fzfPath) { return }
    $fzfItem = Get-Item $fzfPath -Force -ErrorAction SilentlyContinue
    if ($fzfItem.LinkType) { $fzfPath = $fzfItem.Target }
    Set-Location (Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName | & $fzfPath)
}

function .. {
    Set-Location ..
}

function ... {
    Set-Location ../..
}

function take {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path
    )

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

Set-Alias ll Get-ChildItem
Set-Alias gs git
function gco {
    git checkout @Args
}

function gcmsg {
    git commit -m $Args
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias v nvim
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# HksUtil — Windows Optimizer Tool
$hksUtilPaths = @(
    "$env:USERPROFILE\dev\HksUtil\app.ps1",
    "D:\dev-setup\HksUtil\app.ps1",
    "$env:USERPROFILE\HksUtil\hksutil.ps1"
)
foreach ($p in $hksUtilPaths) {
    if (Test-Path $p) {
        Set-Alias hksutil $p
        break
    }
}