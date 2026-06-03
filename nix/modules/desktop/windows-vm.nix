{ pkgs, ... }:

let
  cgppWindows = pkgs.writeShellApplication {
    name = "cgpp-windows";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      docker
      findutils
      freerdp
      gawk
      gnugrep
      gnused
      gum
      jq
      nix
      rsync
      util-linux
      xdg-utils
    ];
    text = builtins.readFile ../../scripts/cgpp-windows;
  };

  windowsRdp = pkgs.writeShellScriptBin "windows-rdp" ''
    set -euo pipefail

    user_config_dir="$HOME/.config/windows"
    env_file="$user_config_dir/.env"
    compose_file="/etc/windows-vm/docker-compose.yml"
    usb_compose_file="/etc/windows-vm/docker-compose.usb.yml"
    log_file="$HOME/.cache/windows-rdp.log"
    compose_args=(-f "$compose_file")
    usb_requested=0

    mkdir -p "$user_config_dir" "$(${pkgs.coreutils}/bin/dirname "$log_file")"
    if [ ! -e "$env_file" ]; then
      printf 'WINDOWS_USERNAME=cgpp\n' > "$env_file"
      chmod 600 "$env_file"
    fi
    compose_args=(--env-file "$env_file" "''${compose_args[@]}")

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
  winrdp = pkgs.writeShellScriptBin "winrdp" ''
    exec ${windowsRdp}/bin/windows-rdp "$@"
  '';
  winrdpUsb = pkgs.writeShellScriptBin "winrdp-usb" ''
    exec ${windowsRdp}/bin/windows-rdp --usb "$@"
  '';
  winup = pkgs.writeShellScriptBin "winup" ''
    env_file="$HOME/.config/windows/.env"
    mkdir -p "$HOME/.config/windows"
    if [ ! -e "$env_file" ]; then
      printf 'WINDOWS_USERNAME=cgpp\n' > "$env_file"
      chmod 600 "$env_file"
    fi
    exec ${pkgs.docker}/bin/docker compose --env-file "$env_file" -f /etc/windows-vm/docker-compose.yml up -d
  '';
  winusb = pkgs.writeShellScriptBin "winusb" ''
    env_file="$HOME/.config/windows/.env"
    mkdir -p "$HOME/.config/windows"
    if [ ! -e "$env_file" ]; then
      printf 'WINDOWS_USERNAME=cgpp\n' > "$env_file"
      chmod 600 "$env_file"
    fi
    exec ${pkgs.docker}/bin/docker compose --env-file "$env_file" -f /etc/windows-vm/docker-compose.yml -f /etc/windows-vm/docker-compose.usb.yml up -d
  '';
  windown = pkgs.writeShellScriptBin "windown" ''
    exec ${pkgs.docker}/bin/docker rm -f nix-windows
  '';
  winlogs = pkgs.writeShellScriptBin "winlogs" ''
    env_file="$HOME/.config/windows/.env"
    mkdir -p "$HOME/.config/windows"
    if [ ! -e "$env_file" ]; then
      printf 'WINDOWS_USERNAME=cgpp\n' > "$env_file"
      chmod 600 "$env_file"
    fi
    exec ${pkgs.docker}/bin/docker compose --env-file "$env_file" -f /etc/windows-vm/docker-compose.yml logs -f
  '';
in

{
  virtualisation.docker.enable = true;

  users.users.cgpp.extraGroups = [
    "docker"
    "kvm"
    "dialout"
  ];

  users.users.wife.extraGroups = [
    "docker"
    "kvm"
    "dialout"
  ];

  boot.kernelModules = [
    "kvm-intel"
    "tun"
    "cp210x"
    "usbserial"
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", ATTRS{idProduct}=="ea60", GROUP="dialout", MODE="0660", SYMLINK+="medtronic-carelink"
  '';

  environment.etc."windows-vm/docker-compose.yml".source =
    ../../../windows/.config/windows/docker-compose.yml;

  environment.etc."windows-vm/docker-compose.usb.yml".source =
    ../../../windows/.config/windows/docker-compose.usb.yml;

  environment.systemPackages = with pkgs; [
    docker-compose
    cgppWindows
    freerdp
    windowsRdp
    winrdp
    winrdpUsb
    winup
    winusb
    windown
    winlogs
  ];
}
