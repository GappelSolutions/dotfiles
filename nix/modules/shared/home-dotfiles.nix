{ config, ... }:

{
  xdg.configFile = {
    "nvim".source = ../../../nvim/.config/nvim;
    "lazygit/config.yml".source = ../../../lazygit/.config/lazygit/config.yml;
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
    mkdir -p $HOME/.config/lazygit
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
  '';

  home.activation.cleanupLegacyLazygitDir = config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
    if [ -L "$HOME/.config/lazygit" ]; then
      rm -f "$HOME/.config/lazygit"
      mkdir -p "$HOME/.config/lazygit"
    fi
  '';
}
