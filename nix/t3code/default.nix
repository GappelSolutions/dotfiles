{ lib, stdenvNoCC, fetchurl, _7zz }:

stdenvNoCC.mkDerivation rec {
  pname = "t3-code";
  version = "0.0.3";

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-arm64.dmg";
    hash = "sha256-0xBCebEZRTK76rkXBj7y8E57keG0hFbD/b4YaLzdgPg=";
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
    description = "A minimal GUI for coding agents";
    homepage = "https://github.com/pingdotgg/t3code";
    platforms = [ "aarch64-darwin" ];
    license = licenses.unfree;
  };
}
