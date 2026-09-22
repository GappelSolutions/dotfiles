{ lib, pkgs, ... }:

let
  repo = ../../..;
in
{
  # Seed only -- deliberately NOT home.file.
  #
  # home.file deploys a read-only /nix/store symlink, and T3 Code rewrites
  # userdata/settings.json itself whenever a project script, default model or
  # provider toggle changes. Managing it declaratively silently breaks that
  # write (the settings.json.hm-backup left over from an earlier attempt is
  # what that looked like). So: install the repo copy only when the file is
  # absent, then hand ownership to T3.
  #
  # Consequence: changes made in the T3 UI do not flow back. Refresh the repo
  # copy by hand when you want to keep them:
  #   cp ~/.t3/userdata/settings.json <repo>/t3/.t3/userdata/settings.json
  #
  # t3/projects.txt maps the UUIDs used as keys in settings.json to project
  # names. The project list itself lives only in state.sqlite and cannot be
  # seeded this way.
  home.activation.seedT3Settings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="$HOME/.t3/userdata/settings.json"
    if [ ! -e "$target" ]; then
      run ${pkgs.coreutils}/bin/install -Dm644 \
        ${repo + /t3/.t3/userdata/settings.json} "$target"
    fi
  '';
}
