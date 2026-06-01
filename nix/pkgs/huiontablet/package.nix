{
  autoPatchelfHook,
  fetchurl,
  lib,
  stdenv,
  bash,
  coreutils,
  gawk,
  gnugrep,
  gnused,
  procps,
  e2fsprogs,
  fontconfig,
  freetype,
  libglvnd,
  libgpg-error,
  libusb1,
  libxkbcommon,
  xorg,
  zlib,
}:

stdenv.mkDerivation rec {
  pname = "huiontablet";
  version = "15.0.0.175";

  src = fetchurl {
    url = "https://driverdl.huion.com/driver/Linux/HuionTablet_LinuxDriver_v${version}.x86_64.tar.xz";
    hash = "sha256-sCUztiMQ+CVlM1SxaQa/5vcK417GSUxB6JgBoilsPAY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    e2fsprogs
    fontconfig
    freetype
    libglvnd
    libgpg-error
    libusb1
    libxkbcommon
    xorg.libX11
    xorg.libXau
    xorg.libXdmcp
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libXinerama
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    zlib
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/libexec/huiontablet $out/bin $out/share/applications $out/share/icons/hicolor/256x256/apps
    cp -a huiontablet/. $out/libexec/huiontablet/
    install -Dm0644 icon/huiontablet.png $out/share/icons/hicolor/256x256/apps/huiontablet.png

    substituteInPlace $out/libexec/huiontablet/huiontablet.sh \
      --replace-fail '#!/bin/bash' '#!${bash}/bin/bash' \
      --replace-fail 'ps -e' '${procps}/bin/ps -e' \
      --replace-fail 'grep huionCore' '${gnugrep}/bin/grep huionCore' \
      --replace-fail 'grep huiontablet' '${gnugrep}/bin/grep huiontablet' \
      --replace-fail 'killall huionCore' '${procps}/bin/killall huionCore' \
      --replace-fail 'killall huiontablet' '${procps}/bin/killall huiontablet' \
      --replace-fail 'LD_LIBRARY_PATH=$dirname/libs' '# Nix patchelf supplies library paths; exporting bundled libs breaks helper commands.' \
      --replace-fail 'export LD_LIBRARY_PATH' '# export LD_LIBRARY_PATH'

    cat > $out/bin/huiontablet <<EOF
    #!${bash}/bin/bash
    set -euo pipefail

    export PATH="${lib.makeBinPath [
      coreutils
      gawk
      gnugrep
      gnused
      procps
      xorg.xmodmap
    ]}:\$PATH"

    runtime="\''${XDG_DATA_HOME:-\$HOME/.local/share}/huiontablet"
    source_marker="\$runtime/.nix-store-source"

    if [ ! -e "\$source_marker" ] || [ "\$(${coreutils}/bin/cat "\$source_marker" 2>/dev/null || true)" != "$out" ]; then
      ${coreutils}/bin/rm -rf "\$runtime"
      ${coreutils}/bin/mkdir -p "\$runtime"
      ${coreutils}/bin/cp -a "$out/libexec/huiontablet/." "\$runtime/"
      ${coreutils}/bin/chmod -R u+w "\$runtime"
      ${coreutils}/bin/printf '%s\n' "$out" > "\$source_marker"
    fi

    cd "\$runtime"
    exec ${bash}/bin/bash ./huiontablet.sh "\$@"
    EOF
    chmod +x $out/bin/huiontablet

    cat > $out/bin/huioncore <<EOF
    #!${bash}/bin/bash
    set -euo pipefail

    export PATH="${lib.makeBinPath [
      coreutils
      gawk
      gnugrep
      gnused
      procps
      xorg.xmodmap
    ]}:\$PATH"

    runtime="\''${XDG_DATA_HOME:-\$HOME/.local/share}/huiontablet"
    source_marker="\$runtime/.nix-store-source"

    if [ ! -e "\$source_marker" ] || [ "\$(${coreutils}/bin/cat "\$source_marker" 2>/dev/null || true)" != "$out" ]; then
      ${coreutils}/bin/rm -rf "\$runtime"
      ${coreutils}/bin/mkdir -p "\$runtime"
      ${coreutils}/bin/cp -a "$out/libexec/huiontablet/." "\$runtime/"
      ${coreutils}/bin/chmod -R u+w "\$runtime"
      ${coreutils}/bin/printf '%s\n' "$out" > "\$source_marker"
    fi

    cd "\$runtime"
    exec ./huionCore -d
    EOF
    chmod +x $out/bin/huioncore

    cat > $out/share/applications/huiontablet.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=HuionTablet
    Comment=Huion tablet driver
    Exec=$out/bin/huiontablet
    Icon=huiontablet
    Terminal=false
    Categories=Utility;
    EOF

    runHook postInstall
  '';

  meta = {
    description = "Official Huion Tablet Linux driver";
    homepage = "https://www.huion.com/download";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
