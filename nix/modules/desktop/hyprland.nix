{ lib, pkgs, ... }:

let
  sddmIcebergTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "sddm-iceberg-minimal";
    version = "1.0";
    src = ../../assets/sddm/iceberg;
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/sddm/themes/iceberg-minimal
      cp -r . $out/share/sddm/themes/iceberg-minimal
      runHook postInstall
    '';
  };

  cursorName = "catppuccin-mocha-sky-cursors";

  sddmWithGreeterAlias = pkgs.kdePackages.sddm.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      ln -s $out/bin/sddm-greeter-qt6 $out/bin/sddm-greeter
    '';
  });
in
{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager = {
    defaultSession = "hyprland";
    sddm = {
      enable = true;
      package = sddmWithGreeterAlias;
      theme = "iceberg-minimal";
      wayland = {
        enable = true;
        compositor = "kwin";
      };
      settings = {
        General = {
          GreeterEnvironment = lib.mkForce "QT_WAYLAND_SHELL_INTEGRATION=layer-shell,QML_DISABLE_DISK_CACHE=1";
        };
        Theme = {
          CursorTheme = cursorName;
          CursorSize = 24;
        };
        Users = {
          RememberLastUser = true;
          RememberLastSession = true;
        };
      };
      extraPackages = with pkgs.kdePackages; [
        pkgs.catppuccin-cursors.mochaSky
        qtsvg
      ];
    };
  };

  services.greetd.enable = false;

  services.dbus.enable = true;
  programs.dconf.enable = true;
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;

  xdg.portal = {
    enable = true;
    config.hyprland = {
      default = [ "hyprland" "gtk" ];
      "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-termfilechooser
      xdg-desktop-portal-gtk
    ];
  };

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    GTK_USE_PORTAL = "1";
  };

  environment.systemPackages = with pkgs; [
    sddmIcebergTheme
    catppuccin-cursors.mochaSky
    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-termfilechooser
    qt6.qtwayland
    libsForQt5.qt5.qtwayland
    glib
    gsettings-desktop-schemas
    adwaita-icon-theme
    polkit_gnome
    hypridle
    hyprpicker
    grim
    slurp
    swappy
    swaynotificationcenter
  ];
}
