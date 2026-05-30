{ ... }:

{
  imports = [
    ../../../modules/shared/home-cli.nix
    ../../../modules/shared/home-dotfiles.nix
    ../../../modules/desktop/home-caelestia.nix
    ../../../modules/desktop/home-hyprland.nix
    ../../../modules/desktop/home-shortcuts.nix
    ../../../modules/desktop/home-windows-vm.nix
  ];

  home.username = "cgpp";
  home.homeDirectory = "/home/cgpp";
}
