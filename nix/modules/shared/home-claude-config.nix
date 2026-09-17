{ pkgs, ... }:

let
  repo = ../../..;
in
{
  home.file.".claude/CLAUDE.md".source = repo + /claude/.claude/CLAUDE.md;
  home.file.".claude/settings.json".source = repo + /claude/.claude/settings.json;
  home.file.".claude/statusline-command.sh".source = repo + /claude/.claude/statusline-command.sh;
  # Ruleset injected once per main session by the SessionStart hook in
  # claude/.claude/settings.json. Standalone on purpose — no plugin, no skills,
  # no commands, nothing to install or keep in sync.
  home.file.".claude/caveman-ultra.md".source = repo + /claude/.claude/caveman-ultra.md;
  home.file.".claude/commands".source = pkgs.runCommand "claude-commands" {} ''
    mkdir -p $out/cl
    for f in ${repo}/claude/.claude/commands/*.md; do
      cp "$f" $out/
    done
    for f in ${repo}/claude/.claude/commands/cl/*.md; do
      cp "$f" $out/cl/
    done
  '';
  home.file.".local/bin/claude" = {
    executable = true;
    text = ''
      #!/bin/sh
      set -eu

      self="$HOME/.local/bin/claude"
      has_verbose=0
      for arg do
        if [ "$arg" = "--verbose" ]; then
          has_verbose=1
          break
        fi
      done

      old_ifs=$IFS
      IFS=:
      for dir in $PATH; do
        candidate="$dir/claude"
        if [ "$candidate" = "$self" ]; then
          continue
        fi
        if [ -x "$candidate" ]; then
          IFS=$old_ifs
          if [ "$has_verbose" -eq 1 ]; then
            exec "$candidate" "$@"
          fi
          exec "$candidate" --verbose "$@"
        fi
      done
      IFS=$old_ifs

      echo "claude: underlying executable not found" >&2
      exit 127
    '';
  };
}
