{ config, ... }:

{
  xdg.configFile."windows/docker-compose.yml".source =
    ../../../windows/.config/windows/docker-compose.yml;

  xdg.configFile."windows/.env.example".source =
    ../../../windows/.config/windows/.env.example;

  home.activation.createWindowsVmDirs =
    config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
      mkdir -p $HOME/.config/windows
      mkdir -p $HOME/.windows
      mkdir -p $HOME/Windows
      chmod 700 $HOME/.config/windows
    '';

  home.shellAliases = {
    winup = "docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml up -d";
    windown = "docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml down";
    winlogs = "docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml logs -f";
    winssh = "ssh cgpp@127.0.0.1 -p 2222";
  };
}
