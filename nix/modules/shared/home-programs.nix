{ pkgs, ... }:

{
  home.packages = [ pkgs.git-credential-manager ];

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
        credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
        credential."https://dev.azure.com".useHttpPath = true;
        credential.credentialStore = "plaintext";
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

    fzf = {
      enable = true;
      historyWidget.command = "";
    };

    bat = {
      enable = true;
      config.theme = "TwoDark";
    };
  };
}
