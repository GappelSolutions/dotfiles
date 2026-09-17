# opencode from upstream's own prebuilt binary, not nixpkgs' from-source build.
#
# Two things are wrong with nixpkgs' opencode for this machine:
#   * it carries 1.18.30, which crashes in SystemPrompt.environment before any
#     request reaches the provider ("TypeError: undefined is not an object
#     (evaluating 'a.name')"), in `run` and behind `opencode serve` alike, so
#     T3 Code cannot drive it at all -- upstream fixed that in 1.18.31;
#   * rebuilding that derivation at 1.18.31 still crashes the same way, while
#     the published 1.18.31 binary does not. The from-source bundle is the
#     difference, not the version, and chasing it is not worth the time.
#
# The npm platform package is the same artifact upstream ships, so this tracks
# whatever T3 Code expects. Revisit once nixpkgs is comfortably past 1.18.31.
{
  lib,
  stdenv,
  fetchurl,
  patchelf,
  makeWrapper,
  ripgrep,
  versionCheckHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "opencode";
  version = "1.18.31";

  src = fetchurl {
    url = "https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-${finalAttrs.version}.tgz";
    hash = "sha256-bYnaJSqLAw2SPnKDltw0Rlz2CVEBt4IisO4ze2gUDeo=";
  };

  # The tarball ships a bun single-file executable: the JS bundle is appended
  # past the ELF image, so autoPatchelfHook or strip silently truncate it and
  # the result degrades into a bare bun runtime ("Script not found "serve"").
  nativeBuildInputs = [
    makeWrapper
    patchelf
  ];

  dontStrip = true;
  dontPatchELF = true;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 bin/opencode $out/bin/opencode

    # --set-interpreter only. autoPatchelfHook (rpath rewrite + strip) leaves the
    # appended bundle unreadable and the binary falls back to a bare bun runtime.
    patchelf --set-interpreter "${stdenv.cc.bintools.dynamicLinker}" $out/bin/opencode
    wrapProgram $out/bin/opencode \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      --set OPENCODE_DISABLE_AUTOUPDATE true

    runHook postInstall
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--version";

  meta = {
    description = "AI coding agent built for the terminal";
    homepage = "https://opencode.ai";
    license = lib.licenses.mit;
    mainProgram = "opencode";
    platforms = [ "x86_64-linux" ];
  };
})
