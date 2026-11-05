# calldiff + the grammars our repos use (C#, bash, Python, Rust, Go, Lua), prebuilt. calldiff loads
# a grammar from its own node_modules first and only falls back to `npm install` into ~/.cache at
# runtime (native build) for languages not bundled here, which fails offline and crashes the run.
# TypeScript/TSX/JS come with calldiff. Bump: edit package.json, then
# `npm install --package-lock-only --ignore-scripts --legacy-peer-deps` and update npmDepsHash.
{
  lib,
  buildNpmPackage,
  nodejs_22,
  makeWrapper,
  python3,
}:
buildNpmPackage {
  pname = "calldiff";
  version = "0.5.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-NDK/1J78eDkrFRbrl9naIPeyVW8m4XgLzkyTIOURPVk=";
  npmFlags = [ "--legacy-peer-deps" ];
  nodejs = nodejs_22;

  nativeBuildInputs = [
    makeWrapper
    python3
  ];

  # node-gyp-build would pick the bundled glibc prebuilds, which don't load on NixOS
  env.npm_config_build_from_source = "true";

  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/calldiff
    cp -r node_modules $out/lib/calldiff/
    makeWrapper ${lib.getExe nodejs_22} $out/bin/calldiff \
      --add-flags $out/lib/calldiff/node_modules/calldiff/dist/cli.js
    runHook postInstall
  '';

  meta = {
    description = "Diff call stacks across git commits for agentic code review";
    homepage = "https://github.com/tanishqkancharla/calldiff";
    license = lib.licenses.mit;
    mainProgram = "calldiff";
  };
}
