{ config, inputs, lib, pkgs, ... }:

let
  caelestiaShell = inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/caelestia-clock-calendar-popout.patch
    ];
    postPatch = (old.postPatch or "") + ''
      substituteInPlace modules/drawers/ContentWindow.qml \
        --replace-fail 'monitor?.lastIpcObject.specialWorkspace?.name || monitor?.activeWorkspace.lastIpcObject.windows > 0' 'monitor?.lastIpcObject?.specialWorkspace?.name || (monitor?.activeWorkspace?.lastIpcObject?.windows ?? 0) > 0' \
        --replace-fail 'monitor?.lastIpcObject.specialWorkspace?.name' 'monitor?.lastIpcObject?.specialWorkspace?.name' \
        --replace-fail 't.lastIpcObject.fullscreen > 1' '(t.lastIpcObject?.fullscreen ?? 0) > 1'
    '';
  });

  icebergScheme = {
    name = "iceberg";
    flavour = "dark";
    mode = "dark";
    variant = "tonalspot";
    colours = {
      primary_paletteKeyColor = "84A0C6";
      secondary_paletteKeyColor = "91ACD1";
      tertiary_paletteKeyColor = "89B8C2";
      neutral_paletteKeyColor = "6B7089";
      neutral_variant_paletteKeyColor = "818596";
      background = "161821";
      onBackground = "C6C8D1";
      surface = "161821";
      surfaceDim = "0F1117";
      surfaceBright = "2E313F";
      surfaceContainerLowest = "0F1117";
      surfaceContainerLow = "1A1C27";
      surfaceContainer = "1E2132";
      surfaceContainerHigh = "24283A";
      surfaceContainerHighest = "2E313F";
      onSurface = "C6C8D1";
      surfaceVariant = "2E313F";
      onSurfaceVariant = "D2D4DE";
      inverseSurface = "C6C8D1";
      inverseOnSurface = "161821";
      outline = "6B7089";
      outlineVariant = "444B71";
      shadow = "000000";
      scrim = "000000";
      surfaceTint = "84A0C6";
      primary = "84A0C6";
      onPrimary = "161821";
      primaryContainer = "444B71";
      onPrimaryContainer = "D2D4DE";
      inversePrimary = "91ACD1";
      secondary = "91ACD1";
      onSecondary = "161821";
      secondaryContainer = "3E445E";
      onSecondaryContainer = "D2D4DE";
      tertiary = "89B8C2";
      onTertiary = "161821";
      tertiaryContainer = "3A515B";
      onTertiaryContainer = "D2D4DE";
      error = "E27878";
      onError = "161821";
      errorContainer = "5A2D35";
      onErrorContainer = "E98989";
      primaryFixed = "D2D4DE";
      primaryFixedDim = "84A0C6";
      onPrimaryFixed = "161821";
      onPrimaryFixedVariant = "444B71";
      secondaryFixed = "D2D4DE";
      secondaryFixedDim = "91ACD1";
      onSecondaryFixed = "161821";
      onSecondaryFixedVariant = "3E445E";
      tertiaryFixed = "D2D4DE";
      tertiaryFixedDim = "89B8C2";
      onTertiaryFixed = "161821";
      onTertiaryFixedVariant = "3A515B";
      term0 = "161821";
      term1 = "E27878";
      term2 = "B4BE82";
      term3 = "E2A478";
      term4 = "84A0C6";
      term5 = "A093C7";
      term6 = "89B8C2";
      term7 = "C6C8D1";
      term8 = "6B7089";
      term9 = "E98989";
      term10 = "C0CA8E";
      term11 = "E9B189";
      term12 = "91ACD1";
      term13 = "ADA0D3";
      term14 = "95C4CE";
      term15 = "D2D4DE";
      rosewater = "D2D4DE";
      flamingo = "E98989";
      pink = "ADA0D3";
      mauve = "A093C7";
      red = "E27878";
      maroon = "E98989";
      peach = "E2A478";
      yellow = "E9B189";
      green = "B4BE82";
      teal = "89B8C2";
      sky = "95C4CE";
      sapphire = "91ACD1";
      blue = "84A0C6";
      lavender = "ADA0D3";
      klink = "84A0C6";
      klinkSelection = "84A0C6";
      kvisited = "A093C7";
      kvisitedSelection = "A093C7";
      knegative = "E27878";
      knegativeSelection = "E27878";
      kneutral = "E2A478";
      kneutralSelection = "E2A478";
      kpositive = "B4BE82";
      kpositiveSelection = "B4BE82";
      text = "C6C8D1";
      subtext1 = "D2D4DE";
      subtext0 = "6B7089";
      overlay2 = "818596";
      overlay1 = "6B7089";
      overlay0 = "565B73";
      surface2 = "444B71";
      surface1 = "2E313F";
      surface0 = "1E2132";
      base = "161821";
      mantle = "0F1117";
      crust = "0B0D12";
      success = "B4BE82";
      onSuccess = "161821";
      successContainer = "3E4A34";
      onSuccessContainer = "C0CA8E";
    };
  };
in
{
  home.packages = with pkgs; [
    app2unit
    brightnessctl
    ddcutil
    flameshot
    grim
    libnotify
    material-symbols
    networkmanager
    pamixer
    playerctl
    slurp
    swappy
    wl-clipboard
  ];

  programs.caelestia = {
    enable = true;
    package = caelestiaShell;
    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
    settings = {
      appearance.rounding.scale = 0.48;
      bar.status.showBattery = true;
      border.rounding = 12;
      paths.mediaGif = "${config.home.homeDirectory}/.local/share/caelestia/media-headbang.gif";
      paths.sessionGif = "${config.home.homeDirectory}/.local/share/caelestia/session-power.gif";
      paths.wallpaperDir = "${config.home.homeDirectory}/.local/share/caelestia/wallpapers";
      general.idle = {
        lockBeforeSleep = false;
        timeouts = [ ];
      };
      launcher.useFuzzy.apps = true;
      services.useFahrenheit = false;
      services.useFahrenheitPerformance = false;
      services.useTwelveHourClock = false;
    };
    cli = {
      enable = true;
      settings.theme.enableGtk = true;
    };
  };

  home.file.".local/share/caelestia/session-power.gif".source =
    ../../assets/caelestia/session-power.gif;

  home.file.".local/share/caelestia/media-headbang.gif".source =
    ../../assets/caelestia/media-headbang.gif;

  home.file.".local/share/caelestia/wallpapers/background.png".source =
    ../../assets/sddm/iceberg/background.png;

  home.activation.caelestiaIcebergScheme =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      wallpaper_path='${config.home.homeDirectory}/.local/share/caelestia/wallpapers/background.png'
      mkdir -p ${config.home.homeDirectory}/.local/state/caelestia
      mkdir -p ${config.home.homeDirectory}/.local/state/caelestia/wallpaper
      printf '%s\n' "$wallpaper_path" > ${config.home.homeDirectory}/.local/state/caelestia/wallpaper/path.txt
      ln -sfn "$wallpaper_path" ${config.home.homeDirectory}/.local/state/caelestia/wallpaper/current
      printf '%s\n' '${builtins.toJSON icebergScheme}' > ${config.home.homeDirectory}/.local/state/caelestia/scheme.json
    '';
}
