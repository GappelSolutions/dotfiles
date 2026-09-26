{ pkgs, ... }:

{
  home.file.".claude/skills".source = ../../../claude/.claude/skills;
  home.file.".claude/agents".source = ../../../claude/.claude/agents;

  # Skill helper scripts (hitch-inspector) and ad-hoc agent scripting.
  home.packages = [ pkgs.python3 ];
}
