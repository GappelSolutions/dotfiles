{ pkgs, ... }:

let
  zellij-welcome = pkgs.callPackage ../../rust/zellij-welcome { };
in
{
  home.packages = [
    zellij-welcome
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
