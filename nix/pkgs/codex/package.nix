{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex";
  version = "0.135.0";

  src =
    let
      assets = {
        x86_64-linux = {
          url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
          hash = "sha256-9ITnfNbE4Ouqy2eDnO3X1o420Ih4TKVTvBd9JoT58Hg=";
        };
        aarch64-darwin = {
          url = "https://github.com/openai/codex/releases/download/rust-v${finalAttrs.version}/codex-package-aarch64-apple-darwin.tar.gz";
          hash = "sha256-yFs5JxgK+zMnrkMNucL8fgsAYBF1xY6EK5DQ2YpZd7I=";
        };
      };
      asset = assets.${stdenvNoCC.hostPlatform.system};
    in
    fetchurl {
      inherit (asset) url hash;
    };

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    tar -xzf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R bin "$out/"
    cp -R codex-path "$out/"
    cp -R codex-resources "$out/"
    cp codex-package.json "$out/"

    runHook postInstall
  '';

  meta = {
    description = "Lightweight coding agent that runs in your terminal";
    homepage = "https://github.com/openai/codex";
    changelog = "https://github.com/openai/codex/releases/tag/rust-v${finalAttrs.version}";
    license = lib.licenses.asl20;
    mainProgram = "codex";
    platforms = lib.platforms.unix;
  };
})
