{ ... }:

{
  imports = [
    ../../modules/nixos/server-base.nix
    ../../modules/nixos/wsl.nix
  ];

  networking.hostName = "wsl";

  wsl.enable = true;
  wsl.defaultUser = "cga";

  system.stateVersion = "24.05";
}
