{ config, pkgs, ... }:

let
  repo = ../../..;
in
{
  xdg.configFile = {
    "nvim".source = repo + /nvim/.config/nvim;
    "alacritty".source = repo + /alacritty/.config/alacritty;
    "lazygit".source = repo + /lazygit/.config/lazygit;
    "yazi".source = repo + /yazi/.config/yazi;
    "zellij".source = repo + /zellij/.config/zellij;
    "Code/User/settings.json".source = repo + /vscode/.config/Code/Users/settings.json;
  };

  home.file.".aerospace.toml".source = repo + /aerospace/.aerospace.toml;
  home.file.".vimrc".source = repo + /vim/.vimrc;
  home.file.".ideavimrc".source = repo + /jetbrains/.ideavimrc;

  home.file.".claude/CLAUDE.md".source = repo + /claude/.claude/CLAUDE.md;
  home.file.".claude/settings.json".source = repo + /claude/.claude/settings.json;
  home.file.".claude/commands".source = pkgs.runCommand "claude-commands" {} ''
    mkdir -p $out/cl
    for f in ${repo}/claude/.claude/commands/*.md; do
      cp "$f" $out/
    done
    for f in ${repo}/claude/.claude/commands/cl/*.md; do
      cp "$f" $out/cl/
    done
  '';
  home.file.".claude/statusline-command.sh".source = repo + /claude/.claude/statusline-command.sh;

  home.file.".codex/AGENTS.md".source = repo + /codex/.codex/AGENTS.md;
  home.file.".codex/skills/pr-ready" = {
    source = repo + /codex/.codex/skills/pr-ready;
    force = true;
  };

  home.file.".local/bin/nerdfetch" = {
    source = ../../scripts/nerdfetch;
    executable = true;
  };

  home.activation.createDirs = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/dev
    mkdir -p $HOME/bin
    mkdir -p $HOME/.zsh/completions
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
  '';
}
