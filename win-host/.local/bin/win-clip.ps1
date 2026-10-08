# Windows clipboard for yazi (plugins\winclip.yazi). Windows PowerShell 5.1 only: pwsh's
# Set-/Get-Clipboard handle text alone, no file lists or images.
#
#   win-clip.ps1 copy <path>...   puts the files on the clipboard as files, like Explorer's ctrl+c:
#                                 ctrl+v attaches them in Teams/Outlook/browsers, pastes in Explorer
#   win-clip.ps1 paste <dir>      copies the clipboard's files into dir; a copied image (screenshot)
#                                 is saved there as PNG instead. Never overwrites: "name (2).ext".
param(
  [Parameter(Mandatory)][ValidateSet('copy', 'paste')][string]$Mode,
  [Parameter(ValueFromRemainingArguments)][string[]]$Paths
)
$ErrorActionPreference = 'Stop'

if ($Mode -eq 'copy') {
  Set-Clipboard -LiteralPath $Paths
  if ($Paths.Count -eq 1) { "copied $(Split-Path -Leaf $Paths[0])" } else { "copied $($Paths.Count) files" }
  return
}

$dest = $Paths[0]
function FreePath($name) {
  $path = Join-Path $dest $name
  $base = [IO.Path]::GetFileNameWithoutExtension($name)
  $ext = [IO.Path]::GetExtension($name)
  for ($i = 2; Test-Path -LiteralPath $path; $i++) { $path = Join-Path $dest "$base ($i)$ext" }
  $path
}

$files = Get-Clipboard -Format FileDropList
if ($files) {
  foreach ($f in $files) { Copy-Item -LiteralPath $f.FullName -Destination (FreePath $f.Name) -Recurse }
  if (@($files).Count -eq 1) { "pasted $(@($files)[0].Name)" } else { "pasted $(@($files).Count) files" }
  return
}

$image = Get-Clipboard -Format Image
if ($image) {
  Add-Type -AssemblyName System.Drawing
  $path = FreePath ('clipboard-{0:yyyyMMdd-HHmmss}.png' -f (Get-Date))
  $image.Save($path, [Drawing.Imaging.ImageFormat]::Png)
  "pasted image as $(Split-Path -Leaf $path)"
  return
}
'no files or image on the clipboard'
