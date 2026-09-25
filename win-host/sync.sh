#!/usr/bin/env bash
# Sync the Windows-native configs between this repo and the Windows user
# profile. Runs from WSL. What goes where lives in win-host/manifest.
#
#   win-host/sync.sh [status]   what differs, read-only (default)
#   win-host/sync.sh diff       same, with the actual diffs
#   win-host/sync.sh pull       Windows -> repo
#   win-host/sync.sh push       repo -> Windows; anything overwritten is first
#                               backed up to %USERPROFILE%\.dotfiles-sync-backup\
#
# Why copies and not symlinks: Windows apps cannot follow WSL symlinks, and
# \\wsl$\ paths are slow and flaky for things like Alacritty and komorebi.
#
# WIN_HOME overrides the Windows profile path (default: %USERPROFILE%).
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
manifest="$repo/win-host/manifest"
cmd="${1:-status}"

case "$cmd" in
  status|diff|pull|push) ;;
  *) echo "usage: $0 [status|diff|pull|push]" >&2; exit 2 ;;
esac

if [ -n "${WIN_HOME:-}" ]; then
  home="$WIN_HOME"
else
  # cmd.exe complains about a UNC cwd, so run it from a Windows path.
  win_profile="$(cd /mnt/c && cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"
  [ -n "$win_profile" ] || { echo "error: cannot resolve %USERPROFILE% -- not WSL?" >&2; exit 1; }
  home="$(wslpath -u "$win_profile")"
fi
[ -d "$home" ] || { echo "error: $home does not exist" >&2; exit 1; }

backup_root="$home/.dotfiles-sync-backup/$(date +%Y%m%d-%H%M%S)"

