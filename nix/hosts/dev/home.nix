{ ... }:

{
  imports = [
    ../../modules/shared/home-cli.nix
    ../../modules/shared/home-dotfiles.nix
  ];

  home.username = "cgpp";
  home.homeDirectory = "/home/cgpp";
}
