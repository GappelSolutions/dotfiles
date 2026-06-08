{ lib, stdenv, writeShellApplication, coreutils, git, jujutsu, revdiff, wl-clipboard }:

writeShellApplication {
  name = "rd";
  runtimeInputs = [
    coreutils
    git
    jujutsu
    revdiff
  ] ++ lib.optionals stdenv.isLinux [
    wl-clipboard
  ];
  text = ''
    set -euo pipefail

    if repo_root="$(git rev-parse --show-toplevel 2>/dev/null)"; then
      :
    elif repo_root="$(jj root 2>/dev/null)"; then
      :
    else
      repo_root="$PWD"
    fi

    cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/revdiff"
    mkdir -p "$cache_dir"

    repo_name="''${repo_root##*/}"
    repo_id="$(printf '%s' "$repo_root" | cksum | cut -d ' ' -f1)"
    review_file="$cache_dir/''${repo_name}-''${repo_id}.md"

    args=(--compact --untracked --output "$review_file")
    if [ -s "$review_file" ]; then
      args+=(--annotations "$review_file")
    fi

    revdiff "''${args[@]}" "$@"
    status=$?

    if [ -s "$review_file" ]; then
      if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$review_file"
      elif command -v pbcopy >/dev/null 2>&1; then
        pbcopy < "$review_file"
      else
        printf 'rd: no clipboard utility found; review saved at %s\n' "$review_file" >&2
      fi
    fi

    exit "$status"
  '';
}
