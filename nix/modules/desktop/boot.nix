{ ... }:

{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
    extraEntries = {
      "omarchy-limine.conf" = ''
        title Omarchy
        sort-key omarchy
        efi /EFI/limine/limine_x64.efi
      '';
    };
  };

  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
}
