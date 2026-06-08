{
  lib,
  glibc,
  patchelf,
  stdenvNoCC,
  fetchurl,
}:
let
  assets = {
    x86_64-linux = {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v15.10.1/omp-linux-x64";
      hash = "sha256-UJseqZHMyPOs4AHcr5hilMF10MlO9aqSPf+x8CFwS50=";
    };
    aarch64-linux = {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v15.10.1/omp-linux-arm64";
      hash = "sha256-37tcWhpm8WfnvBoXkVvDRZbWlnkltc4bZDZ1QBySyH0=";
    };
    x86_64-darwin = {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v15.10.1/omp-darwin-x64";
      hash = "sha256-eqodc/X9YQaA6xZIreK2yzzAnrdgIE1gwtG2tgcSH4o=";
    };
    aarch64-darwin = {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v15.10.1/omp-darwin-arm64";
      hash = "sha256-tehuDSKW2fvwC8wRbDchFXVVFs2LWr/dQKCdR+XGGvA=";
    };
  };
  linuxDynamicLinker =
    if stdenvNoCC.hostPlatform.system == "x86_64-linux" then
      "${glibc}/lib/ld-linux-x86-64.so.2"
    else if stdenvNoCC.hostPlatform.system == "aarch64-linux" then
      "${glibc}/lib/ld-linux-aarch64.so.1"
    else
      null;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "oh-my-pi";
  version = "15.10.1";

  src = fetchurl {
    inherit (assets.${stdenvNoCC.hostPlatform.system}) url hash;
  };

  nativeBuildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux patchelf;
  buildInputs = lib.optional stdenvNoCC.hostPlatform.isLinux glibc;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/omp"

    ${lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
      patchelf \
        --set-interpreter ${linuxDynamicLinker} \
        --set-rpath ${lib.makeLibraryPath [ glibc ]} \
        "$out/bin/omp"
    ''}

    runHook postInstall
  '';

  meta = {
    description = "Coding agent with the IDE wired in";
    homepage = "https://github.com/can1357/oh-my-pi";
    changelog = "https://github.com/can1357/oh-my-pi/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
