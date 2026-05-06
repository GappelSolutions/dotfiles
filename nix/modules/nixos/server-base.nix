{ lib, pkgs, ... }:

let
  sshKeys = import ../shared/ssh-keys.nix;
in
{
  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_CTYPE = "en_US.UTF-8";

  networking.useDHCP = lib.mkDefault true;
  networking.firewall.checkReversePath = "loose";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  users.users.cgpp = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys.cgpp;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.bash.shellAliases.rb = "sudo nixos-rebuild switch";

  environment.systemPackages = with pkgs; [
    curl
    vim
    htop
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
