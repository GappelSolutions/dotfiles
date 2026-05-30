{ pkgs, ... }:

{
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fwupd.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    powertop
  ];
}
