{ config, lib, osConfig ? { }, ... }:

{
  home = {
    stateVersion = "24.05";

    sessionVariables = {
      ZELLIJ_SOCKET_DIR = "/tmp/zellij";
      BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    }
    # Only where podman is the container runtime. cgpp-t14 runs the Docker
    # daemon, and pointing its docker CLI at a podman socket that does not
    # exist broke it.
    // lib.optionalAttrs (osConfig.virtualisation.podman.enable or false) {
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
