{ ... }:

let
  repo = ../../..;
in
{
  home.file.".codex/AGENTS.md".source = repo + /codex/.codex/AGENTS.md;
  home.file.".codex/skills/pr-ready" = {
    source = repo + /codex/.codex/skills/pr-ready;
    force = true;
  };
}
