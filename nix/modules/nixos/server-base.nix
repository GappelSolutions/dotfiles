{ lib, pkgs, ... }:

let
  sshKeys = import ../shared/ssh-keys.nix;
in
{
  time.timeZone = "Europe/Zurich";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings.LC_CTYPE = "en_US.UTF-8";

  networking = {
    useDHCP = lib.mkDefault true;
    firewall = {
      checkReversePath = "loose";
      interfaces.tailscale0.allowedTCPPorts = [ 445 ];
    };
  };

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

    samba = {
      enable = true;
      openFirewall = false;
      settings = {
        global = {
          workgroup = "WORKGROUP";
          security = "user";
          "map to guest" = "Bad User";
          "server min protocol" = "SMB3";
        };
        dev = {
          path = "/home/cgpp/dev";
          browseable = "yes";
          writeable = "yes";
          "guest ok" = "yes";
          "force user" = "cgpp";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  users.users.cgpp = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = sshKeys.cgpp;
  };

  security.sudo.wheelNeedsPassword = false;

  programs.bash.shellAliases.rb = "sudo nixos-rebuild switch";
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    curl
    vim
    htop
    podman
    podman-compose
    kubectl
    minikube
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
