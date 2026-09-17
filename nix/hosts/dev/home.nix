{ ... }:

{
  imports = [
    ../../modules/shared/home-cli.nix
    ../../modules/shared/home-dotfiles.nix
    ../../modules/shared/home-claude-skills.nix
    ../../modules/shared/home-claude-config.nix
    ../../modules/shared/home-t3code-config.nix
    ../../modules/shared/home-mprocs.nix
  ];

  home.username = "cgpp";
  home.homeDirectory = "/home/cgpp";
}
