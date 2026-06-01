{ pkgs, ... }:

{
  services = {
    upower.enable = true;
    power-profiles-daemon.enable = true;
    fwupd.enable = true;
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
  ];
}
