{ config, lib, pkgs, ... }:

{
  home = {
    stateVersion = "24.05";

    sessionVariables = {
      ZELLIJ_SOCKET_DIR = "/tmp/zellij";
      BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    } // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      DOCKER_HOST = "unix://\${XDG_RUNTIME_DIR}/podman/podman.sock";
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
