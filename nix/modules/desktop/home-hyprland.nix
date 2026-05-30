{ pkgs, ... }:

{
  home.packages = with pkgs; [
    alacritty
    cliphist
    wl-clipboard
    wtype
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    systemd.enable = true;
    settings = {
      "$mod" = "SUPER";

      monitor = [
        ",preferred,auto,1.25"
      ];

      input = {
        kb_layout = "de,us";
        kb_options = "compose:caps,grp:alts_toggle";
        repeat_rate = 40;
        repeat_delay = 200;
        numlock_by_default = true;
        touchpad.scroll_factor = 0.4;
      };

      general = {
        gaps_in = 3;
        gaps_out = 6;
        border_size = 1;
      };

      decoration.rounding = 8;

      exec-once = [
        "wl-paste --type text --watch cliphist store"
        "wl-paste --type image --watch cliphist store"
      ];

      bind = [
        "$mod, RETURN, exec, alacritty"
        "$mod, M, exec, ~/.local/bin/wife-help"
        "$mod, S, exec, zen"
        "$mod, Q, killactive"
        "$mod, F, fullscreen, 0"
        "$mod, W, togglefloating"
        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"
        "$mod SHIFT, H, swapwindow, l"
        "$mod SHIFT, J, swapwindow, d"
        "$mod SHIFT, K, swapwindow, u"
        "$mod SHIFT, L, swapwindow, r"
      ];

      bindel = [
        ",XF86AudioRaiseVolume, exec, pamixer -i 5"
        ",XF86AudioLowerVolume, exec, pamixer -d 5"
        ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ",XF86AudioMute, exec, pamixer -t"
        ",XF86AudioPlay, exec, playerctl play-pause"
        ",XF86AudioNext, exec, playerctl next"
        ",XF86AudioPrev, exec, playerctl previous"
      ];
    };
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };
}
