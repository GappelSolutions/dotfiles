{ pkgs, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  networking.wireless.iwd.enable = true;
  networking.firewall.checkReversePath = "loose";

  environment.systemPackages = with pkgs; [
    networkmanagerapplet
    iw
    wirelesstools
  ];
}
