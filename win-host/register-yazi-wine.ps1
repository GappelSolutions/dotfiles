# Makes Win+E (and the taskbar's File Explorer button) open yazi in a full-width Rio tile instead
# of Explorer. Per user, no admin. Explorer itself, its folder windows and "Open folder" from other
# apps stay as they are.
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-yazi-wine.ps1
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-yazi-wine.ps1 -Undo
#
# How: Win+E runs the `opennewwindow` verb of the shell's Home/This PC object; an HKCU command for
# that verb with an empty DelegateExecute replaces Explorer's handler (the same trick the Files app
# uses). Endpoint security on managed machines may silently revert it.
param([switch]$Undo)
$ErrorActionPreference = 'Stop'

$key = 'Software\Classes\CLSID\{52205fd8-5dfb-447d-801a-d0b52f2e83e1}'
$rio = 'C:\Program Files\Rio\rio.exe'

if ($Undo) {
  [Microsoft.Win32.Registry]::CurrentUser.DeleteSubKeyTree($key, $false)
  'Win+E opens Explorer again'
  return
}

$launcher = "$env:USERPROFILE\.local\bin\yazi-wide.ps1"
$pwsh = "$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe"
foreach ($f in $rio, $launcher, $pwsh) { if (-not (Test-Path $f)) { throw "$f is missing" } }
$cmd = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("$key\shell\opennewwindow\command")
# yazi-wide.ps1 tiles the window (full width, bottom third); conhost --headless hides pwsh's
# console. ExpandString: the %VARS% are resolved when the shell runs it.
$cmd.SetValue('', 'conhost.exe --headless "%LOCALAPPDATA%\Microsoft\WindowsApps\pwsh.exe" -NoProfile -NonInteractive -File "%USERPROFILE%\.local\bin\yazi-wide.ps1"', 'ExpandString')
$cmd.SetValue('DelegateExecute', '')
'Win+E opens yazi'
