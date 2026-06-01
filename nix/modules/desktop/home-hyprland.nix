{ config, enableCaelestia ? true, lib, pkgs, ... }:

let
  cursorName = "catppuccin-mocha-sky-cursors";
  cursorSize = 24;
  desktopIconOverrides = pkgs.runCommand "desktop-icon-overrides" { } ''
    install -D -m 0644 \
      ${pkgs.networkmanagerapplet}/share/icons/hicolor/scalable/apps/nm-device-wired.svg \
      $out/share/icons/hicolor/scalable/apps/preferences-system-network.svg

    install -D -m 0644 \
      ${pkgs.yazi}/share/pixmaps/yazi.png \
      $out/share/icons/hicolor/256x256/apps/yazi.png
  '';
in
{
  home.packages = with pkgs; [
    desktopIconOverrides
    alacritty
    catppuccin-cursors.mochaSky
    cliphist
    flameshot
    hyprpicker
    hyprsunset
    libreoffice-fresh
    localsend
    networkmanagerapplet
    obsidian
    pavucontrol
    spotify
    terminaltexteffects
    wl-clipboard
    wtype
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      "$mod" = "SUPER";

      env = [
        "XCURSOR_THEME,${cursorName}"
        "XCURSOR_SIZE,${toString cursorSize}"
        "HYPRCURSOR_THEME,${cursorName}"
        "HYPRCURSOR_SIZE,${toString cursorSize}"
      ];

      monitor = [
        ",preferred,auto,1.0"
      ];

      input = {
        kb_layout = "de,us";
        kb_options = "compose:caps";
        repeat_rate = 40;
        repeat_delay = 200;
        follow_mouse = 1;
        numlock_by_default = true;
        sensitivity = 0.0;
        touchpad = {
          natural_scroll = true;
          tap-to-click = true;
          scroll_factor = 0.4;
        };
      };

      general = {
        gaps_in = 3;
        gaps_out = 6;
        border_size = 1;
      };

      decoration.rounding = 8;

      windowrule = [
        "fullscreen on, match:class org.omarchy.screensaver"
        "float on, match:class org.omarchy.screensaver"
        "animation slide, match:class org.omarchy.screensaver"
        "match:class ^(ueberzugpp_.*)$, float 1, no_focus 1, no_initial_focus 1, no_anim 1"
      ];

      animations = {
        enabled = true;
        bezier = [
          "snappy, 0.15, 0.85, 0.25, 1.0"
          "quickExit, 0.30, 0.00, 0.60, 1.00"
        ];
        animation = [
          "global, 1, 4.5, snappy"
          "windows, 1, 4, snappy, popin 88%"
          "windowsOut, 1, 2.5, quickExit, popin 92%"
          "windowsMove, 1, 3.5, snappy"
          "fade, 1, 3, quickExit"
          "fadeOut, 1, 2, quickExit"
          "fadeLayersOut, 1, 2, quickExit"
          "workspaces, 1, 4.5, snappy"
          "workspacesOut, 1, 3, snappy"
          "specialWorkspaceOut, 1, 3, snappy"
        ];
      };

      exec-once = [
        "hyprctl setcursor ${cursorName} ${toString cursorSize}"
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
        "nm-applet --indicator"
        "swaync"
      ] ++ lib.optionals enableCaelestia [
        "systemctl --user start caelestia.service"
      ];

      bind = [
        "$mod, RETURN, exec, alacritty"
        "$mod CTRL, K, exec, hyprctl switchxkblayout all next"
        "SUPER CTRL, K, exec, hyprctl switchxkblayout all next"
        "$mod CTRL, code:45, exec, hyprctl switchxkblayout all next"
        "$mod, T, exec, alacritty"
        "$mod, M, exec, ~/.local/bin/wife-help"
        "$mod, S, exec, zen"
        "$mod, E, exec, alacritty -e yazi"
        "$mod, N, exec, pgrep -x hyprsunset && pkill -x hyprsunset || hyprsunset -t 4000"
        "$mod, B, exec, systemctl suspend"
        "$mod, O, exec, obsidian"
        "$mod, P, exec, xdg-open https://www.perplexity.ai/"
        "$mod, A, exec, xdg-open https://t3.chat/"
        "$mod, V, exec, caelestia clipboard"
        "$mod, Q, killactive"
        "$mod, F, fullscreen, 0"
        "$mod, W, togglefloating"
        "$mod, TAB, workspace, previous"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"
        "$mod SHIFT, H, swapwindow, l"
        "$mod SHIFT, J, swapwindow, d"
        "$mod SHIFT, K, swapwindow, u"
        "$mod SHIFT, L, swapwindow, r"
      ] ++ lib.optionals enableCaelestia [
        "$mod, SPACE, exec, caelestia shell drawers toggle launcher"
        "$mod, ESCAPE, exec, caelestia shell drawers toggle session"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, pamixer -i 5"
        ",XF86AudioLowerVolume, exec, pamixer -d 5"
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ] ++ lib.optionals enableCaelestia [
        ",XF86AudioRaiseVolume, exec, caelestia shell osd volume"
        ",XF86AudioLowerVolume, exec, caelestia shell osd volume"
        ",XF86MonBrightnessUp, exec, caelestia shell osd brightness"
        ",XF86MonBrightnessDown, exec, caelestia shell osd brightness"
      ];

      bindl = [
        ",XF86AudioMute, exec, pamixer -t"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
        ",Print, exec, env QT_QPA_PLATFORM=wayland flameshot gui"
        ",Menu, exec, env QT_QPA_PLATFORM=wayland flameshot gui"
      ];

    };
  };

  home.pointerCursor = {
    name = cursorName;
    package = pkgs.catppuccin-cursors.mochaSky;
    size = cursorSize;
    gtk.enable = true;
    x11.enable = true;
  };

  home.file.".local/bin/omarchy-launch-screensaver" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}"
      mkdir -p "$log_dir"
      log_file="$log_dir/omarchy-screensaver.log"
      log() { printf '%s launcher: %s\n' "$(${pkgs.coreutils}/bin/date -Is)" "$*" >> "$log_file"; }

      log "requested"

      if ${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -e '.[] | select(.class == "org.omarchy.screensaver")' >/dev/null; then
        log "already running"
        exit 0
      fi

      log "dispatch alacritty"
      ${pkgs.hyprland}/bin/hyprctl dispatch exec -- ${pkgs.alacritty}/bin/alacritty \
        --class org.omarchy.screensaver \
        --option 'window.decorations="None"' \
        --option 'window.startup_mode="Fullscreen"' \
        --option 'cursor.style.shape="Beam"' \
        -e ${config.home.homeDirectory}/.local/bin/omarchy-screensaver >> "$log_file" 2>&1
      log "dispatch returned"
    '';
  };

  home.file.".local/bin/omarchy-screensaver" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}"
      mkdir -p "$log_dir"
      log_file="$log_dir/omarchy-screensaver.log"
      log() { printf '%s screensaver[%s]: %s\n' "$(${pkgs.coreutils}/bin/date -Is)" "$$" "$*" >> "$log_file"; }

      screensaver_in_focus() {
        ${pkgs.hyprland}/bin/hyprctl activewindow -j | ${pkgs.jq}/bin/jq -e '.class == "org.omarchy.screensaver"' >/dev/null 2>&1
      }

      exit_screensaver() {
        log "exit"
        ${pkgs.hyprland}/bin/hyprctl keyword cursor:invisible false >/dev/null 2>&1 || true
        ${pkgs.procps}/bin/pkill -P "$$" 2>/dev/null || true
        ${pkgs.procps}/bin/pkill -u "$USER" -f "[.]tte-wrapped|[t]erminaltexteffects" 2>/dev/null || true
        ${pkgs.procps}/bin/pkill -u "$USER" -f "[o]rg.omarchy.screensaver" 2>/dev/null || true
        exit 0
      }

      trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT
      printf '\033]11;rgb:00/00/00\007'
      ${pkgs.hyprland}/bin/hyprctl keyword cursor:invisible true >/dev/null 2>&1 || true

      input_file="$XDG_RUNTIME_DIR/omarchy-screensaver.txt"
      ascii_source="${config.home.homeDirectory}/.local/share/omarchy-screensaver/nixos-ascii.txt"
      tty_name="$(tty 2>/dev/null)"
      started_at="$(${pkgs.coreutils}/bin/date +%s)"
      log "started tty=$tty_name"

      while true; do
        cols="$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || printf 100)"
        rows="$(${pkgs.ncurses}/bin/tput lines 2>/dev/null || printf 30)"
        log "prepare cols=$cols rows=$rows source=$ascii_source"

        if [ ! -s "$ascii_source" ]; then
          printf 'Missing %s\n' "$ascii_source" > "$input_file"
        else
          ${pkgs.gawk}/bin/awk -v cols="$cols" -v rows="$rows" '
            {
              sub(/[[:space:]]+$/, "")
              lines[NR] = $0
              if ($0 != "") {
                match($0, /[^ ]/)
                if (RSTART > 0 && (min == "" || RSTART - 1 < min))
                  min = RSTART - 1
              }
            }
            END {
              if (min == "")
                min = 0

              for (i = 1; i <= NR; i++)
                print substr(lines[i], min + 1)
            }
          ' "$ascii_source" > "$input_file"
        fi

        ${pkgs.terminaltexteffects}/bin/tte \
          -i "$input_file" \
          --frame-rate 120 \
          --canvas-width 0 \
          --canvas-height 0 \
          --reuse-canvas \
          --anchor-canvas c \
          --anchor-text c \
          --random-effect \
          --no-eol \
          --no-restore-cursor 2>/dev/null &
        tte_pid="$!"
        log "tte started pid=$tte_pid"

        while ${pkgs.coreutils}/bin/kill -0 "$tte_pid" 2>/dev/null; do
          now="$(${pkgs.coreutils}/bin/date +%s)"
          if read -n1 -t 1; then
            log "input received"
            exit_screensaver
          fi
          if (( now - started_at > 3 )) && ! screensaver_in_focus; then
            log "lost focus"
            exit_screensaver
          fi
        done
        wait "$tte_pid" 2>/dev/null || true
        log "tte exited"
      done
    '';
  };

  home.file.".local/bin/omarchy-stop-screensaver" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      log_dir="''${XDG_STATE_HOME:-$HOME/.local/state}"
      mkdir -p "$log_dir"
      log_file="$log_dir/omarchy-screensaver.log"
      printf '%s stop: requested\n' "$(${pkgs.coreutils}/bin/date -Is)" >> "$log_file"

      ${pkgs.hyprland}/bin/hyprctl keyword cursor:invisible false >/dev/null 2>&1 || true
      ${pkgs.procps}/bin/pkill -u "$USER" -f "[.]tte-wrapped|[t]erminaltexteffects" 2>/dev/null || true

      pids="$(${pkgs.hyprland}/bin/hyprctl clients -j | ${pkgs.jq}/bin/jq -r '.[] | select(.class == "org.omarchy.screensaver") | .pid')"
      for pid in $pids; do
        kill "$pid" 2>/dev/null || true
      done
    '';
  };

  home.file.".local/share/omarchy-screensaver/nixos-ascii.txt".source =
    ../../assets/screensaver/nixos-ascii.txt;

  home.file.".local/bin/pick-color" = {
    executable = true;
    text = ''
      #!${pkgs.bash}/bin/bash
      set -euo pipefail

      color="$(${pkgs.hyprpicker}/bin/hyprpicker --format hex)"
      printf '%s' "$color" | ${pkgs.wl-clipboard}/bin/wl-copy
      ${pkgs.libnotify}/bin/notify-send "Color copied" "$color"
    '';
  };

  xdg.configFile."hypr/hypridle.conf".text = ''
    general {
      ignore_dbus_inhibit = false
      ignore_systemd_inhibit = false
    }

    listener {
      timeout = 120
      on-timeout = ${config.home.homeDirectory}/.local/bin/omarchy-launch-screensaver
      on-resume = ${config.home.homeDirectory}/.local/bin/omarchy-stop-screensaver
    }
  '';

  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hyprland idle screensaver";
      Documentation = "https://wiki.hyprland.org/Hypr-Ecosystem/hypridle";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      ExecStart = "${pkgs.hypridle}/bin/hypridle -c ${config.xdg.configHome}/hypr/hypridle.conf";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  systemd.user.services.huioncore = {
    Unit = {
      Description = "Huion tablet core driver";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "/run/current-system/sw/bin/huioncore";
      Restart = "always";
      RestartSec = 5;
    };
    Install.WantedBy = [ "hyprland-session.target" ];
  };

  xdg.dataFile."applications/yazi.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Yazi
    GenericName=File Manager
    Comment=Terminal file manager
    Icon=yazi
    Exec=alacritty -e yazi %f
    Terminal=false
    Categories=System;FileManager;
    MimeType=inode/directory;
  '';

  xdg.dataFile."applications/omarchy-screensaver.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Screensaver
    GenericName=Terminal Screensaver
    Comment=Start the Omarchy-style screensaver
    Icon=cgpp-screensaver
    Exec=${config.home.homeDirectory}/.local/bin/omarchy-launch-screensaver
    Terminal=false
    Categories=Utility;System;
  '';

  xdg.dataFile."applications/color-picker.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Color Picker
    GenericName=Screen Color Picker
    Comment=Pick a screen color and copy it to the clipboard
    Icon=color-picker
    Exec=${config.home.homeDirectory}/.local/bin/pick-color
    Terminal=false
    Categories=Utility;Graphics;
    Keywords=color;picker;eyedropper;
  '';

  xdg.dataFile."applications/lock-session.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Lock
    GenericName=Lock Session
    Comment=Lock the current session
    Icon=cgpp-lock
    Exec=caelestia shell lock lock
    Terminal=false
    Categories=System;
    Keywords=lock;screen;session;
  '';

  xdg.dataFile."applications/logout-session.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Log Out
    GenericName=End Session
    Comment=Log out of Hyprland
    Icon=cgpp-logout
    Exec=${pkgs.hyprland}/bin/hyprctl dispatch exit
    Terminal=false
    Categories=System;
    Keywords=logout;log out;session;exit;
  '';

  xdg.dataFile."applications/suspend-system.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Suspend
    GenericName=Suspend System
    Comment=Suspend the computer
    Icon=cgpp-suspend
    Exec=${pkgs.systemd}/bin/systemctl suspend
    Terminal=false
    Categories=System;
    Keywords=suspend;sleep;
  '';

  xdg.dataFile."applications/restart-system.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Restart
    GenericName=Restart System
    Comment=Restart the computer
    Icon=cgpp-restart
    Exec=${pkgs.systemd}/bin/systemctl reboot
    Terminal=false
    Categories=System;
    Keywords=restart;reboot;
  '';

  xdg.dataFile."applications/shutdown-system.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Shut Down
    GenericName=Power Off
    Comment=Shut down the computer
    Icon=cgpp-shutdown
    Exec=${pkgs.systemd}/bin/systemctl poweroff
    Terminal=false
    Categories=System;
    Keywords=shutdown;shut down;poweroff;power off;
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/preferences-system-network.svg".source =
    "${pkgs.networkmanagerapplet}/share/icons/hicolor/scalable/apps/nm-device-wired.svg";

  xdg.dataFile."icons/hicolor/256x256/apps/yazi.png".source =
    "${pkgs.yazi}/share/pixmaps/yazi.png";

  xdg.dataFile."icons/hicolor/scalable/apps/color-picker.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <defs>
        <linearGradient id="handle" x1="18" y1="46" x2="50" y2="14" gradientUnits="userSpaceOnUse">
          <stop stop-color="#84a0c6"/>
          <stop offset="1" stop-color="#89b8c2"/>
        </linearGradient>
      </defs>
      <path fill="#c6c8d1" d="M47.7 5.2a7.7 7.7 0 0 0-5.5 2.3l-4.6 4.6-2.1-2.1a3.4 3.4 0 0 0-4.8 4.8l18.5 18.5a3.4 3.4 0 1 0 4.8-4.8l-2.1-2.1 4.6-4.6A7.8 7.8 0 0 0 47.7 5.2Z"/>
      <path fill="url(#handle)" d="M35.5 18.5 13.3 40.7a8 8 0 0 0-2 3.3L8.7 54.4a1.8 1.8 0 0 0 2.1 2.1l10.4-2.6a8 8 0 0 0 3.3-2l22.2-22.2-11.2-11.2Z"/>
      <path fill="#161821" fill-opacity=".55" d="m17.7 45.1 21.2-21.2 3.2 3.2-21.2 21.2a3.4 3.4 0 0 1-1.4.8l-4.1 1 1-4.1a3.4 3.4 0 0 1 1.3-.9Z"/>
      <path fill="#e27878" d="M9.8 54.3c4.1-1.2 7.4-.5 9.8 2.1H10.3a1.8 1.8 0 0 1-.5-2.1Z"/>
    </svg>
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/cgpp-shutdown.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="26" fill="#1e2132"/>
      <path fill="none" stroke="#e27878" stroke-linecap="round" stroke-width="7" d="M32 12v21"/>
      <path fill="none" stroke="#c6c8d1" stroke-linecap="round" stroke-width="6" d="M21.3 20.7a18 18 0 1 0 21.4 0"/>
    </svg>
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/cgpp-restart.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="26" fill="#1e2132"/>
      <path fill="none" stroke="#84a0c6" stroke-linecap="round" stroke-linejoin="round" stroke-width="6" d="M47 24a17 17 0 1 0 1.7 13"/>
      <path fill="#84a0c6" d="M47 11v15H32z"/>
    </svg>
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/cgpp-logout.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <rect width="42" height="42" x="9" y="11" fill="#1e2132" rx="8"/>
      <path fill="none" stroke="#c6c8d1" stroke-linecap="round" stroke-linejoin="round" stroke-width="5" d="M31 21h11v22H31"/>
      <path fill="none" stroke="#e2a478" stroke-linecap="round" stroke-linejoin="round" stroke-width="6" d="M12 32h24"/>
      <path fill="#e2a478" d="m33 20 13 12-13 12z"/>
    </svg>
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/cgpp-suspend.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <circle cx="32" cy="32" r="26" fill="#1e2132"/>
      <path fill="#89b8c2" d="M24 14h8L21 32h12L20 52h-8l11-17H11z"/>
      <path fill="#c6c8d1" d="M38 18h15L39 41h15v6H28l14-23H38z"/>
    </svg>
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/cgpp-lock.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <rect width="42" height="32" x="11" y="26" fill="#1e2132" rx="7"/>
      <path fill="none" stroke="#84a0c6" stroke-linecap="round" stroke-width="6" d="M20 27v-7a12 12 0 0 1 24 0v7"/>
      <circle cx="32" cy="40" r="5" fill="#c6c8d1"/>
      <path fill="#c6c8d1" d="M30 42h4l2 10h-8z"/>
    </svg>
  '';

  xdg.dataFile."icons/hicolor/scalable/apps/cgpp-screensaver.svg".text = ''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
      <rect width="50" height="34" x="7" y="10" fill="#1e2132" rx="6"/>
      <path fill="#89b8c2" d="M22 19h20v4H22zM17 28h30v4H17zM25 37h14v4H25z"/>
      <path fill="none" stroke="#c6c8d1" stroke-linecap="round" stroke-width="5" d="M24 53h16"/>
      <path fill="none" stroke="#c6c8d1" stroke-linecap="round" stroke-width="4" d="M32 44v9"/>
    </svg>
  '';

  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "yazi.desktop" ];
  };

  xdg.configFile."xdg-desktop-portal-termfilechooser/config".text = ''
    [filechooser]
    cmd=yazi-wrapper.sh
    create_help_file=0
    default_dir=$HOME
    env=TERMCMD=${pkgs.alacritty}/bin/alacritty --title 'Yazi File Picker' -e
    open_mode=suggested
    save_mode=suggested
  '';

  xdg.configFile."flameshot/flameshot.ini".text = ''
    [General]
    contrastOpacity=190
    contrastUiColor=#161821
    disabledGrimWarning=true
    drawColor=#E27878
    predefinedColorPaletteLarge=false
    uiColor=#84A0C6
    useGrimAdapter=true
    userColors=#E27878, #B4BE82, #E2A478, #84A0C6, #A093C7, #89B8C2, #C6C8D1, #6B7089, picker
  '';

  home.sessionVariables = {
    XCURSOR_THEME = cursorName;
    XCURSOR_SIZE = toString cursorSize;
    HYPRCURSOR_THEME = cursorName;
    HYPRCURSOR_SIZE = toString cursorSize;
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };
}
