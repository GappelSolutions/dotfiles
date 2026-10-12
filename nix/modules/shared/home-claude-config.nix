{ lib, pkgs, ... }:

let
  repo = ../../..;
in
{
  home.file.".claude/CLAUDE.md".source = repo + /claude/.claude/CLAUDE.md;
  home.file.".claude/settings.json".source = repo + /claude/.claude/settings.json;
  home.file.".claude/statusline-command.sh".source = repo + /claude/.claude/statusline-command.sh;
  home.file.".claude/hooks/usage-limit.sh".source = repo + /claude/.claude/hooks/usage-limit.sh;

  # User-scope MCP servers live in ~/.claude.json, which Claude Code rewrites
  # constantly (sessions, OAuth state), so it can't be a store symlink. Merge
  # the repo's servers into it instead; servers added by hand are kept.
  home.activation.mergeClaudeMcpServers = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.claude.json"
    if [ -z "''${DRY_RUN:-}" ]; then
      [ -e "$target" ] || echo '{}' > "$target"
      tmp="$(mktemp "$target.XXXXXX")"
      ${pkgs.jq}/bin/jq --slurpfile servers ${repo + /claude/.claude/mcp-servers.json} \
        '.mcpServers = ((.mcpServers // {}) + $servers[0])' "$target" > "$tmp"
      chmod 600 "$tmp"
      mv "$tmp" "$target"
    fi
  '';
}
