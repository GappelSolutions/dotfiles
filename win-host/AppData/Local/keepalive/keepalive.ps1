# Keeps the session from idling out (screen lock / inactivity logoff). Every $CheckSeconds it
# reads the system idle time; once you've been idle for $IdleSeconds it nudges the mouse 1px and
# straight back, which resets the idle timer without moving the cursor visibly. While you're
# using the machine it does nothing. Started hidden at logon by the `keepalive` task
# (win-host/register-keepalive.ps1); a mutex keeps it to one instance.
param(
  [int]$IdleSeconds = 120,
  [int]$CheckSeconds = 30
)

Add-Type -Namespace KeepAlive -Name Native -MemberDefinition @'
[StructLayout(LayoutKind.Sequential)]
public struct LASTINPUTINFO { public uint cbSize; public uint dwTime; }

[StructLayout(LayoutKind.Sequential)]
public struct MOUSEINPUT { public int dx; public int dy; public uint mouseData; public uint dwFlags; public uint time; public IntPtr dwExtraInfo; }

// INPUT is a union; MOUSEINPUT is its largest member on x64 apart from padding, so this layout matches.
[StructLayout(LayoutKind.Sequential)]
public struct INPUT { public uint type; public MOUSEINPUT mi; }

[DllImport("user32.dll")] static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
[DllImport("user32.dll", SetLastError = true)] static extern uint SendInput(uint n, INPUT[] inputs, int size);
[DllImport("kernel32.dll")] static extern uint GetTickCount();

public static uint IdleMs() {
  var lii = new LASTINPUTINFO();
  lii.cbSize = (uint)Marshal.SizeOf(lii);
  GetLastInputInfo(ref lii);
  return unchecked(GetTickCount() - lii.dwTime);
}

public static void Nudge() {
  const uint INPUT_MOUSE = 0, MOUSEEVENTF_MOVE = 1;
  var a = new INPUT { type = INPUT_MOUSE, mi = new MOUSEINPUT { dx = 1, dwFlags = MOUSEEVENTF_MOVE } };
  var b = new INPUT { type = INPUT_MOUSE, mi = new MOUSEINPUT { dx = -1, dwFlags = MOUSEEVENTF_MOVE } };
  SendInput(2, new[] { a, b }, Marshal.SizeOf(typeof(INPUT)));
}
'@

$created = $false
$mutex = [Threading.Mutex]::new($true, 'Local\keepalive-mouse', [ref]$created)
if (-not $created) { exit 0 }

while ($true) {
  if ([KeepAlive.Native]::IdleMs() -ge $IdleSeconds * 1000) { [KeepAlive.Native]::Nudge() }
  Start-Sleep -Seconds $CheckSeconds
}
