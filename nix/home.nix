{ config, pkgs, inputs, ... }:

{
  home.username = "cgpp";
  home.homeDirectory = "/Users/cgpp";
  home.stateVersion = "24.05";

  # Let home-manager manage itself
  programs.home-manager.enable = true;

  # ==========================================================================
  # Packages
  # ==========================================================================
  home.packages = with pkgs; [
    # Core tools
    git
    age  # for agenix
    stow

    # Terminal & Shell
    zoxide
    fzf
    eza
    ripgrep
    fd
    bat
    delta  # git-delta

    # File managers & viewers
    yazi
    lazygit
    btop
    bottom
    lazydocker

    # Multiplexers
    zellij
    tmux

    # Development - Node
    nodejs
    pnpm

    # Cloud & DevOps
    gh
    sops

    # Utilities
    jq
    nerdfetch
    unar
    zip
    socat
    rclone
    wget
    pandoc
    ffmpeg
    luarocks
    rustup
    pipx
  ];

  # ==========================================================================
  # Program Configurations
  # ==========================================================================

  # Git
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

  # Delta (git pager)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # Zsh
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

      ssh-cloud = "ssh cgpp@192.168.178.33";
      ftp-cloud = "sftp cgpp@192.168.178.33";

      dcu = "docker-compose up -d --build";
      dcd = "docker-compose down";
      ld = "lazydocker";
      lg = "lazygit";

      ai = "claude --dangerously-skip-permissions";
      sz = "source ~/.zshrc";
      zr = "zellij run -i --";
      vi = "nvim";
      vim = "nvim --listen /tmp/nvim-server.pipe";

      py = "python3";
      pip = "pip3";

      # Nix rebuild alias
      rebuild = "sudo HOME=/var/root /nix/var/nix/profiles/default/bin/nix run nix-darwin -- switch --flake ~/dev/dotfiles/nix 2>&1 | grep --line-buffered -v \"builtins.toFile\"";
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

      # --- Syntax highlighting colors (set after plugin loads) ---
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

      # Bubble characters (Nerd Font powerline)
      _bubble_left=$'\ue0b6'
      _bubble_right=$'\ue0b4'
      _git_icon=$'\uf418'
      _apple_icon=$'\ue711'
      _dirty_icon='●'

      precmd() {
        vcs_info
        if [[ -n "''${vcs_info_msg_0_}" ]]; then
          if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
            _git_info="%K{yellow}%F{blue}''${_bubble_right}%f%F{black}  ''${_git_icon} ''${vcs_info_msg_0_} ''${_dirty_icon} %f%k%F{yellow}''${_bubble_right}%f"
          else
            _git_info="%K{green}%F{blue}''${_bubble_right}%f%F{black}  ''${_git_icon} ''${vcs_info_msg_0_} %f%k%F{green}''${_bubble_right}%f"
          fi
        else
          _git_info="%F{blue}''${_bubble_right}%f"
        fi
      }

      # Transient prompt
      _transient_accept_line() {
        local cmd="$BUFFER"
        print -n "\e[2A\e[J\r\e[35m\u276f\e[0m $cmd"
        zle accept-line
      }
      zle -N _transient_accept_line
      bindkey '^M' _transient_accept_line

      setopt PROMPT_SUBST
      PROMPT=$'\n %F{cyan}''${_bubble_left}%K{magenta} %K{red}%F{black}''${_apple_icon}%K{yellow} %K{blue}%F{green}''${_bubble_right}%f%F{blue}%K{blue}%F{black}  %~ %f%k''${_git_info}\n %F{magenta}╰─❯%f '

      # --- Tools ---
      eval "$(zoxide init zsh)"
      setopt nocaseglob

      # --- FZF ---
      [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

      # --- Editor ---
      if [[ -n "$NVIM_LISTEN_ADDRESS" ]]; then
        alias nvim="nvr -cc split --remote-wait +'set bufhidden=wipe'"
        export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
        export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
      else
        export VISUAL="nvim"
        export EDITOR="nvim"
      fi

      # --- Yazi integration ---
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # --- Paths ---
      export PATH="/Users/cgpp/.local/share/bob/nvim-bin:$PATH"
      export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
      export DOTNET_ROOT=/usr/local/share/dotnet
      export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
      export PATH="$PATH:$HOME/.dotnet/tools"
      export PNPM_HOME="/Users/cgpp/Library/pnpm"
      export PATH="$PNPM_HOME:$PATH"
      export PATH="$HOME/bin:$PATH"
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$HOME/.cargo/bin:$PATH"

      # --- Splash ---
      clear
      echo ""
      nerdfetch
      echo "\n"
    '';
  };

  # SSH
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "/Users/cgpp/.colima/ssh_config" ];
    matchBlocks = {
      "github.com-personal" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519";
        identitiesOnly = true;
      };
      "github.com-work" = {
        hostname = "github.com";
        user = "git";
        identityFile = "~/.ssh/id_ed25519_work";
        identitiesOnly = true;
      };
      "ssh.dev.azure.com" = {
        hostname = "ssh.dev.azure.com";
        user = "git";
        identityFile = "~/.ssh/id_azure_rsa";
        identitiesOnly = true;
      };
    };
  };

  # FZF
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # Bat (cat replacement)
  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
    };
  };

  # Lazygit
  programs.lazygit = {
    enable = true;
    # Settings are sourced from your existing config
  };

  # ==========================================================================
  # Dotfiles (xdg.configFile)
  # ==========================================================================
  # These symlink your existing configs into ~/.config
  # Point to the parent directory since we're in nix/ subdirectory

  xdg.configFile = {
    "nvim".source = ../nvim/.config/nvim;
    "alacritty".source = ../alacritty/.config/alacritty;
    "lazygit".source = ../lazygit/.config/lazygit;
    "yazi".source = ../yazi/.config/yazi;
    "zellij".source = ../zellij/.config/zellij;
  };

  # Aerospace config (lives in home directory, not .config)
  home.file.".aerospace.toml".source = ../aerospace/.aerospace.toml;

  # Claude Code config (only config files, not runtime data)
  home.file.".claude/CLAUDE.md".source = ../claude/.claude/CLAUDE.md;
  home.file.".claude/settings.json".source = ../claude/.claude/settings.json;
  home.file.".claude/commands".source = ../claude/.claude/commands;
  home.file.".claude/frameworks".source = ../claude/.claude/frameworks;
  home.file.".claude/statusline-command.sh".source = ../claude/.claude/statusline-command.sh;

  # ==========================================================================
  # Create directories
  # ==========================================================================
  home.activation.createDirs = config.lib.dag.entryAfter ["writeBoundary"] ''
    mkdir -p $HOME/dev
    mkdir -p $HOME/bin
    mkdir -p $HOME/.zsh/completions
    mkdir -p $HOME/.ssh
    chmod 700 $HOME/.ssh
  '';
}
