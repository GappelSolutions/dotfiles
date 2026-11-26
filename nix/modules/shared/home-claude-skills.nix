{ pkgs, ... }:

{
  home.file.".claude/skills".source = ../../../claude/.claude/skills;
  home.file.".claude/agents".source = ../../../claude/.claude/agents;

  # Skill helper scripts (hitch-inspector, hitch-map) and ad-hoc agent scripting;
  # mermaid-cli renders the hitch Plan diagrams (Azure only renders Mermaid in wikis);
  # nvd diffs a host's closure for hitch-focus's Nix effects.
  home.packages = [ pkgs.python3 pkgs.mermaid-cli pkgs.nvd ];
}
