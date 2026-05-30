{ inputs, pkgs, ... }:

let
  sshKeys = import ../../../modules/shared/ssh-keys.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../../modules/desktop/base.nix
    ../../../modules/desktop/boot.nix
    ../../../modules/desktop/networking.nix
    ../../../modules/desktop/hyprland.nix
    ../../../modules/desktop/audio.nix
    ../../../modules/desktop/bluetooth.nix
    ../../../modules/desktop/printing.nix
    ../../../modules/desktop/power.nix
    ../../../modules/desktop/hardware-lenovo.nix
    ../../../modules/desktop/windows-vm.nix
  ];

  networking.hostName = "cgpp-t14-nix";

  users.users.cgpp = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "input"
      "lp"
      "scanner"
      "i2c"
      "dialout"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = sshKeys.cgpp;
  };

  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  environment.systemPackages = [
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ (with pkgs; [
    git
    gh
    codex
    curl
    wget
    vim
    neovim
    networkmanager
    pciutils
    usbutils
  ]);

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
