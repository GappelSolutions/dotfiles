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

  # gnome-keyring runs on this host (modules/desktop/hyprland.nix).
  programs.git.settings.credential.credentialStore = "secretservice";

  # Only this host has a lite variant. Plain `rb` (shared) picks the
  # nixosConfigurations attr matching the hostname.
  programs.zsh.shellAliases.rbl =
    "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix-lite";
  programs.bash.shellAliases.rbl =
    "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix-lite";
}
