{ ... }:

let
  repo = ../../..;
in
{
  home.file.".codex/skills/pr-ready" = {
    source = repo + /codex/.codex/skills/pr-ready;
    force = true;
  };
}
