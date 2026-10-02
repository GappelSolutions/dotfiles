# Registers vis with Explorer, per user: in "Open with", and as the default for the text formats
# below. Opens in Rio through .local\bin\vis-open.cmd. Re-run after moving Rio or the profile.
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File win-host\register-vis.ps1
#
# An app picked with "Always" (Explorer's UserChoice) still wins over this default; pick vis there.
$ErrorActionPreference = 'Stop'

$progId = 'Rio.Vis'
$rio = 'C:\Program Files\Rio\rio.exe'
$visOpen = "$env:USERPROFILE\.local\bin\vis-open.cmd"
$exts = -split '
  .adoc .bash .bat .c .cc .cfg .cjs .cmd .conf .cpp .cs .csproj .css .csv .diff .dockerfile .env
  .fish .fs .fsproj .gitignore .go .graphql .h .hpp .htm .html .ini .java .js .json .jsonc .jsx .kt
  .less .log .lua .markdown .md .mjs .nix .patch .php .properties .props .proto .ps1 .psd1 .psm1 .py
  .rb .rs .rst .sass .scss .sh .sln .sql .svelte .swift .targets .tf .tfvars .toml .ts .tsx .txt .vim
  .vue .xml .yaml .yml .zsh
'

foreach ($f in $rio, $visOpen) { if (-not (Test-Path $f)) { throw "$f is missing" } }
# Rio joins -e's arguments with spaces, unquoted: %1 brings its own quotes, the script path can't
# have any
if ($visOpen -match ' ') { throw "$visOpen has a space" }

# CreateSubKey opens existing keys as they are; New-Item -Force would empty them
function Key($path) { [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey("Software\Classes\$path") }

$icon = "`"$rio`",0"
(Key $progId).SetValue('', 'vis')
(Key $progId).SetValue('FriendlyTypeName', 'vis')
(Key "$progId\DefaultIcon").SetValue('', $icon)
(Key "$progId\Application").SetValue('ApplicationName', 'vis')
(Key "$progId\Application").SetValue('ApplicationIcon', $icon)
(Key "$progId\shell\open").SetValue('FriendlyAppName', 'vis')
(Key "$progId\shell\open\command").SetValue('', ('"{0}" -e cmd.exe /c {1} "\"%1\""' -f $rio, $visOpen))

foreach ($ext in $exts) {
  (Key $ext).SetValue('', $progId)
  (Key "$ext\OpenWithProgids").SetValue($progId, [byte[]]@(), 'None')
}

# Explorer caches associations until told they changed (SHCNE_ASSOCCHANGED)
Add-Type -Namespace Win32 -Name Shell -MemberDefinition '[DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, uint f, IntPtr a, IntPtr b);'
[Win32.Shell]::SHChangeNotify(0x08000000, 0, [IntPtr]::Zero, [IntPtr]::Zero)
"vis registered for $($exts.Count) extensions"
