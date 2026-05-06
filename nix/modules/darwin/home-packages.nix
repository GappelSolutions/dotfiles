{ pkgs, inputs, ... }:

let
  zellij-welcome = pkgs.callPackage ../../rust/zellij-welcome { };
in
{
  home.packages = [
    zellij-welcome
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
