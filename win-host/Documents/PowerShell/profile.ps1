Import-Module PSReadLine

# atuin
Invoke-Expression (& { (atuin init powershell | Out-String) })

# zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# fzf keybindings (ctrl+r history, ctrl+t files)
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

# aliases matching wsl profile
function ll { eza -la @args }
function ls { eza @args }
function lt { eza --tree --level=1 --icons @args }
function cat { bat @args }
function lg { lazygit @args }
function ld { lazydocker @args }

$env:VISUAL = "nvim"
$env:EDITOR = "nvim"

function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi @args --cwd-file="$tmp"
    $cwd = Get-Content $tmp -Raw
    if ($cwd -and (Test-Path $cwd) -and ($cwd -ne $PWD.Path)) {
        Set-Location $cwd
    }
    Remove-Item $tmp -ErrorAction SilentlyContinue
}

# --- Prompt (ported from zsh vcs_info bubble prompt) ---
$bubbleLeft  = [char]0xe0b6
$bubbleRight = [char]0xe0b4
$gitIcon     = [char]0xf418
$hostIcon    = [char]::ConvertFromUtf32(0xf0a21)  # nf-md-microsoft_windows_classic
$dirtyIcon   = "*"

function global:prompt {
    $esc = [char]27
    $branch = $null
    $dirty = $false
    try {
        $branch = git rev-parse --abbrev-ref HEAD 2>$null
        if ($LASTEXITCODE -eq 0 -and $branch) {
            $status = git status --porcelain 2>$null
            if ($status) { $dirty = $true }
        } else {
            $branch = $null
        }
    } catch { $branch = $null }

    $path = $PWD.Path.Replace($HOME, "~")

    if ($branch) {
        if ($dirty) {
            $bg = "43"; $gitInfo = "$esc[${bg}m$esc[32m${bubbleRight}$esc[0m$esc[30m$esc[${bg}m  $gitIcon $branch $dirtyIcon $esc[0m$esc[33m${bubbleRight}$esc[0m"
        } else {
            $bg = "44"; $gitInfo = "$esc[${bg}m$esc[32m${bubbleRight}$esc[0m$esc[30m$esc[${bg}m  $gitIcon $branch $esc[0m$esc[34m${bubbleRight}$esc[0m"
        }
    } else {
        $gitInfo = "$esc[32m${bubbleRight}$esc[0m"
    }

    "`n $esc[34m${bubbleLeft}$esc[44m$esc[30m $hostIcon $esc[42m$esc[34m${bubbleRight}$esc[30m  $path $esc[0m$gitInfo`n $esc[34m╰─❯$esc[0m "
}
