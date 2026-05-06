{ config, pkgs, ... }:

{
  home.stateVersion = "24.05";

  home.sessionVariables = {
    ZELLIJ_SOCKET_DIR = "/tmp/zellij";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.dotnet/tools"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  home.packages = with pkgs; [
    git
    zoxide
    fzf
    eza
    ripgrep
    fd
    bat
    delta
    yazi
    lazygit
    btop
    bottom
    zellij
    tmux
    nodejs
    bun
    gh
    jq
    unzip
    zip
    wget
    pandoc
    ffmpeg
    rustup
    sshpass
    neovim
  ];

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "Christian Gappel";
      user.email = "aichelberg2@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.lazygit.enable = true;

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -l --icons";
      lt = "eza --tree --level=1 --icons";
      lsa = "eza -a --icons";
      lla = "eza -al --icons";
      lta = "eza -a --tree --level=1 --icons";
      lg = "lazygit";
      vi = "nvim";
      rb = "sudo nixos-rebuild switch";
    };
    initExtra = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    '';
  };
}
