{ pkgs, ... }:

{
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_CTYPE = "en_US.UTF-8";

  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    tailscale.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
  };

  fonts.packages = [
    pkgs.inter
    pkgs.nerd-fonts.fira-code
  ];

  environment.systemPackages = with pkgs; [
    home-manager
    man-pages
    man-pages-posix
  ];
}
