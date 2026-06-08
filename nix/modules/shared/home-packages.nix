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
    dotnet-sdk
    gcc
    gnumake
    cmake
    pkg-config
    gh
    jq
    unzip
    zip
    wget
    pandoc
    ffmpeg
    rustup
    sshpass
    neovim
  ]);
}
