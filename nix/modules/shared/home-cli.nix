{ config, pkgs, ... }:

let
  zellij-welcome = pkgs.callPackage ../../rust/zellij-welcome { };
in
{
  home.stateVersion = "24.05";

  manual.manpages.enable = false;

  home.sessionVariables = {
    ZELLIJ_SOCKET_DIR = "/tmp/zellij";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.bun/bin"
    "${config.home.homeDirectory}/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.dotnet/tools"
    "${config.home.homeDirectory}/.cargo/bin"
  ];

  home.packages = [
    zellij-welcome
  ] ++ (with pkgs; [
    git
    zoxide
    fzf
    eza
    ripgrep
    fd
    bat
    delta
    yazi
    ueberzugpp
    chafa
    imagemagick
    ffmpegthumbnailer
    poppler-utils
    lazygit
    lazydocker
    btop
    bottom
    zellij
    tmux
    nodejs
    bun
    dotnet-sdk
    gcc
    gnumake
    cmake
    pkg-config
    gh
    jq
    unzip
    zip
    wget
    pandoc
    ffmpeg
    rustup
    sshpass
    neovim
  ]);

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings = {
      user.name = "Christian Gappel";
      user.email = "aichelberg2@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf.enable = true;

  programs.bat = {
    enable = true;
    config.theme = "TwoDark";
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -l --icons";
      lt = "eza --tree --level=1 --icons";
      lsa = "eza -a --icons";
      lla = "eza -al --icons";
      lta = "eza -a --tree --level=1 --icons";
      lg = "lazygit";
      docker = "podman";
      dcu = "podman-compose up -d --build";
      dcd = "podman-compose down";
      ld = "lazydocker";
      vi = "nvim";
      ai = "codex --dangerously-bypass-approvals-and-sandbox";
      rb = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix";
      rbl = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix-lite";
      sz = "source ~/.bashrc";
      zel = "zellij attach welcome || zellij --session welcome --new-session-with-layout welcome-custom";
    };
    initExtra = ''
      eval "$(${pkgs.zoxide}/bin/zoxide init bash)"
    '';
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      share = true;
      ignoreDups = true;
      ignoreSpace = true;
    };

    shellAliases = {
      ls = "eza --icons";
      ll = "eza -l --icons";
      lt = "eza --tree --level=1 --icons";
      lsa = "eza -a --icons";
      lla = "eza -al --icons";
      lta = "eza -a --tree --level=1 --icons";
      lg = "lazygit";
      docker = "podman";
      dcu = "podman-compose up -d --build";
      dcd = "podman-compose down";
      ld = "lazydocker";
      ai = "codex --dangerously-bypass-approvals-and-sandbox";
      vi = "nvim";
      vim = "nvim";
      py = "python3";
      pip = "pip3";
      nerdfetch = "$HOME/.local/bin/nerdfetch";
      rb = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix";
      rbl = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix-lite";
      sz = "source ~/.zshrc";
      zr = "zellij run -i --";
    };

    initContent = ''
      # --- Completion ---
      fpath=(~/.zsh/completions $fpath)
      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
      zstyle ':completion:*:warnings' format '%F{red}No matches%f'

      # --- Colors ---
      export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
      export CLICOLOR=1

      # --- Autosuggest ---
      ZSH_AUTOSUGGEST_STRATEGY=(history completion)
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
      bindkey '^f' autosuggest-accept

      # --- Syntax highlighting colors ---
      typeset -gA ZSH_HIGHLIGHT_STYLES
      ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
      ZSH_HIGHLIGHT_STYLES[builtin]='fg=green,bold'
      ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
      ZSH_HIGHLIGHT_STYLES[function]='fg=cyan,bold'
      ZSH_HIGHLIGHT_STYLES[path]='fg=blue,underline'
      ZSH_HIGHLIGHT_STYLES[globbing]='fg=magenta'
      ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=yellow'
      ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=yellow'

      # --- Prompt ---
      autoload -Uz vcs_info
      zstyle ':vcs_info:git:*' formats '%b'
      zstyle ':vcs_info:git:*' actionformats '%b|%a'

      _bubble_left=$'\ue0b6'
      _bubble_right=$'\ue0b4'
      _git_icon=$'\uf418'
      _host_icon=$'\uf313'
      _dirty_icon='●'

      precmd() {
        vcs_info
        if [[ -n "''${vcs_info_msg_0_}" ]]; then
          if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            _git_info="%K{yellow}%F{green}''${_bubble_right}%f%F{black}  ''${_git_icon} ''${vcs_info_msg_0_} ''${_dirty_icon} %f%k%F{yellow}''${_bubble_right}%f"
          else
            _git_info="%K{blue}%F{green}''${_bubble_right}%f%F{black}  ''${_git_icon} ''${vcs_info_msg_0_} %f%k%F{blue}''${_bubble_right}%f"
          fi
        else
          _git_info="%F{green}''${_bubble_right}%f"
        fi
      }

      _transient_accept_line() {
        local cmd="$BUFFER"
        print -n "\e[2A\e[J\r\e[32m\u276f\e[0m $cmd"
        zle accept-line
      }
      zle -N _transient_accept_line
      bindkey '^M' _transient_accept_line

      setopt PROMPT_SUBST
      PROMPT=$'\n %F{blue}''${_bubble_left}%K{blue}%F{black} ''${_host_icon}  %K{green}%F{blue}''${_bubble_right}%F{black}  %~ %f%k''${_git_info}\n %F{blue}╰─❯%f '

      # --- Tools ---
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
      setopt nocaseglob
      [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

      export VISUAL="nvim"
      export EDITOR="nvim"

      # --- Zellij session helpers ---
      _zj() {
        local layout="$1"
        local existing=$(zellij list-sessions 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' | grep "^$layout-" | grep -v "EXITED" | awk '{print $1}' | head -1)
        if [[ -n "$existing" ]]; then
          zellij action switch-session "$existing"
        else
          zellij action switch-session "$layout-$(date +%Y%m%d-%H%M%S)" -l "$layout"
        fi
      }
      zeb() { _zj energyboard; }
      zbo() { _zj backoffice; }
      zea() { _zj easyasset; }
      zex() { _zj elixir; }
      zgs() { _zj gappel-solutions; }
      zdc() { _zj decon; }
      zsc() { _zj screensaver; }
      zlc() { _zj lazychat; }
      zco() { _zj colony; }
      zms() { _zj msp; }
      zsf() { _zj smartflex; }
      zll() { _zj lazylink; }

      zel() {
        zellij attach welcome || zellij --session welcome --new-session-with-layout welcome-custom
      }

      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      clear
      $HOME/.local/bin/nerdfetch
      echo "\n"
    '';
  };
}
