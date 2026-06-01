{ config, ... }:

{
  home = {
    stateVersion = "24.05";

    sessionVariables = {
      ZELLIJ_SOCKET_DIR = "/tmp/zellij";
      BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.bun/bin"
      "${config.home.homeDirectory}/bin"
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/.dotnet/tools"
      "${config.home.homeDirectory}/.cargo/bin"
    ];
  };

  manual.manpages.enable = false;
}
