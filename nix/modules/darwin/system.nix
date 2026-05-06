{ pkgs, ... }:

{
  # Determinate Nix manages the daemon on this host.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.variables.EDITOR = "nvim";
  environment.systemPackages = with pkgs; [
    vim
    curl
  ];

  security.pam.services.sudo_local.touchIdAuth = true;

  system.primaryUser = "cgpp";
  system.stateVersion = 4;

  users.users.cgpp = {
    name = "cgpp";
    home = "/Users/cgpp";
  };
}
