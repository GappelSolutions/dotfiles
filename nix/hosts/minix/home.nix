{ ... }:

{
  imports = [
    ../../modules/shared/home-slim.nix
  ];

  home.username = "cga";
  home.homeDirectory = "/home/cga";
}
