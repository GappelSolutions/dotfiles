{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "eza -l --icons=auto";
      lt = "eza --tree --level=1 --icons=auto";
      lsa = "eza -a --icons=auto";
      lla = "eza -al --icons=auto";
      lta = "eza -a --tree --level=1 --icons=auto";
      lg = "lazygit";
      t3c = "t3-connect connect";
      t3d = "t3-connect disconnect";
      t3s = "t3-connect status";
      docker = "podman";
      dcu = "podman-compose up -d --build";
      dcd = "podman-compose down";
      ld = "lazydocker";
      vi = "nvim";
      ai = "codex --dangerously-bypass-approvals-and-sandbox";
      rb = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix";
      rollback = "sudo nixos-rebuild switch --rollback";
      sz = "source ~/.bashrc";
      zel = "zellij attach welcome || zellij --session welcome --new-session-with-layout welcome-custom";
    };
    initExtra = ''
      # Agents (Claude Code's Bash) get GNU ls: eza rejects flags like -t.
      [[ -n $CLAUDECODE ]] || alias ls='eza --icons=auto'
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    '';
  };
}
