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
      usb_compose_file="$HOME/.config/windows/docker-compose.usb.yml"
      log_file="$HOME/.cache/windows-rdp.log"
      compose_args=(--env-file "$env_file" -f "$compose_file")
      usb_requested=0

      mkdir -p "$(${pkgs.coreutils}/bin/dirname "$log_file")"
      if [ -t 1 ]; then
        exec > >(${pkgs.coreutils}/bin/tee -a "$log_file") 2>&1
      else
        exec >>"$log_file" 2>&1
      fi

      log() {
        printf '[%s] %s\n' "$(${pkgs.coreutils}/bin/date +%H:%M:%S)" "$*"
      }

      on_exit() {
        status=$?
        if [ "$status" -ne 0 ]; then
          log "failed with exit code $status"
          if [ -t 0 ]; then
            printf '\nPress Enter to close...'
            read -r _ || true
          fi
        fi
      }
      trap on_exit EXIT

      if [ "''${1:-}" = "--usb" ]; then
        usb_requested=1
        while [ ! -e /dev/ttyUSB0 ]; do
          log "CareLink adapter is missing at /dev/ttyUSB0"
          if [ ! -t 0 ]; then
            exit 1
          fi

          printf 'Plug in the CareLink adapter, then choose [r]etry, [c]ontinue without USB, or [a]bort: '
          read -r answer || answer=a
          case "$answer" in
            r|R|"")
              ;;
            c|C)
              log "continuing without CareLink USB; CareLink will not work"
              usb_requested=0
              break
              ;;
            a|A|q|Q)
              exit 1
              ;;
            *)
              log "unknown choice: $answer"
              ;;
          esac
        done
        if [ "$usb_requested" = 1 ]; then
          compose_args+=(-f "$usb_compose_file")
        fi
      fi

      log "starting Windows VM launcher"

      if [ -f "$env_file" ]; then
        set -a
        # shellcheck disable=SC1090
        source "$env_file"
        set +a
      fi

      container_running="$("${pkgs.docker}/bin/docker" inspect -f '{{.State.Running}}' nix-windows 2>/dev/null || true)"
      container_has_usb="$("${pkgs.docker}/bin/docker" inspect -f '{{range .HostConfig.Devices}}{{println .PathOnHost}}{{end}}{{range .Config.Env}}{{println .}}{{end}}' nix-windows 2>/dev/null | ${pkgs.gnugrep}/bin/grep -Eq '^/dev/ttyUSB0$|^ARGUMENTS=.*usb-serial' && printf yes || true)"
      if [ "$usb_requested" = 1 ] && [ "$container_running" = true ] && [ "$container_has_usb" != yes ]; then
        log "existing Windows VM lacks CareLink USB; recreating"
        "${pkgs.docker}/bin/docker" rm -f nix-windows
        container_running=""
      fi

      if [ "$container_running" = true ]; then
        log "container already running; reusing it"
      else
        log "starting Docker container"
        "${pkgs.docker}/bin/docker" compose "''${compose_args[@]}" up -d
      fi

      docker_logs_contain() {
        set +o pipefail
        "${pkgs.docker}/bin/docker" logs nix-windows 2>&1 | ${pkgs.gnugrep}/bin/grep -qi "$1"
        status=$?
        set -o pipefail
        return "$status"
      }

      wait_count=0
      log "waiting for Windows readiness"
      until docker_logs_contain "windows started successfully"; do
        ${pkgs.coreutils}/bin/sleep 2
        wait_count=$((wait_count + 1))
        if (( wait_count % 5 == 0 )); then
          log "still waiting ($((wait_count * 2))s)"
        fi
        if (( wait_count > 60 )); then
          log "timed out waiting; opening web console"
          exec ${pkgs.xdg-utils}/bin/xdg-open http://127.0.0.1:8006/
        fi
      done
      log "Windows is ready"

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

      log "opening RDP session"
      set +e
      ${pkgs.freerdp}/bin/xfreerdp /u:"$user" /p:"$password" /v:127.0.0.1:3389 -grab-keyboard /sound /microphone /clipboard /cert:ignore /title:"Windows VM" /dynamic-resolution /gfx:AVC444 /floatbar:sticky:off,default:visible,show:fullscreen $rdp_scale
      rdp_status=$?
      set -e
      log "RDP session closed with exit code $rdp_status; stopping Windows VM"
      ${pkgs.docker}/bin/docker rm -f nix-windows >/dev/null 2>&1 || true
    '';
  };

  home.file.".local/share/applications/windows-rdp.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Windows
    GenericName=Windows VM
    Comment=Start Dockurr Windows and connect over RDP
    Exec=${pkgs.uwsm}/bin/uwsm app -- ${config.home.homeDirectory}/.local/bin/windows-rdp
    Terminal=false
    Categories=System;RemoteAccess;
    Icon=${config.home.homeDirectory}/.local/share/icons/windows.png
  '';

  home.file.".local/share/applications/windows-rdp-usb.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Windows CareLink
    GenericName=Windows VM with CareLink
    Comment=Start Dockurr Windows with CareLink USB and connect over RDP
    Exec=${pkgs.uwsm}/bin/uwsm app -- ${config.home.homeDirectory}/.local/bin/windows-rdp --usb
    Terminal=false
    Categories=System;RemoteAccess;
    Icon=${config.home.homeDirectory}/.local/share/icons/windows.png
  '';

  home.shellAliases = {
    winup = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml up -d";
    winusb = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml -f ~/.config/windows/docker-compose.usb.yml up -d";
    windown = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml down";
    winlogs = "command docker compose --env-file ~/.config/windows/.env -f ~/.config/windows/docker-compose.yml logs -f";
    winrdp = "~/.local/bin/windows-rdp";
    winrdp-usb = "~/.local/bin/windows-rdp --usb";
    winssh = "ssh cgpp@127.0.0.1 -p 2222";
  };
}
