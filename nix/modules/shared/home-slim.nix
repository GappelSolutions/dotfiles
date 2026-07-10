{ pkgs, ... }:

{
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    zoxide
    yazi
    lazydocker
    lazygit
    bottom
  ];

  xdg.configFile."yazi".source = ../../../yazi/.config/yazi;
  xdg.configFile."lazygit/config.yml".source = ../../../lazygit/.config/lazygit/config.yml;
  home.file.".vimrc".source = ../../../vim/.vimrc;

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      settings = {
        user.name = "Christian Gappel";
        user.email = "aichelberg2@gmail.com";
        init.defaultBranch = "main";
        pull.rebase = true;
      };
    };

    atuin = {
      enable = true;
      enableZshIntegration = true;
      settings = {
        auto_sync = false;
        update_check = false;
      };
    };

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      shellAliases = {
        docker = "podman";
        dcu = "podman-compose up -d --build";
        dcd = "podman-compose down";
        ld = "lazydocker";
        lg = "lazygit";
        vi = "vim";
        py = "python3";
        pip = "pip3";
        btm = "bottom";
      };

      initContent = ''
        eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
        export VISUAL="vim"
        export EDITOR="vim"
      '';
    };
  };
}
