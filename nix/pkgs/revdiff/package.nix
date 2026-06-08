{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "revdiff";
  version = "1.6.1";

  src =
    let
      assets = {
        x86_64-linux = {
          url = "https://github.com/umputun/revdiff/releases/download/v${finalAttrs.version}/revdiff_${finalAttrs.version}_linux_amd64.tar.gz";
          hash = "sha256-BsSlPUwK/0cNyoANQGVQSnrivpjAmQrpt+nCqeAwpbI=";
        };
        aarch64-linux = {
          url = "https://github.com/umputun/revdiff/releases/download/v${finalAttrs.version}/revdiff_${finalAttrs.version}_linux_arm64.tar.gz";
          hash = "sha256-KxIIDMbvec8mBEF1wbaaGB6zTEaf/W0nr21HEMdgdjc=";
        };
        x86_64-darwin = {
          url = "https://github.com/umputun/revdiff/releases/download/v${finalAttrs.version}/revdiff_${finalAttrs.version}_darwin_amd64.tar.gz";
          hash = "sha256-slC0nRbdUOU8VZPsrFZRm1mrMhZaayO2hTfcy5rGPQs=";
        };
        aarch64-darwin = {
          url = "https://github.com/umputun/revdiff/releases/download/v${finalAttrs.version}/revdiff_${finalAttrs.version}_darwin_arm64.tar.gz";
          hash = "sha256-ofHUOi2UUxSr5lz1XVm2xYUhE0o68r8U3AoCiTgDHO8=";
        };
      };
    in
    fetchurl {
      inherit (assets.${stdenvNoCC.hostPlatform.system}) url hash;
    };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    tar -xzf "$src"
    install -Dm755 revdiff "$out/bin/revdiff"
    install -Dm644 completions/revdiff.bash "$out/share/bash-completion/completions/revdiff"
    install -Dm644 completions/revdiff.fish "$out/share/fish/vendor_completions.d/revdiff.fish"
    install -Dm644 completions/revdiff.zsh "$out/share/zsh/site-functions/_revdiff"

    runHook postInstall
  '';

  meta = {
    description = "Diff review TUI for AI agents";
    homepage = "https://github.com/umputun/revdiff";
    license = lib.licenses.mit;
    mainProgram = "revdiff";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
})
