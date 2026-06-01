{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -l --icons";
      lt = "eza --tree --level=1 --icons";
      lsa = "eza -a --icons";
      lla = "eza -al --icons";
      lta = "eza -a --tree --level=1 --icons";
      lg = "lazygit";
      docker = "podman";
      dcu = "podman-compose up -d --build";
      dcd = "podman-compose down";
      ld = "lazydocker";
      vi = "nvim";
      ai = "codex --dangerously-bypass-approvals-and-sandbox";
      rb = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix";
      rbl = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix-lite";
      sz = "source ~/.bashrc";
      zel = "zellij attach welcome || zellij --session welcome --new-session-with-layout welcome-custom";
    };
    initExtra = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    '';
  };
}
