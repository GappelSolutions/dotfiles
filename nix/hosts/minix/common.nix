{ pkgs, ... }:

let
  sshKeys = import ../../modules/shared/ssh-keys.nix;
in
{
  networking.hostName = "minix";

  boot.kernelParams = [ "nomodeset" ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  users.users.cga = {
    isNormalUser = true;
    extraGroups = [ "wheel" "podman" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = sshKeys.cgpp;
    initialPassword = "docker";
  };

  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [ vim git claude-code ];

  system.stateVersion = "25.11";
}
