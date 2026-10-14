# Registers the `keepalive` scheduled task: runs %LOCALAPPDATA%\keepalive\keepalive.ps1 hidden at
# logon and keeps it running (restarted if it dies). It nudges the mouse 1px and back after 2 min
# idle so Windows never locks / logs off for inactivity. Re-running replaces the task and
# (re)starts it right away.
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-keepalive.ps1
$ErrorActionPreference = 'Stop'

$script = "$env:LOCALAPPDATA\keepalive\keepalive.ps1"
# the WindowsApps alias survives PowerShell updates; the versioned package path doesn't
$pwsh = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
foreach ($f in $script, $pwsh) { if (-not (Test-Path $f)) { throw "$f is missing" } }
$user = "$env:USERDOMAIN\$env:USERNAME"

# conhost --headless: no console window
$action = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument "--headless `"$pwsh`" -NoProfile -NonInteractive -File `"$script`""

$logon = New-ScheduledTaskTrigger -AtLogOn -User $user

# no time limit, restart if it ever exits, ignore battery state
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
  -MultipleInstances IgnoreNew -ExecutionTimeLimit ([TimeSpan]::Zero) `
  -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1)
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName 'keepalive' -Force -Action $action -Trigger $logon -Settings $settings -Principal $principal `
  -Description 'Nudge the mouse when idle so the session never locks. Script: %LOCALAPPDATA%\keepalive\keepalive.ps1' | Out-Null
Start-ScheduledTask -TaskName 'keepalive'
'keepalive task registered and started'
