{ config, ... }:

{
  xdg.configFile = {
    "nvim".source = ../../../nvim/.config/nvim;
    "lazygit".source = ../../../lazygit/.config/lazygit;
    "yazi".source = ../../../yazi/.config/yazi;
    "zellij".source = ../../../zellij/.config/zellij;
  };

  home.activation.createSharedDirs = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p $HOME/dev
    mkdir -p $HOME/bin
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
  '';
}
