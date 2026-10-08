# Opens yazi in Rio as a full-width tile across the top third of the screen: long file names need
# the width. komorebi has no per-window placement, so while yazi is open its workspace switches to
# HorizontalStack with yazi as the full-width primary row; the other windows share the bottom two
# thirds and alt+hjkl still reaches everything. When yazi closes, the workspace gets its previous
# layout back. Returns once that is done.
# Win+E (win-host/register-yazi-wine.ps1) and Raycast start it detached; yazi-pick.ps1 runs it with
# -Chooser and waits.
#
#   yazi-wide.ps1 [dir] [-Chooser file]    dir defaults to %USERPROFILE%; -Chooser: yazi writes the
#                                          paths opened with Enter there and quits (a file picker)
param([string]$Dir = $env:USERPROFILE, [string]$Chooser)
$ErrorActionPreference = 'Stop'

# Launchers like Raycast keep the environment they started with: re-read the YAZI_* user vars
# (YAZI_FILE_ONE, bookmark paths) so changes apply without restarting them
$vars = [Environment]::GetEnvironmentVariables('User')
foreach ($name in $vars.Keys) {
  if ($name -like 'YAZI_*') { [Environment]::SetEnvironmentVariable($name, $vars[$name], 'Process') }
}

Add-Type -Namespace YaziWide -Name Win32 -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();'

# "C:\" would end the quoted argument in \", escaping the quote
if ($Dir.EndsWith('\')) { $Dir += '.' }
$yazi = @('yazi')
if ($Chooser) {
  # Rio joins -e's arguments with spaces, unquoted
  if ($Chooser -match ' ') { throw "chooser path has a space: $Chooser" }
  $yazi += "--chooser-file=$Chooser"
}
$rio = Start-Process 'C:\Program Files\Rio\rio.exe' -PassThru -ArgumentList (@('--working-dir', "`"$Dir`"", '-e') + $yazi)

function KomorebiState { komorebic state | Out-String | ConvertFrom-Json }

# change-layout's names for komorebi's layouts; custom layouts have no Default and are left alone
$names = @{
  BSP = 'bsp'; Columns = 'columns'; Rows = 'rows'; VerticalStack = 'vertical-stack'
  UltrawideVerticalStack = 'ultrawide-vertical-stack'; Grid = 'grid'
  RightMainVerticalStack = 'right-main-vertical-stack'; Scrolling = 'scrolling'
}

# Makes our window the wide row. Returns monitor, workspace and previous layout when it changed the
# workspace's layout (and so has to restore it), else $null.
function Arrange {
  $deadline = (Get-Date).AddSeconds(10)
  while ($rio.MainWindowHandle -eq [IntPtr]::Zero -or [YaziWide.Win32]::GetForegroundWindow() -ne $rio.MainWindowHandle) {
    if ((Get-Date) -gt $deadline -or $rio.HasExited) { return }
    Start-Sleep -Milliseconds 50
    $rio.Refresh()
  }
  $hwnd = [int64]$rio.MainWindowHandle

  # monitor and workspace tiling our window; komorebi takes a moment to pick it up
  $deadline = (Get-Date).AddSeconds(5)
  while ($true) {
    $monitors = @((KomorebiState).monitors.elements)
    for ($m = 0; $m -lt $monitors.Count; $m++) {
      $workspaces = @($monitors[$m].workspaces.elements)
      for ($w = 0; $w -lt $workspaces.Count; $w++) {
        if ($workspaces[$w].containers.elements.windows.elements.hwnd -contains $hwnd) {
          $tile = @{ Monitor = $m; Workspace = $w; Layout = [string]$workspaces[$w].layout.Default }
        }
      }
    }
    if ($tile) { break }
    if ((Get-Date) -gt $deadline) { return }
    Start-Sleep -Milliseconds 100
  }

  # HorizontalStack already: another yazi set the workspace up, and that one restores it
  if ($tile.Layout -eq 'HorizontalStack') { komorebic promote | Out-Null; return }
  if (-not $names.ContainsKey($tile.Layout)) { return }

  # all act on the focused workspace, ours: our window has the focus
  komorebic change-layout horizontal-stack | Out-Null
  komorebic promote | Out-Null
  # 0.1.41's HorizontalStack takes the primary row's height from row_ratios[0] (its schema says
  # column_ratios). The row ratio stays behind afterwards; BSP and the column layouts ignore it.
  komorebic layout-ratios --rows 0.33 | Out-Null
  # No flip-layout to put the row at the bottom: with a row ratio set, 0.1.41 flips the primary row
  # but not the stack, so the two overlap.
  $tile
}

$tile = Arrange
$rio.WaitForExit()
if (-not $tile) { return }

# Restore unless the layout was changed meanwhile. change-layout only acts on the focused
# workspace: if the user is elsewhere, wait until they come back.
while (Get-Process komorebi -ErrorAction SilentlyContinue) {
  $state = KomorebiState
  $monitor = @($state.monitors.elements)[$tile.Monitor]
  if (@($monitor.workspaces.elements)[$tile.Workspace].layout.Default -ne 'HorizontalStack') { return }
  if ($state.monitors.focused -eq $tile.Monitor -and $monitor.workspaces.focused -eq $tile.Workspace) {
    komorebic change-layout $names[$tile.Layout]
    return
  }
  Start-Sleep -Seconds 1
}
