{ pkgs, ... }:

{
  services.hardware.bolt.enable = true;
  hardware.i2c.enable = true;

  services.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    ddcutil
    lm_sensors
  ];
}
