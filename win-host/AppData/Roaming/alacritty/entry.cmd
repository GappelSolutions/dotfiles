@echo off
choice /c 12 /n /m "1) Windows  2) WSL: "
if errorlevel 2 (
  wsl.exe --cd ~
) else (
  pwsh.exe -NoLogo -NoExit -Command "zellij attach welcome; if (!$?) { zellij --session welcome }"
)
