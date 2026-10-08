{ lib, pkgs, ... }:

let
  plugin = url: rev: hash: pkgs.fetchgit { inherit url rev hash; };

  # vt100 backend instead of curses: 24-bit colour, where curses rounds the theme to 256. The
  # patch gives :! and fullscreen vis:pipe programs (lazygit, yazi, tv) the normal screen,
  # draws every frame and that handover as synchronized updates (no flicker), draws :e once
  # (not the new window stacked below the old one first), makes <C-o> vim's: the jumplist gets
  # a jump's start, but not every : command (:w, :e), gives line numbers nvim's fixed width, and
  # shows the terminal's cursor on the primary one in nvim's shapes, for Rio's cursor trail,
  # and adds mouse support (none upstream): a click places the cursor and focuses its window,
  # a drag selects in visual mode, the wheel scrolls. libtermkey read SGR mouse reports as X10
  # ones (garbage coordinates) wherever terminfo's kmous is \E[< (xterm, rio, alacritty); its
  # CSI driver decodes both by itself.
  # dkjson for vis-lspc, whose fallback JSON decoder is quadratic in string length: tailwind's
  # 400 KB startup log froze vis for ~15s
  libtermkey = pkgs.libtermkey.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./patches/libtermkey-mouse.patch ];
  });
  vis = (pkgs.vis.override { inherit libtermkey; }).overrideAttrs (old: {
    configureFlags = (old.configureFlags or [ ]) ++ [ "--disable-curses" ];
    patches = (old.patches or [ ]) ++ [ ./patches/vis.patch ];
    postInstall = old.postInstall + ''
      wrapProgram $out/bin/vis \
        --prefix LUA_PATH ';' "${pkgs.lua.pkgs.dkjson}/share/lua/${pkgs.lua.luaversion}/?.lua"
    '';
  });

  # vis's "+ register, routed like nvim's clipboard (nvim/.config/nvim/lua/options.lua):
  # the dev clipboard bridge (OSC 52 fallback) over SSH, win32yank on WSL, else stock
  clipboard = pkgs.writeShellScriptBin "vis-clipboard" ''
    bridge=http://127.0.0.1:19777
    win32yank='/mnt/c/Program Files/Neovim/bin/win32yank.exe'
    action=
    for arg; do
      case $arg in --usable | --copy | --paste) action=$arg ;; esac
    done
    if [ -n "$SSH_TTY" ]; then
      up() { ${pkgs.curl}/bin/curl -fsS --max-time 0.2 $bridge/health >/dev/null 2>&1; }
      case $action in
        --usable) exit 0 ;;
        --paste) up && exec ${pkgs.curl}/bin/curl -fsS --max-time 1 $bridge/paste; exit 1 ;;
        --copy)
          text=$(cat; echo .)
          text=''${text%.}
          if up && printf %s "$text" | ${pkgs.curl}/bin/curl -fsS -X POST --data-binary @- $bridge/copy; then
            exit 0
          fi
          printf '\033]52;c;%s\a' "$(printf %s "$text" | base64 -w0)" >/dev/tty
          exit 0 ;;
      esac
    elif [ -n "$WSL_DISTRO_NAME" ] && [ -x "$win32yank" ]; then
      case $action in
        --usable) exit 0 ;;
        --copy) exec "$win32yank" -i --crlf ;;
        --paste) exec "$win32yank" -o --lf ;;
      esac
    fi
    exec ${vis}/bin/vis-clipboard "$@"
  '';
in
{
  home.packages = [
    vis
    (lib.hiPrio clipboard)
    pkgs.scooter
    pkgs.television
  ];

  xdg.configFile."vis/visrc.lua".source = ../../../vis/.config/vis/visrc.lua;
  xdg.configFile."vis/lua".source = ../../../vis/.config/vis/lua;
  xdg.configFile."vis/themes".source = ../../../vis/.config/vis/themes;
  xdg.configFile."vis/lexers".source = ../../../vis/.config/vis/lexers;

  # telescope for vis's pickers, iceberg like the rest
  xdg.configFile."television/config.toml".source = ../../../television/.config/television/config.toml;
  xdg.configFile."television/themes".source = ../../../television/.config/television/themes;
  programs.bat.themes.iceberg = {
    src = ../../../bat/.config/bat/themes;
    file = "iceberg.tmTheme";
  };

  xdg.configFile."vis/plugins".source = pkgs.linkFarm "vis-plugins" {
    vis-lspc = plugin "https://gitlab.com/muhq/vis-lspc"
      "9d0f7a0b82b1983b44636259733d6d2c39497315"
      "sha256-lA9ZzYeq7td5x5mBE8hCc7xzbRNMl8slm0H4o1P9dlc=";
    vis-fzf-mru = plugin "https://github.com/peaceant/vis-fzf-mru"
      "1e95326b27b70f4976c5acbd8c85e951697e71af"
      "sha256-u2OMS6uej9fkJvS1zZbRXFUiRqaxX9VLJH+Iyw0fJBU=";
    vis-commentary = plugin "https://github.com/lutobler/vis-commentary"
      "0e06ed8212c12c6651cb078b822390094b396f08"
      "sha256-ZsbCC4O/UOpfYm2mh4VqJXIUDGwfvFMJXl9sgENWNok=";
    vis-surround = plugin "https://repo.or.cz/vis-surround.git"
      "49674c957d9af22f4fbbe118d388bd3c81372a04"
      "sha256-ItNa1Uyr4x0KZi5By603klbaybHOWWMUWSMcMoNC084=";
    vis-pairs = plugin "https://repo.or.cz/vis-pairs.git"
      "65ed82e4f3bae6980f98c7247c3129f70fc8e22f"
      "sha256-t6JH/YsviBrplQNJbn+WViFKgKcuGNiHj4KJS3aR9sM=";
    vis-sneak = plugin "https://github.com/erf/vis-sneak"
      "57227d1a1cfc780ead6ada8c0190302c958a82fe"
      "sha256-JVBb9IfmsAHOPzgRJVd4zcIFYYbZh2vtjnmYInOjrRo=";
    vis-format = plugin "https://github.com/milhnl/vis-format"
      "1e37de7e9522383aa7bf769485767cfd0706c7e0"
      "sha256-Tfj1VxROhmJ72sNmpHhPoq5QxgvZM7Bu3coPoGzv3O4=";
    vis-editorconfig-options = plugin "https://github.com/milhnl/vis-editorconfig-options"
      "2f34c4501da79467f5b2af24708eae35e9918b45"
      "sha256-1u13Vd447JCidXlplWf7v5PxfZS7P4jqxhReX92lV2k=";
  };
}
