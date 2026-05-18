{ config, ... }:

{
  xdg.configFile = {
    "nvim".source = ../../../nvim/.config/nvim;
    "yazi".source = ../../../yazi/.config/yazi;
    "zellij".source = ../../../zellij/.config/zellij;
  };

  home.activation.createSharedDirs = config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
    mkdir -p $HOME/dev
    mkdir -p $HOME/bin
    mkdir -p $HOME/.ssh
    if [ -L $HOME/.config/lazygit ]; then
      rm $HOME/.config/lazygit
    fi
    mkdir -p $HOME/.config/lazygit
    chmod 700 $HOME/.ssh
  '';
}
