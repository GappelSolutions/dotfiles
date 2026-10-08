# Registers the `fidx` scheduled task: refreshes the network-drive file lists that yazi's `z`
# (AppData\Roaming\yazi\config\plugins\fidx.yazi) searches. Runs hidden 2 min after logon, 1 min
# after any network/VPN connect and every 3 h; fidx.ps1 skips lists younger than 2 h. Which drives
# get crawled is the $Drives default in fidx.ps1. Re-running replaces the task.
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-fidx.ps1
$ErrorActionPreference = 'Stop'

$script = "$env:LOCALAPPDATA\fidx\fidx.ps1"
# the WindowsApps alias survives PowerShell updates; the versioned package path doesn't
$pwsh = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
foreach ($f in $script, $pwsh) { if (-not (Test-Path $f)) { throw "$f is missing" } }
$user = "$env:USERDOMAIN\$env:USERNAME"

# conhost --headless: no console window flashing up on every run
$action = New-ScheduledTaskAction -Execute 'conhost.exe' -Argument "--headless `"$pwsh`" -NoProfile -NonInteractive -File `"$script`" -MaxAgeMinutes 120"

$logon = New-ScheduledTaskTrigger -AtLogOn -User $user
$logon.Delay = 'PT2M'
$interval = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddHours(7) -RepetitionInterval (New-TimeSpan -Hours 3)
# NetworkProfile 10000 = a network (incl. the VPN adapter) connected
$cls = Get-CimClass -Namespace root/Microsoft/Windows/TaskScheduler -ClassName MSFT_TaskEventTrigger
$netup = New-CimInstance -CimClass $cls -ClientOnly -Property @{
  Enabled = $true
  Delay = 'PT1M'
  Subscription = '<QueryList><Query Id="0" Path="Microsoft-Windows-NetworkProfile/Operational"><Select Path="Microsoft-Windows-NetworkProfile/Operational">*[System[EventID=10000]]</Select></Query></QueryList>'
}

$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable `
  -RunOnlyIfNetworkAvailable -MultipleInstances IgnoreNew -ExecutionTimeLimit (New-TimeSpan -Hours 3)
$principal = New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Limited

Register-ScheduledTask -TaskName 'fidx' -Force -Action $action -Trigger $logon, $interval, $netup -Settings $settings -Principal $principal `
  -Description 'Refresh fidx file lists for network drives (yazi z). Script: %LOCALAPPDATA%\fidx\fidx.ps1' | Out-Null
'fidx task registered'
