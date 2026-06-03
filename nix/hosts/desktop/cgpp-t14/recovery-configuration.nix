{ config, lib, modulesPath, pkgs, ... }:

let
  sshKeys = import ../../../modules/shared/ssh-keys.nix;
in
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../../../modules/desktop/base.nix
    ../../../modules/desktop/boot.nix
    ../../../modules/desktop/networking.nix
    ../../../modules/desktop/hyprland.nix
    ../../../modules/desktop/audio.nix
    ../../../modules/desktop/bluetooth.nix
    ../../../modules/desktop/printing.nix
    ../../../modules/desktop/power.nix
    ../../../modules/desktop/tablet.nix
    ../../../modules/desktop/hardware-lenovo.nix
    ../../../modules/desktop/windows-vm.nix
  ];

  networking.hostName = "cgpp-t14-nix";

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "nvme"
    "usb_storage"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.kernelModules = [ "kvm-intel" ];
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  users.users.cgpp = {
    isNormalUser = true;
    initialPassword = "ASDQWEasdqweASDQWE123";
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

  users.users.wife = {
    isNormalUser = true;
    description = "Wife";
    initialPassword = "ASDQWEasdqweASDQWE123";
    extraGroups = [
      "networkmanager"
      "audio"
      "video"
      "input"
      "lp"
      "scanner"
    ];
    shell = pkgs.zsh;
  };

  security.sudo.wheelNeedsPassword = false;
  programs.zsh.enable = true;

  services.xserver.xkb = {
    layout = "de,us";
    options = "grp:alts_toggle";
  };

  console.keyMap = "de";

  environment.systemPackages = with pkgs; [
    git
    gh
    codex
    curl
    wget
    vim
    neovim
    pciutils
    usbutils
  ];

  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
