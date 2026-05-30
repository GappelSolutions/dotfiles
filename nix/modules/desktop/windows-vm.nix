{ pkgs, ... }:

{
  virtualisation.docker.enable = true;

  users.users.cgpp.extraGroups = [
    "docker"
    "kvm"
    "dialout"
  ];

  boot.kernelModules = [
    "kvm-intel"
    "tun"
    "cp210x"
    "usbserial"
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", GROUP="dialout", MODE="0660", SYMLINK+="medtronic-carelink"
  '';

  environment.systemPackages = with pkgs; [
    docker-compose
    freerdp
  ];
}
