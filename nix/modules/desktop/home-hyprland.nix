{ enableCaelestia ? true, lib, pkgs, ... }:

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
    hyprsunset
    libreoffice-fresh
    localsend
    networkmanagerapplet
    obsidian
    pavucontrol
    spotify
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

  xdg.desktopEntries.color-picker = {
    name = "Color Picker";
    genericName = "Screen Color Picker";
    comment = "Pick a screen color and copy it to the clipboard";
    exec = "caelestia shell picker openClip";
    terminal = false;
    categories = [ "Utility" "Graphics" ];
  };

  xdg.desktopEntries.lock-session = {
    name = "Lock";
    genericName = "Lock Session";
    comment = "Lock the current session";
    exec = "caelestia shell lock lock";
    terminal = false;
    categories = [ "System" ];
  };

  xdg.desktopEntries.logout-session = {
    name = "Log Out";
    genericName = "End Session";
    comment = "Log out of Hyprland";
    exec = "${pkgs.hyprland}/bin/hyprctl dispatch exit";
    terminal = false;
    categories = [ "System" ];
  };

  xdg.desktopEntries.suspend-system = {
    name = "Suspend";
    genericName = "Suspend System";
    comment = "Suspend the computer";
    exec = "${pkgs.systemd}/bin/systemctl suspend";
    terminal = false;
    categories = [ "System" ];
  };

  xdg.desktopEntries.restart-system = {
    name = "Restart";
    genericName = "Restart System";
    comment = "Restart the computer";
    exec = "${pkgs.systemd}/bin/systemctl reboot";
    terminal = false;
    categories = [ "System" ];
  };

  xdg.desktopEntries.shutdown-system = {
    name = "Shut Down";
    genericName = "Power Off";
    comment = "Shut down the computer";
    exec = "${pkgs.systemd}/bin/systemctl poweroff";
    terminal = false;
    categories = [ "System" ];
  };

  xdg.dataFile."icons/hicolor/scalable/apps/preferences-system-network.svg".source =
    "${pkgs.networkmanagerapplet}/share/icons/hicolor/scalable/apps/nm-device-wired.svg";

  xdg.dataFile."icons/hicolor/256x256/apps/yazi.png".source =
    "${pkgs.yazi}/share/pixmaps/yazi.png";

  xdg.mimeApps = {
    enable = true;
    defaultApplications."inode/directory" = [ "yazi.desktop" ];
  };

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
