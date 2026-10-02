@echo off
rem WSL's vis (vis-win in nix/hosts/wsl/home.nix). wsl.exe -e skips the NixOS environment,
rem its /bin/sh sets it up.
wsl.exe -e sh -c "exec vis-win \"$@\"" vis %*
