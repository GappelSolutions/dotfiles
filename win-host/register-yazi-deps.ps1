# Windows-side tools yazi shells out to for previews: pdftoppm (PDF previews) from poppler. Per
# user, no admin; rerun after a poppler upgrade, since the versioned directory changes.
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-yazi-deps.ps1
#
# Why PATH and not winget's Links\ symlinks: poppler's exes load their DLLs from their own
# directory, and through a symlink Windows looks next to the link instead, so pdftoppm dies with
# STATUS_DLL_NOT_FOUND. The poppler bin directory goes on the user PATH instead.
$ErrorActionPreference = 'Stop'

$id = 'oschwartz10612.Poppler'
$pkgs = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages"
$find = { Get-ChildItem $pkgs -Directory -Filter "$id*" -ErrorAction SilentlyContinue |
  Get-ChildItem -Recurse -Filter pdftoppm.exe | Select-Object -First 1 }

if (-not (& $find)) {
  winget install --id $id -e --source winget --accept-package-agreements --accept-source-agreements --disable-interactivity
  if ($LASTEXITCODE) { throw "winget install $id failed ($LASTEXITCODE)" }
}
$bin = (& $find).DirectoryName

# Drop stale poppler entries (older versions), then append the current one.
$path = [Environment]::GetEnvironmentVariable('Path', 'User') -split ';' |
  Where-Object { $_ -and $_ -notlike "$pkgs\$id*" }
[Environment]::SetEnvironmentVariable('Path', (@($path) + $bin) -join ';', 'User')
"pdftoppm on user PATH: $bin (new shells only; restart yazi)"
