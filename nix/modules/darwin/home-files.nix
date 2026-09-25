{ config, pkgs, ... }:

let
  repo = ../../..;
in
{
  imports = [
    ../shared/home-agent-tools.nix
    ../shared/home-omp-caveman.nix
    ../shared/home-claude-config.nix
    ../shared/home-t3-config.nix
    ../shared/home-codex-config.nix
  ];

  xdg.configFile = {
    "nvim".source = repo + /nvim/.config/nvim;
    "alacritty".source = repo + /alacritty/.config/alacritty;
    "yazi".source = repo + /yazi/.config/yazi;
    "zellij".source = repo + /zellij/.config/zellij;
    "Code/User/settings.json".source = repo + /vscode/.config/Code/Users/settings.json;
  };

  home.file.".aerospace.toml".source = repo + /aerospace/.aerospace.toml;
  home.file.".vimrc".source = repo + /vim/.vimrc;
  # xdg.enable is off on this host, so lazygit and k9s read Application
  # Support, not ~/.config.
  home.file."Library/Application Support/lazygit/config.yml".source =
    repo + /lazygit/.config/lazygit/config.yml;
  home.file."Library/Application Support/k9s".source = repo + /k9s/.config/k9s;
  home.file.".ideavimrc".source = repo + /jetbrains/.ideavimrc;
  home.file."dev.smb.inetloc".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>URL</key>
      <string>smb://dev/dev</string>
    </dict>
    </plist>
  '';

  home.file.".local/bin/nerdfetch" = {
    source = ../../scripts/nerdfetch;
    executable = true;
  };

  home.file.".local/bin/zellij-copy" = {
    source = ../../scripts/zellij-copy;
    executable = true;
  };

  home.activation.createDirs = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/dev
    mkdir -p $HOME/bin
    mkdir -p $HOME/.zsh/completions
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
  '';
}
