{ pkgs, ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.trackpoint.enable = true;
  services.hardware.bolt.enable = true;
  hardware.i2c.enable = true;

  services.libinput = {
    enable = true;
    mouse.middleEmulation = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
      disableWhileTyping = true;
      middleEmulation = true;
    };
  };

  environment.systemPackages = with pkgs; [
    ddcutil
    lm_sensors
    libinput
  ];
}
