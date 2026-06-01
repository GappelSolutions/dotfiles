{ pkgs, ... }:

let
  huiontablet = pkgs.callPackage ../../pkgs/huiontablet/package.nix { };
in
{
  boot = {
    blacklistedKernelModules = [ "hid_uclogic" ];
    kernelModules = [
      "uinput"
      "uhid"
    ];
  };

  environment.systemPackages = with pkgs; [
    huiontablet
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="256c", ATTR{idProduct}=="0064", TAG+="uaccess", GROUP="input", MODE="0660"
    KERNEL=="hidraw*", ATTRS{idVendor}=="256c", ATTRS{idProduct}=="0064", TAG+="uaccess", GROUP="input", MODE="0660"
    KERNEL=="hiddev*", SUBSYSTEM=="usbmisc", ATTRS{idVendor}=="256c", ATTRS{idProduct}=="0064", TAG+="uaccess", GROUP="input", MODE="0660"
    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", GROUP="input", MODE="0660"
    KERNEL=="uhid", SUBSYSTEM=="misc", TAG+="uaccess", GROUP="input", MODE="0660"
  '';
}
