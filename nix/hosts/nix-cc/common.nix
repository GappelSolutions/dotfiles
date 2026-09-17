{ pkgs, ... }:

let
  sshKeys = import ../../modules/shared/ssh-keys.nix;
in
{
  networking.hostName = "nix-cc";

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

  users.users.cga = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = sshKeys.cgpp ++ [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHflEu2znFC9TVaJ4dfVGzNZF0k/qmFWgJMYaIVCBe3r cgpp@wsl-box"
    ];
  };

  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [ vim git claude-code ];

  system.stateVersion = "25.11";
}
