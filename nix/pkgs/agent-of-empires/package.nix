{
  lib,
  glibc,
  patchelf,
  stdenv,
  stdenvNoCC,
  zlib,
  fetchurl,
}:
let
  isLinux = stdenvNoCC.hostPlatform.isLinux;
  linuxDynamicLinker =
    if stdenvNoCC.hostPlatform.system == "x86_64-linux" then
      "${glibc}/lib/ld-linux-x86-64.so.2"
    else if stdenvNoCC.hostPlatform.system == "aarch64-linux" then
      "${glibc}/lib/ld-linux-aarch64.so.1"
    else
      null;
  assets = {
    x86_64-linux = {
      url = "https://github.com/agent-of-empires/agent-of-empires/releases/download/v1.12.1/aoe-linux-amd64.tar.gz";
      hash = "sha256-OSpK4fU+oEHt9RttEMoqtKxhkQO4Lm2LfjqBYiygrjk=";
      binary = "aoe-linux-amd64";
    };
    aarch64-linux = {
      url = "https://github.com/agent-of-empires/agent-of-empires/releases/download/v1.12.1/aoe-linux-arm64.tar.gz";
      hash = "sha256-S4xg/C3MNRPYhOSTC1KOoIU64Q4XJMEActCQSRDSA5w=";
      binary = "aoe-linux-arm64";
    };
    x86_64-darwin = {
      url = "https://github.com/agent-of-empires/agent-of-empires/releases/download/v1.12.1/aoe-darwin-amd64.tar.gz";
      hash = "sha256-yQj+yhsQ0CvysQggo2pwl6+LYRhyhUbAOxgu4xHigo0=";
      binary = "aoe-darwin-amd64";
    };
    aarch64-darwin = {
      url = "https://github.com/agent-of-empires/agent-of-empires/releases/download/v1.12.1/aoe-darwin-arm64.tar.gz";
      hash = "sha256-rBYPzCq/49HtPtvN2zHk/twilZx1bR8x3kY7PEFJ/AQ=";
      binary = "aoe-darwin-arm64";
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "agent-of-empires";
  version = "1.12.1";

  src = fetchurl {
    inherit (assets.${stdenvNoCC.hostPlatform.system}) url hash;
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = lib.optionals isLinux [ patchelf ];
  buildInputs = lib.optionals isLinux [
    glibc
    zlib
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall

    tar -xzf "$src"
    install -Dm755 ${assets.${stdenvNoCC.hostPlatform.system}.binary} "$out/bin/aoe"

    ${lib.optionalString isLinux ''
      patchelf \
        --set-interpreter ${linuxDynamicLinker} \
        --set-rpath ${lib.makeLibraryPath [ glibc zlib stdenv.cc.cc.lib ]} \
        "$out/bin/aoe"
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Terminal session manager for AI coding agents";
    homepage = "https://github.com/agent-of-empires/agent-of-empires";
    license = lib.licenses.mit;
    mainProgram = "aoe";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
