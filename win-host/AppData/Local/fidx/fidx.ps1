# fidx - prebuilt file lists for slow (network) drives, consumed by the yazi `fidx` plugin.
# Crawls each drive once with fd (many threads to hide SMB latency) and writes
# %LOCALAPPDATA%\fidx\<Drive>.txt, so fuzzy search becomes instant instead of re-walking the share.
#
#   fidx.ps1                      # index the default drives
#   fidx.ps1 P Y                  # index specific drives
#   fidx.ps1 -MaxAgeMinutes 60    # skip drives whose index is younger than that (used by the scheduled task)
#   fidx.ps1 Y -Force             # accept a list much smaller than the previous one
param(
    [string[]]$Drives = @('P', 'Y'),
    [int]$Threads = 32,
    [int]$MaxAgeMinutes = 0,
    [switch]$Force               # accept a much smaller list (e.g. after a big cleanup on the share)
)

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$log = Join-Path $dir 'fidx.log'
$excludes = '~snapshot', '.snapshot', '$RECYCLE.BIN', 'System Volume Information', 'Thumbs.db', '~$*'

function Log($msg) {
    $line = '{0:yyyy-MM-dd HH:mm:ss}  {1}' -f (Get-Date), $msg
    $line
    Add-Content -LiteralPath $log -Value $line
}

# logon, VPN-connect and interval triggers can fire together: only one crawl at a time
$mutex = [Threading.Mutex]::new($false, 'Local\fidx')
if (-not $mutex.WaitOne(0)) { Log 'another fidx run is active, exiting'; return }

try {
    foreach ($d in $Drives) {
        $d = $d.TrimEnd(':', '\').ToUpper()
        $root = "${d}:\"
        $out = Join-Path $dir "$d.txt"
        $tmp = "$out.tmp"

        $old = Get-Item -LiteralPath $out -ErrorAction Ignore
        if ($old -and $MaxAgeMinutes -and $old.LastWriteTime -gt (Get-Date).AddMinutes(-$MaxAgeMinutes)) { continue }
        if (-not (Test-Path -LiteralPath $root)) { Log "$root not reachable, skipping"; continue }

        # --path-separator: fd switches to '/' when MSYSTEM is set (Git Bash), which yazi can't open.
        $fdArgs = @('--hidden', '--no-ignore', '--color=never', '--path-separator=\', "--threads=$Threads") +
                  ($excludes | ForEach-Object { "--exclude=$_" }) + @('.', $root)

        $sw = [Diagnostics.Stopwatch]::StartNew()
        # pwsh 7.4+ redirects native output byte-for-byte; permission-denied dirs only go to stderr.
        & fd @fdArgs 2>$null > $tmp
        $n = [Linq.Enumerable]::Count([IO.File]::ReadLines($tmp))

        # a VPN drop mid-crawl leaves a truncated list: don't let it replace a good index
        $prev = if ($old) { [Linq.Enumerable]::Count([IO.File]::ReadLines($out)) } else { 0 }
        if ($n -eq 0 -or (-not $Force -and $n -lt $prev * 0.8)) {
            Log ('{0}: only {1:N0} entries (previous {2:N0}, fd exit {3}), keeping old index' -f $root, $n, $prev, $LASTEXITCODE)
            Remove-Item -LiteralPath $tmp
            continue
        }

        Move-Item -LiteralPath $tmp -Destination $out -Force
        Log ('{0}: {1:N0} entries in {2:N1}s' -f $root, $n, $sw.Elapsed.TotalSeconds)
    }
} finally {
    $mutex.ReleaseMutex()
}
