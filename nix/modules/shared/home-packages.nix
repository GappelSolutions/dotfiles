{ config, pkgs, inputs, ... }:

let
  zellij-welcome = pkgs.callPackage ../../rust/zellij-welcome { };
  lazyops = inputs.lazyops.packages.${pkgs.system}.default;
  oh-my-pi = pkgs.callPackage ../../pkgs/oh-my-pi/package.nix { };
  agent-of-empires = pkgs.callPackage ../../pkgs/agent-of-empires/package.nix { };
  revdiff = pkgs.callPackage ../../pkgs/revdiff/package.nix { };
  rd = pkgs.callPackage ../../pkgs/rd/package.nix {
    inherit (pkgs) coreutils git jujutsu wl-clipboard;
    inherit revdiff;
  };
  # Global dotnet tools (e.g. easy-dotnet.nvim's dotnet-easydotnet) are built
  # against whatever SDK the tool author had; a single sdk_10 install has no
  # 8.x shared runtime for their apphost to resolve. combinePackages merges
  # both SDKs' runtimes/hostfxr into one dotnet root so apphost roll-forward
  # can find a match.
  dotnet = pkgs.dotnetCorePackages.combinePackages [
    pkgs.dotnetCorePackages.sdk_10_0
    pkgs.dotnetCorePackages.sdk_8_0
  ];
in
{
  home.packages = [
    zellij-welcome
    oh-my-pi
    agent-of-empires
    revdiff
    rd
    lazyops
    dotnet
    inputs.agenix.packages.${pkgs.system}.default
    pkgs.jujutsu
    pkgs.claude-code
    pkgs.codex
    # T3 Code drives local models through its opencode provider (needs >= 1.14.19).
    pkgs.opencode
    pkgs.playwright-driver.browsers
    pkgs.pipx
  ] ++ (with pkgs; [
    git
    zoxide
    fzf
    eza
    ripgrep
    fd
    bat
    delta
    yazi
    termscp
    ueberzugpp
    chafa
    imagemagick
    ffmpegthumbnailer
    poppler-utils
    lazygit
    lazydocker
    btop
    bottom
    zellij
    tmux
    nodejs
    bun
    gcc
    gnumake
    cmake
    pkg-config
    tree-sitter
    gh
    jq
    bc
    unzip
    zip
    wget
    pandoc
    ffmpeg
    rustup
    sshpass
    neovim
    (azure-cli.withExtensions [ azure-cli-extensions.azure-devops ])
    openshift
    openssl
    openbao
    k9s
    tealdeer
  ]);

  home.sessionVariables.DOTNET_ROOT = "${dotnet}/share/dotnet";

  # Playwright's own browser downloads are pinned to whatever revision each
  # project's @playwright/test happens to depend on, and constantly drift out
  # of sync with nixpkgs' bundled browsers - point at the Nix-provided ones
  # instead and refuse the per-project download entirely.
  home.sessionVariables.PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
  home.sessionVariables.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";

  # nx (the Nx monorepo/build CLI, used by the Angular Customer Portal repo)
  # isn't packaged in nixpkgs. Install/update it globally via bun instead;
  # its bin dir (~/.bun/bin) is already on sessionPath.
  home.activation.installNx = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    BUN_INSTALL="${config.home.homeDirectory}/.bun" ${pkgs.bun}/bin/bun install -g nx >/dev/null 2>&1 || true
  '';

  # claude-session-analyzer (csa): analyzes Claude Code session transcripts
  # for token usage/cost/timing. Not packaged in nixpkgs; install/update it
  # via pipx instead. Its bin dir (~/.local/bin) is already on sessionPath.
  home.activation.installClaudeSessionAnalyzer = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.pipx}/bin/pipx install --force claude-session-analyzer >/dev/null 2>&1 || true
  '';
}
