{ enableCaelestia ? true, lib, ... }:

{
  imports = [
    ../../../modules/shared/home-cli.nix
    ../../../modules/shared/home-dotfiles.nix
    ../../../modules/desktop/home-hyprland.nix
    ../../../modules/desktop/home-owncloud.nix
    ../../../modules/desktop/home-shortcuts.nix
    ../../../modules/desktop/home-windows-vm.nix
  ] ++ lib.optionals enableCaelestia [
    ../../../modules/desktop/home-caelestia.nix
  ];

  home.username = "cgpp";
  home.homeDirectory = "/home/cgpp";

  xdg.configFile."alacritty".source =
    ../../../../alacritty/.config/alacritty;
}
