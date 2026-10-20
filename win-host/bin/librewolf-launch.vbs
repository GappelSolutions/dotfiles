' Silent launcher: runs librewolf-launch.ps1 with zero visible window (0 = hidden),
' unlike calling powershell.exe directly which can still flash a console.
Set args = WScript.Arguments
url = ""
If args.Count > 0 Then
    url = args(0)
End If

Set shell = CreateObject("WScript.Shell")
scriptPath = shell.ExpandEnvironmentStrings("%USERPROFILE%") & "\bin\librewolf-launch.ps1"
cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File """ & scriptPath & """"
If url <> "" Then
    cmd = cmd & " -Url """ & url & """"
End If

shell.Run cmd, 0, False
