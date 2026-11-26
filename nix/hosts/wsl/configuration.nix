{ pkgs, ... }:

{
  imports = [
    ../../modules/nixos/server-base.nix
    ../../modules/nixos/wsl.nix
  ];

  environment.systemPackages = [ pkgs.secretspec pkgs.devenv ];

  # T3 Code's preview browser: its own chrome-headless-shell (~/.t3/tools), run through nix-ld
  programs.nix-ld.libraries = with pkgs; [
    glib nspr nss atk at-spi2-atk at-spi2-core dbus expat libgbm libxkbcommon systemd alsa-lib
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXext xorg.libXfixes xorg.libXrandr
    xorg.libxcb
  ];

  # devenv binary cache — avoids rebuilding its closure from source.
  nix.settings = {
    extra-substituters = [ "https://devenv.cachix.org" ];
    extra-trusted-public-keys = [ "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=" ];
  };

  networking.hostName = "wsl";

  wsl.enable = true;
  wsl.defaultUser = "cgpp";
  # boot.binfmt.emulatedSystems (aarch64 cross-build, in wsl.nix) makes
  # systemd-binfmt own the binfmt_misc table, stomping Windows' own
  # WSLInterop registration. Re-register it ourselves or .exe calls break.
  wsl.interop.register = true;

  system.autoUpgrade = {
    enable = true;
    flake = "github:GappelSolutions/dotfiles?dir=nix#wsl";
    flags = [ "--update-input" "nixpkgs" ];
    dates = "weekly";
    randomizedDelaySec = "45min";
  };

  system.stateVersion = "24.05";
}
