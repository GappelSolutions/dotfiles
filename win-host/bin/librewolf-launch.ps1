param(
    [string]$Url
)

$lwExe = "$env:LOCALAPPDATA\Programs\LibreWolf\LibreWolf\librewolf.exe"

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class LibreWolfFocus {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hWnd);
}
"@

function Find-LibreWolfHwnd {
    # Walk komorebi's state tree looking for the librewolf.exe window entry so we
    # get its real hwnd even while it's cloaked on another workspace.
    try {
        $state = komorebic state | ConvertFrom-Json -Depth 100
    } catch { return $null }

    $found = $null
    function Walk($node) {
        if ($null -eq $node) { return }
        if ($node -is [System.Collections.IEnumerable] -and $node -isnot [string]) {
            foreach ($item in $node) { Walk $item }
            return
        }
        if ($node.PSObject.Properties.Name -contains 'exe' -and $node.exe -eq 'librewolf.exe') {
            $script:found = $node.hwnd
            return
        }
        foreach ($prop in $node.PSObject.Properties) {
            Walk $prop.Value
        }
    }
    Walk $state
    return $script:found
}

function Force-Focus($hwnd) {
    if (-not $hwnd) { return }
    $ptr = [IntPtr]$hwnd
    $fgWin = [LibreWolfFocus]::GetForegroundWindow()
    $fgThread = 0
    [LibreWolfFocus]::GetWindowThreadProcessId($fgWin, [ref]$fgThread) | Out-Null
    $curThread = [LibreWolfFocus]::GetCurrentThreadId()
    [LibreWolfFocus]::AttachThreadInput($curThread, $fgThread, $true) | Out-Null
    if ([LibreWolfFocus]::IsIconic($ptr)) { [LibreWolfFocus]::ShowWindow($ptr, 9) | Out-Null }
    [LibreWolfFocus]::SetForegroundWindow($ptr) | Out-Null
    [LibreWolfFocus]::AttachThreadInput($curThread, $fgThread, $false) | Out-Null
}

# Only count instances with a real window: headless (marionette) librewolf
# processes have none and komorebi can't focus them.
$running = Get-Process librewolf -ErrorAction SilentlyContinue | Where-Object MainWindowHandle -ne 0

if ($running) {
    komorebic eager-focus librewolf.exe | Out-Null
    Start-Sleep -Milliseconds 200
    $hwnd = Find-LibreWolfHwnd
    Force-Focus $hwnd
}

if ($Url) {
    Start-Process -FilePath $lwExe -ArgumentList @('-osint', '-url', $Url)
} else {
    Start-Process -FilePath $lwExe
}
