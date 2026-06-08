{ pkgs, ... }:

let
  zellij-welcome = pkgs.callPackage ../../rust/zellij-welcome { };
  oh-my-pi = pkgs.callPackage ../../pkgs/oh-my-pi/package.nix { };
  agent-of-empires = pkgs.callPackage ../../pkgs/agent-of-empires/package.nix { };
  revdiff = pkgs.callPackage ../../pkgs/revdiff/package.nix { };
  rd = pkgs.callPackage ../../pkgs/rd/package.nix {
    inherit (pkgs) coreutils git jujutsu wl-clipboard;
    inherit revdiff;
  };
in
{
  home.packages = [
    zellij-welcome
    oh-my-pi
    agent-of-empires
    revdiff
    rd
    pkgs.jujutsu
    pkgs.codex
    pkgs.godot_4-mono
  ] ++ (with pkgs; [
    git
    age
    stow

    zoxide
    fzf
    eza
    ripgrep
    fd
    bat
    delta

    yazi
    lazygit
    btop
    bottom
    lazydocker

    zellij
    tmux
    neovim

    nodejs
    bun
    bruno
    gh
    sops

    typst
    qpdf

    jq
    nerdfetch
    unar
    zip
    socat
    rclone
    wget
    pandoc
    ffmpeg
    luarocks
    rustup
    pipx
    sshpass
  ]);
}
