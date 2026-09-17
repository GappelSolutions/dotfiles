{ ... }:

{
  imports = [
    ./common.nix
    ./hardware-configuration.nix
    ../../modules/nixos/vaultwarden.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.vaultwarden.publicDomain = "172.25.65.14";
}
