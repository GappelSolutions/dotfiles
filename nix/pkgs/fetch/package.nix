# `fetch`: shell greeting, no flags. fetch.sh picks per pane size between
# - fetch.c: areofyl/fetch v2.3.0 (ISC, https://github.com/areofyl/fetch), spinning 3D distro logo.
#   Local changes: on exit the cursor goes under the last drawn row, not under the whole canvas;
#   user@host title in blue.
# - small.sh: compact nerdfetch-style block.
{
  lib,
  stdenv,
  makeWrapper,
  runtimeShell,
  fastfetch,
  pciutils,
  util-linux,
}:

stdenv.mkDerivation {
  pname = "fetch";
  version = lib.trim (builtins.readFile ./VERSION);
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [ ./fetch.c ./Makefile ./VERSION ./fetch.sh ./small.sh ];
  };

  strictDeps = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 fetch $out/libexec/fetch/fetch-3d
    wrapProgram $out/libexec/fetch/fetch-3d \
      --prefix PATH : ${lib.makeBinPath ([ fastfetch ] ++ lib.optional stdenv.hostPlatform.isLinux pciutils)}

    { echo '#!${runtimeShell}'; cat small.sh; } > $out/libexec/fetch/fetch-small
    chmod +x $out/libexec/fetch/fetch-small
    ${lib.optionalString stdenv.hostPlatform.isLinux ''
      wrapProgram $out/libexec/fetch/fetch-small --prefix PATH : ${lib.makeBinPath [ util-linux ]}
    ''}

    mkdir -p $out/bin
    { echo '#!${runtimeShell}'; cat fetch.sh; } > $out/bin/fetch
    substituteInPlace $out/bin/fetch \
      --replace-fail @fetch3d@ $out/libexec/fetch/fetch-3d \
      --replace-fail @small@ $out/libexec/fetch/fetch-small
    chmod +x $out/bin/fetch
    runHook postInstall
  '';

  meta = {
    description = "Shell greeting: spinning 3D distro logo in big panes, compact info in small ones";
    license = lib.licenses.isc;
    mainProgram = "fetch";
    platforms = lib.platforms.unix;
  };
}
