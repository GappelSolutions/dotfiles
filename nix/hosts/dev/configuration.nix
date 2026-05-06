{ ... }:

{
  imports = [
    ../../modules/nixos/server-base.nix
    ./hardware-configuration.nix
  ];

  networking.hostName = "dev";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  system.stateVersion = "25.11";
}
