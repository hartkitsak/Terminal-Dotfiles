if ($Host.Name -eq "ConsoleHost" -and $Host.UI.SupportsVirtualTerminal) {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

$env:FZF_DEFAULT_OPTS = "--height=40% --layout=reverse --border --inline-info"

function ff {
    rg --files | fzf
}

function cdf {
    Set-Location (Get-ChildItem -Directory -Recurse -ErrorAction SilentlyContinue | ForEach-Object FullName | fzf)
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