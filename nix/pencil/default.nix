{ lib, stdenvNoCC, fetchurl, undmg }:

stdenvNoCC.mkDerivation rec {
  pname = "pencil-dev";
  version = "0.0.0"; # unversioned release URL — update comment when known

  src = fetchurl {
    url = "https://www.pencil.dev/download/Pencil-mac-arm64.dmg";
    hash = "sha256-Vx+kwjHGrJsII6deMR3060eAYrwcN9Tg+8eKO/7zZjo=";
  };

  nativeBuildInputs = [ undmg ];
  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/Applications
    cp -r *.app $out/Applications/
  '';

  meta = with lib; {
    description = "Design on canvas. Land in code.";
    homepage = "https://pencil.dev";
    platforms = [ "aarch64-darwin" ];
    license = licenses.unfree;
    mainProgram = "pencil";
  };
}
