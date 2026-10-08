{ lib, pkgs, ... }:

{
  imports = [
    ../dev/home.nix
    ./p-backup.nix
  ];

  # Hand git credentials to the Windows GCM, which keeps them in Windows
  # Credential Manager (DPAPI-encrypted) and shares them with Windows-side
  # git -- instead of dev's plaintext ~/.gcm/store. wincredman is set
  # explicitly so GCM can never be steered into writing plaintext files on
  # the Windows side either. The escaped space is required: git runs the
  # helper string through the shell.
  programs.git.settings.credential = {
    helper = lib.mkForce "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
    credentialStore = "wincredman";
  };

  # Windows' vis (win-host/.local/bin): vis has no native Windows build and its plugins, language
  # servers and pickers live here, so Windows runs this one through wsl.exe, which costs ~150 ms
  # (Windows nvim takes 8 s). The caller's Windows paths become WSL ones; relative paths already
  # resolve, wsl.exe starts in the caller's directory.
  home.packages = [
    (pkgs.writeShellScriptBin "vis-win" ''
      for arg; do
        shift
        case $arg in
          [+-]*) ;;
          [A-Za-z]:[\\/]* | \\\\*) arg=$(wslpath -u "$arg") ;;
          *\\*) arg=''${arg//\\//} ;;
        esac
        set -- "$@" "$arg"
      done
      exec vis "$@"
    '')
  ];
}
