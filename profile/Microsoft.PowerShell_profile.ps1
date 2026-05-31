if ($Host.Name -eq "ConsoleHost" -and $Host.UI.SupportsVirtualTerminal) {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Set-PSReadLineOption -PredictionSource History -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -EditMode Windows -ErrorAction SilentlyContinue
        Set-PSReadLineOption -Colors @{
            Command            = "#cba6f7"
            Parameter          = "#89b4fa"
            Operator           = "#fab387"
            String             = "#a6e3a1"
            Number             = "#fab387"
            Variable           = "#f5c2e7"
            Member             = "#89dceb"
            Keyword            = "#cba6f7"
            Type               = "#b4befe"
            Comment            = "#585b70"
            ContinuationPrompt = "#6c7086"
            Emphasis           = "#f38ba8"
            Error              = "#f38ba8"
            Selection          = "#313244"
            InlinePrediction   = "#6c7086"
            ListPrediction     = "#6c7086"
            ListPredictionSelected = "#313244"
        } -ErrorAction SilentlyContinue
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

