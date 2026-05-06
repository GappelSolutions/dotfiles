{ ... }:

{
  imports = [
    ../../modules/darwin/home-packages.nix
    ../../modules/darwin/home-shell.nix
    ../../modules/darwin/home-programs.nix
    ../../modules/darwin/home-launchd.nix
    ../../modules/darwin/home-files.nix
  ];

  home.username = "cgpp";
  home.homeDirectory = "/Users/cgpp";
  home.stateVersion = "24.05";
}
