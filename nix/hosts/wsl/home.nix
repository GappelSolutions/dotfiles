{ lib, ... }:

{
  imports = [
    ../dev/home.nix
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
}
