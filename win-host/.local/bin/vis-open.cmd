@echo off
rem Explorer's "Open with" vis (win-host/register-vis.ps1): vis starts in the file's folder, like
rem it would from a shell there.
cd /d "%~dp1"
"%~dp0vis.cmd" "%~nx1"
