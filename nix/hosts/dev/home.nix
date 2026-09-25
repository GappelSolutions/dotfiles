{ lib, ... }:

{
  imports = [
    ../../modules/shared/home-cli.nix
    ../../modules/shared/home-dotfiles.nix
    ../../modules/shared/home-claude-skills.nix
    ../../modules/shared/home-claude-config.nix
    ../../modules/shared/home-t3-config.nix
    ../../modules/shared/home-mprocs.nix
  ];

  home.username = "cgpp";
  home.homeDirectory = "/home/cgpp";

  # Headless VM: no keyring to back git-credential-manager, so plaintext
  # (~/.gcm/store) is the only store that works. mkDefault so hosts that
  # import this one (wsl) can pick something better.
  programs.git.settings.credential.credentialStore = lib.mkDefault "plaintext";
}
