{
  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      settings = {
        user.name = "Christian Gappel";
        user.email = "aichelberg2@gmail.com";
        init.defaultBranch = "main";
        push.autoSetupRemote = true;
        pull.rebase = true;
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    fzf.enable = true;

    bat = {
      enable = true;
      config.theme = "TwoDark";
    };
  };
}
