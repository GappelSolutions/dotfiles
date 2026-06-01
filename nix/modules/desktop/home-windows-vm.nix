{ config, pkgs, ... }:

{
  xdg.configFile."windows/docker-compose.yml".source =
    ../../../windows/.config/windows/docker-compose.yml;

  xdg.configFile."windows/docker-compose.usb.yml".source =
    ../../../windows/.config/windows/docker-compose.usb.yml;

  xdg.configFile."windows/.env.example".source =
    ../../../windows/.config/windows/.env.example;

  xdg.dataFile."icons/windows-vm.svg".source =
    ../../../windows/.local/share/icons/windows-vm.svg;

  xdg.dataFile."icons/windows.png".source =
    ../../../windows/.local/share/icons/windows.png;

  home.activation.createWindowsVmDirs =
    config.lib.dag.entryBefore [ "checkLinkTargets" ] ''
      mkdir -p $HOME/.config/windows
      mkdir -p $HOME/.windows
      mkdir -p $HOME/Windows
      chmod 700 $HOME/.config/windows
      if [ ! -e $HOME/.config/windows/.env ]; then
        printf 'WINDOWS_USERNAME=cgpp\n' > $HOME/.config/windows/.env
        chmod 600 $HOME/.config/windows/.env
      fi
    '';

  home.file.".local/bin/windows-rdp" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      env_file="$HOME/.config/windows/.env"
      compose_file="$HOME/.config/windows/docker-compose.yml"
      log_file="$HOME/.cache/windows-rdp.log"

      mkdir -p "$(${pkgs.coreutils}/bin/dirname "$log_file")"
      exec >>"$log_file" 2>&1
      echo "[$(${pkgs.coreutils}/bin/date --iso-8601=seconds)] starting windows-rdp"

      if [ -f "$env_file" ]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
      fi

      "${pkgs.docker}/bin/docker" compose --env-file "$env_file" -f "$compose_file" up -d
      ${pkgs.libnotify}/bin/notify-send "Windows" "Starting VM and waiting for RDP..."

      wait_count=0
      until "${pkgs.docker}/bin/docker" logs omarchy-windows 2>&1 | ${pkgs.gnugrep}/bin/grep -qi "windows started successfully"; do
        ${pkgs.coreutils}/bin/sleep 2
        wait_count=$((wait_count + 1))
        if (( wait_count > 60 )); then
          ${pkgs.libnotify}/bin/notify-send "Windows" "Still installing. Opening web console."
          echo "Timed out waiting for Docker log readiness; opening web console"
          exec ${pkgs.xdg-utils}/bin/xdg-open http://127.0.0.1:8006/
        fi
      done

      hypr_scale="$(${pkgs.hyprland}/bin/hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused == true) | .scale' 2>/dev/null || true)"
      scale_percent="$(printf '%s\n' "''${hypr_scale:-1}" | ${pkgs.gawk}/bin/awk '{print int($1 * 100)}')"
      rdp_scale=""
      if (( scale_percent >= 170 )); then
        rdp_scale="/scale:180"
      elif (( scale_percent >= 130 )); then
        rdp_scale="/scale:140"
      fi

      user="''${WINDOWS_USERNAME:-cgpp}"
      password="''${WINDOWS_PASSWORD:-admin}"

      ${pkgs.libnotify}/bin/notify-send "Windows" "Opening RDP session..."
      ${pkgs.freerdp}/bin/xfreerdp /u:"$user" /p:"$password" /v:127.0.0.1:3389 -grab-keyboard /sound /microphone /clipboard /cert:ignore /title:"Windows VM" /dynamic-resolution /gfx:AVC444 /floatbar:sticky:off,default:visible,show:fullscreen $rdp_scale

      echo "RDP session closed. Stopping Windows VM..."
      "${pkgs.docker}/bin/docker" compose --env-file "$env_file" -f "$compose_file" down
    '';
  };

  xdg.desktopEntries.windows-rdp = {
    name = "Windows";
    genericName = "Windows VM";
    comment = "Start Dockurr Windows and connect over RDP";
    exec = "${pkgs.uwsm}/bin/uwsm app -- ${config.home.homeDirectory}/.local/bin/windows-rdp";
    terminal = false;
    categories = [ "System" "RemoteAccess" ];
    icon = "${config.home.homeDirectory}/.local/share/icons/windows.png";
  };

  home.shellAliases = {
    winup = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml up -d";
    winusb = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml -f ~/.config/windows/docker-compose.usb.yml up -d";
    windown = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml down";
    winlogs = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml logs -f";
    winrdp = "~/.local/bin/windows-rdp";
    winssh = "ssh cgpp@127.0.0.1 -p 2222";
  };
}
