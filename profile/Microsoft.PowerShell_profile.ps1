function Resolve-CommandPath {
    param([string]$Name)
    $path = (Get-Command $Name -ErrorAction SilentlyContinue).Source
    if (-not $path) { return $null }
    $item = Get-Item $path -Force -ErrorAction SilentlyContinue
    if ($item.LinkType) { return $item.Target }
    return $path
}

if ($Host.Name -eq "ConsoleHost" -and $Host.UI.SupportsVirtualTerminal) {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
    }
}

$zoxidePath = Resolve-CommandPath zoxide
if ($zoxidePath) {
    Invoke-Expression (& { (& $zoxidePath init powershell | Out-String) })
}

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}

$env:FZF_DEFAULT_OPTS = "--height=40% --layout=reverse --border --inline-info"

function ff {
    $rgPath = Resolve-CommandPath rg
    $fzfPath = Resolve-CommandPath fzf
    if (-not $rgPath -or -not $fzfPath) { return }
    & $rgPath --files --hidden --glob '!.git' | & $fzfPath
}

function cdf {
    $fzfPath = Resolve-CommandPath fzf
    if (-not $fzfPath) { return }
    Set-Location (Get-ChildItem -Directory -Recurse -Depth 4 -ErrorAction SilentlyContinue | ForEach-Object FullName | & $fzfPath)
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
function la {
    Get-ChildItem -Force @args
}
Set-Alias gs git
function ga { git add @args }
function gp { git push @args }
function gst { git status @args }

function gco {
    git checkout @Args
}

function gcmsg {
    git commit -m $Args
}

function gl {
    git log --oneline --graph --decorate @Args
}

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias v nvim
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}