# The native Windows zellij can't use the shared config verbatim: no bash to
# run the tab-naming bind (bash.exe is the WSL launcher and would talk to the
# WSL zellij server), a different clipboard, and pwsh as the shell. zellij has
# no includes, so derive the Windows file from the shared one. Every rule must
# match exactly once -- if the shared config changes shape, this fails loudly
# instead of silently shipping a half-converted file.
render_zellij() {
  perl -e '
    local $/; my $s = <STDIN>;
    my @rules = (
      [ qr{^copy_command "zellij-copy"[^\n]*$}m, q{copy_command "win32yank.exe -i --crlf"} ],
      [ qr{^// default_shell "fish"$}m,          q{default_shell "pwsh.exe"} ],
      [ qr{^// default_layout "compact"$}m,      q{default_layout "compact"} ],
      [ qr{bind "n" \{\n\s*Run "bash" "-c" "N=\$\(zellij action query-tab-names[^\n]*\n(?:[^\n]*\n)*?\s*SwitchToMode "locked"\n\s*\}},
        q{bind "n" { NewTab; SwitchToMode "locked"; }} ],
    );
    for my $i (0 .. $#rules) {
      my ($re, $to) = @{ $rules[$i] };
      my $n = () = $s =~ /$re/g;
      die "render_zellij: rule $i matched $n times, expected 1 -- zellij/.config/zellij/config.kdl changed shape, update win-host/sync.sh\n"
        unless $n == 1;
      $s =~ s/$re/$to/;
    }
    print $s;
  ' < "$1"
}

is_shared() { case "$1" in win-host/*) return 1 ;; *) return 0 ;; esac; }

# One "mode repo-path windows-path" line per concrete file; dir entries are
# expanded to the union of files on both sides.
entries() {
  grep -vE '^[[:space:]]*(#|$)' "$manifest" | while read -r mode rp wp; do
    if [ "$mode" = dir ]; then
      {
        [ -d "$repo/$rp" ] && (cd "$repo/$rp" && find . -type f)
        [ -d "$home/$wp" ] && (cd "$home/$wp" && find . -type f)
      } | sed 's|^\./||' | sort -u | while read -r f; do
        echo "file $rp/$f $wp/$f"
      done
    else
      echo "$mode $rp $wp"
    fi
  done
}

# What the Windows side should contain, on stdout.
wanted() {
  local mode="$1" rp="$2"
  if [ "$mode" = render ]; then
    render_zellij "$repo/$rp"
  else
    cat "$repo/$rp"
  fi
}

# Shared files are compared ignoring CRs: Windows tools may have rewritten
# them CRLF, which is not a real difference.
same() {
  local mode="$1" rp="$2" wp="$3"
  if is_shared "$rp"; then
    cmp -s <(wanted "$mode" "$rp" | tr -d '\r') <(tr -d '\r' < "$home/$wp")
  else
    cmp -s <(wanted "$mode" "$rp") "$home/$wp"
  fi
}

put_windows() {
  local mode="$1" rp="$2" wp="$3" dst="$home/$3"
  if [ -e "$dst" ]; then
    mkdir -p "$(dirname "$backup_root/$wp")"
    cp -p "$dst" "$backup_root/$wp"
  fi
  mkdir -p "$(dirname "$dst")"
  wanted "$mode" "$rp" > "$dst.sync-tmp"
  mv -f "$dst.sync-tmp" "$dst"
}

get_windows() {
  local rp="$1" src="$home/$2" dst="$repo/$1"
  mkdir -p "$(dirname "$dst")"
  if is_shared "$rp"; then
    tr -d '\r' < "$src" > "$dst"
  else
    cp "$src" "$dst"
  fi
  # /mnt/c reports everything as 0777; don't let git record it as executable.
  chmod 644 "$dst"
}

refresh_t3_projects() {
  local db="$home/.t3/userdata/state.sqlite" out="$repo/win-host/.t3/projects.txt"
  [ -e "$db" ] || return 0
  local sqlite=(sqlite3)
  command -v sqlite3 >/dev/null 2>&1 || sqlite=(nix run nixpkgs#sqlite --)
  {
    echo "# Windows T3 Code projects, exported by win-host/sync.sh pull."
    echo "# Maps the UUID keys in .t3/userdata/settings.json to project names."
    echo "# The project list itself lives only in state.sqlite; re-add by hand."
    echo "#"
    echo "# uuid  title  workspace_root"
    echo
    # immutable=1: T3 holds the DB open and /mnt/c can't do sqlite locking.
    "${sqlite[@]}" "file:$db?immutable=1" \
      "select project_id||'  '||title||'  '||workspace_root from projection_projects where deleted_at is null order by title"
  } > "$out.tmp" && mv "$out.tmp" "$out"
}

changed=0
while read -r mode rp wp; do
  have_repo=0; have_win=0
  [ -e "$repo/$rp" ] && have_repo=1
  [ -e "$home/$wp" ] && have_win=1

  if [ $have_repo = 1 ] && [ $have_win = 1 ] && same "$mode" "$rp" "$wp"; then
    continue
  fi

  case "$cmd" in
    status|diff)
      if [ $have_repo = 0 ]; then state="only on Windows"
      elif [ $have_win = 0 ]; then state="only in repo"
      else state="differs"; fi
      printf '%-16s %-7s %s\n' "$state" "$mode" "$rp"
      if [ "$cmd" = diff ] && [ $have_repo = 1 ] && [ $have_win = 1 ]; then
        diff -u --label "repo:$rp" --label "windows:$wp" \
          <(wanted "$mode" "$rp" | tr -d '\r') <(tr -d '\r' < "$home/$wp") || true
      fi
      changed=1
      ;;
    pull)
      [ $have_win = 1 ] || continue
      if [ "$mode" = render ]; then
        echo "drift   $wp was edited on Windows -- port the change into $rp by hand:"
        diff -u --label "rendered:$rp" --label "windows:$wp" \
          <(wanted "$mode" "$rp" | tr -d '\r') <(tr -d '\r' < "$home/$wp") || true
      else
        get_windows "$rp" "$wp"
        echo "pulled  $rp"
      fi
      changed=1
      ;;
    push)
      [ $have_repo = 1 ] || continue
      if [ "$mode" = seed ] && [ $have_win = 1 ]; then
        continue
      fi
      put_windows "$mode" "$rp" "$wp"
      echo "pushed  $wp"
      changed=1
      ;;
  esac
done < <(entries)

if [ "$cmd" = pull ]; then
  refresh_t3_projects
fi

if [ $changed = 0 ]; then
  echo "in sync"
elif [ "$cmd" = push ] && [ -d "$backup_root" ]; then
  echo "previous Windows copies saved under $(wslpath -w "$backup_root")"
fi
