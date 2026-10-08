# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Yazi Downloads
# @raycast.mode silent
# @raycast.packageName Files

# Optional parameters:
# @raycast.platform windows
# @raycast.icon 📂
# @raycast.description Open yazi in Downloads, as a full-width tile across the bottom third

# Keep ASCII only: Windows PowerShell 5.1 misreads BOM-less UTF-8 (the icon
# line above is a comment and only read by Raycast).
# Downloads can be redirected (OneDrive, another drive): ask the shell, not $HOME.
$dir = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path
# yazi-wide.ps1 stays until yazi closes (it restores the layout then): detach it from Raycast,
# hidden like Win+E's
Start-Process conhost.exe -ArgumentList '--headless', "`"$env:LOCALAPPDATA\Microsoft\WindowsApps\pwsh.exe`"",
  '-NoProfile', '-NonInteractive', '-File', "`"$env:USERPROFILE\.local\bin\yazi-wide.ps1`"", "`"$dir`""
