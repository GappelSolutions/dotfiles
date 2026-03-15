{ lib, stdenvNoCC, fetchurl, _7zz }:

stdenvNoCC.mkDerivation rec {
  pname = "tui-studio";
  version = "0.3.9";

  src = fetchurl {
    url = "https://github.com/jalonsogo/tui-studio-desktop/releases/download/v${version}/TUIStudio.dmg";
    hash = "sha256-d+b8oR45hdlQJtXlIYYSPT7kIdYwuvWzDDmo1N32Dew=";
  };

  nativeBuildInputs = [ _7zz ];
  sourceRoot = ".";

  unpackPhase = ''
    7zz x $src -y
  '';

  installPhase = ''
    mkdir -p $out/Applications
    find . -maxdepth 2 -name "*.app" -exec cp -r {} $out/Applications/ \;
  '';

  dontFixup = true;

  meta = with lib; {
    description = "Visual editor for designing Terminal UIs";
    homepage = "https://tui.studio";
    platforms = [ "aarch64-darwin" ];
    license = licenses.unfree;
  };
}
