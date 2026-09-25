{ ... }:

let
  repo = ../../..;
in
{
  home.file.".claude/CLAUDE.md".source = repo + /claude/.claude/CLAUDE.md;
  home.file.".claude/settings.json".source = repo + /claude/.claude/settings.json;
  home.file.".claude/statusline-command.sh".source = repo + /claude/.claude/statusline-command.sh;
}
