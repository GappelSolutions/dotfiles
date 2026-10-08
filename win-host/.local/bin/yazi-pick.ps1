# alt+e (whkd) in an Open or Save dialog of any app (Teams, browsers, Office): pick in yazi instead
# and the dialog gets the result. Space selects several (from different folders too), Enter picks;
# quitting yazi with q leaves the dialog as it was. yazi starts where the last pick was.
# The standard dialog takes several full, quoted paths in its file name box, so they go straight in
# (WM_SETTEXT) and its OK button gets pressed: no typing, no clipboard. Apps with their own picker
# instead of the standard dialog are left alone.
$ErrorActionPreference = 'Stop'

Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;
public static class YaziPick {
  delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetParent(IntPtr h);
  [DllImport("user32.dll")] static extern int GetDlgCtrlID(IntPtr h);
  [DllImport("user32.dll")] static extern IntPtr GetDlgItem(IntPtr dlg, int id);
  [DllImport("user32.dll")] static extern bool EnumChildWindows(IntPtr parent, EnumProc proc, IntPtr l);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern int GetClassName(IntPtr h, StringBuilder sb, int n);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, string l);
  [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, uint msg, IntPtr w, IntPtr l);

  public static string ClassOf(IntPtr h) { var sb = new StringBuilder(64); GetClassName(h, sb, 64); return sb.ToString(); }

  // The file name box: an Edit inside the combo box with id 0x47C (Open dialogs, cmb13), or itself
  // with id 1001 (Save dialogs). Not the address bar's Edit (id 41477).
  public static IntPtr FileNameEdit(IntPtr dialog) {
    IntPtr found = IntPtr.Zero;
    EnumChildWindows(dialog, (h, l) => {
      if (ClassOf(h) != "Edit") return true;
      for (IntPtr p = h; p != IntPtr.Zero && p != dialog; p = GetParent(p)) {
        int id = GetDlgCtrlID(p);
        if (id == 0x47C || id == 1001) { found = h; return false; }
      }
      return true;
    }, IntPtr.Zero);
    return found;
  }

  public static void Fill(IntPtr dialog, IntPtr edit, string text) {
    SendMessage(edit, 0x000C /* WM_SETTEXT */, IntPtr.Zero, text);
    SendMessage(dialog, 0x0111 /* WM_COMMAND */, new IntPtr(1) /* IDOK */, GetDlgItem(dialog, 1));
  }
}
'@

$state = "$env:LOCALAPPDATA\yazi-pick"
New-Item -ItemType Directory -Force $state | Out-Null
function Log($msg) { Add-Content -LiteralPath "$state\pick.log" -Value ('{0:yyyy-MM-dd HH:mm:ss}  {1}' -f (Get-Date), $msg) }

$dialog = [YaziPick]::GetForegroundWindow()
$class = [YaziPick]::ClassOf($dialog)
if ($class -ne '#32770') { Log "no dialog in front (window class '$class')"; return }
if ([YaziPick]::FileNameEdit($dialog) -eq [IntPtr]::Zero) { Log 'dialog without a file name box (a message box?)'; return }
Log "picking for dialog $dialog"
$chooser = "$state\chosen.txt"
$lastDir = "$state\last-dir.txt"
Remove-Item -LiteralPath $chooser -ErrorAction SilentlyContinue
$start = $env:USERPROFILE
if (Test-Path -LiteralPath $lastDir) {
  $last = (Get-Content -LiteralPath $lastDir -Encoding UTF8 | Select-Object -First 1)
  if ($last -and (Test-Path -LiteralPath $last)) { $start = $last }
}

& "$PSScriptRoot\yazi-wide.ps1" $start -Chooser $chooser

$paths = @(Get-Content -LiteralPath $chooser -Encoding UTF8 -ErrorAction SilentlyContinue | Where-Object { $_ })
if (-not $paths) { Log 'nothing picked'; return }
if (-not [YaziPick]::IsWindow($dialog)) { Log 'dialog closed meanwhile'; return }
Log "filling $($paths.Count) path(s)"
Set-Content -LiteralPath $lastDir -Value (Split-Path -Parent $paths[0]) -Encoding UTF8

# a single path goes in bare: a folder then just opens in the dialog, and Save takes it as the name
$text = if ($paths.Count -eq 1) { $paths[0] } else { ($paths | ForEach-Object { "`"$_`"" }) -join ' ' }
[YaziPick]::SetForegroundWindow($dialog) | Out-Null
[YaziPick]::Fill($dialog, [YaziPick]::FileNameEdit($dialog), $text)
