{ config, ... }:

{
  xdg.configFile = {
    "nvim".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/misc/dotfiles/nvim/.config/nvim";
    "lazygit".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dev/misc/dotfiles/lazygit/.config/lazygit";
    "yazi".source = ../../../yazi/.config/yazi;
    "zellij".source = ../../../zellij/.config/zellij;
  };

  home.file.".local/bin/nerdfetch" = {
    source = ../../scripts/nerdfetch;
    executable = true;
  };

  home.activation.createSharedDirs = config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p $HOME/dev
    mkdir -p $HOME/bin
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
  '';
}
