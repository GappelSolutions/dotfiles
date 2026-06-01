{ pkgs, ... }:

{
  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    wireless.iwd.enable = true;
    firewall.checkReversePath = "loose";
  };

  environment.systemPackages = with pkgs; [
    networkmanager
    networkmanagerapplet
    iwd
    iw
    wirelesstools
  ];
}
