{ pkgs, ... }:

{
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      update_check = false;
    };
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
      t3c = "t3-connect connect";
      t3d = "t3-connect disconnect";
      t3s = "t3-connect status";
      docker = "podman";
      dcu = "podman-compose up -d --build";
      dcd = "podman-compose down";
      ld = "lazydocker";
      lo = "lazyops";
      ftp = "termscp";
      ai = "codex --dangerously-bypass-approvals-and-sandbox";
      vi = "nvim";
      vim = "nvim";
      py = "python3";
      pip = "pip3";
      nerdfetch = "$HOME/.local/bin/nerdfetch";
      rb = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix";
      rbl = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#cgpp-t14-nix-lite";
      rbw = "sudo nixos-rebuild switch --flake ~/dev/misc/dotfiles/nix#wsl";
      rollback = "sudo nixos-rebuild switch --rollback";
      sz = "source ~/.zshrc";
      zr = "zellij run -i --";
      dr = "devenv tasks run";
    };

    # .zshenv: sourced by every zsh invocation, including non-interactive
    # ones (agents, scripts). Keeping the PAT here means az never falls back
    # to a cached az-login AAD token, which expires every ~week.
    envExtra = ''
      # --- Secrets ---
      [[ -r ~/.azure-devops-pat ]] && export AZURE_DEVOPS_EXT_PAT="$(<~/.azure-devops-pat)"
    '';

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
      PROMPT=$'\n %F{blue}''${_bubble_left}%K{blue}%F{black} ''${_host_icon} %K{green}%F{blue}''${_bubble_right}%F{black}  %~ %f%k''${_git_info}\n %F{blue}╰─❯%f '

      # --- Tools ---
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh)"
      setopt nocaseglob
      [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

      # devenv tasks/scripts + bun run/package.json scripts, tab-completable
      command -v devenv >/dev/null && eval "$(COMPLETE=zsh devenv)"
      command -v bun >/dev/null && source <(bun completions)

      export VISUAL="nvim"
      export EDITOR="nvim"

      # --- OpenShift login ---
      # Credentials live in ~/.okd-credentials (mode 600), same pattern as
      # ~/.azure-devops-pat. CA bundles per cluster in ~/.okd-ca/<host>.crt so
      # logins stay TLS-verified instead of --insecure-skip-tls-verify.
      OKD_CLUSTERS=(api.okd.ensor.test api.dev.ensor.test)

      # Trust-on-first-use: pull the served chain, show issuer + fingerprint,
      # pin the root only after explicit confirmation.
      _ocl_fetch_ca() {
        local host="$1" cadir=~/.okd-ca
        local ca="$cadir/$host.crt" chain
        chain=$(openssl s_client -showcerts -connect "$host:6443" </dev/null 2>/dev/null)
        if [[ -z $chain ]]; then
          echo "ocl: could not reach $host:6443" >&2
          return 1
        fi
        # last cert in the chain is the signer OKD self-signs the API cert with
        local root
        root=$(printf '%s\n' "$chain" | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
          | awk '/-----BEGIN CERTIFICATE-----/{n++} {a[n]=a[n] $0 "\n"} END{printf "%s", a[n]}')
        echo "ocl: certificate offered by $host"
        printf '%s' "$root" | openssl x509 -noout -issuer -subject -dates -fingerprint -sha256
        local ok
        read -r "ok?Trust this CA for $host? [y/N] "
        [[ $ok == [yY] ]] || return 1
        mkdir -p "$cadir"
        printf '%s' "$root" > "$ca"
        chmod 644 "$ca"
        echo "ocl: pinned $ca"
      }

      ocl() {
        local creds=~/.okd-credentials cadir=~/.okd-ca
        local user password save

        if [[ -r $creds ]]; then
          user=$(sed -n 's/^OKD_USER=//p' "$creds" | head -1)
          password=$(sed -n 's/^OKD_PASSWORD=//p' "$creds" | head -1)
        fi

        if [[ -z $user || -z $password ]]; then
          read -r "user?OKD username: "
          read -rs "password?OKD password: "; echo
          if [[ -z $user || -z $password ]]; then
            echo "ocl: aborted, empty credentials" >&2
            return 1
          fi
          read -r "save?Save credentials to $creds? [y/N] "
          if [[ $save == [yY] ]]; then
            ( umask 077; printf 'OKD_USER=%s\nOKD_PASSWORD=%s\n' "$user" "$password" > "$creds" )
          fi
        fi

        local host ca rc=0
        for host in $OKD_CLUSTERS; do
          ca="$cadir/$host.crt"
          if [[ ! -r $ca ]]; then
            _ocl_fetch_ca "$host" || { echo "ocl: skipping $host (no trusted CA)" >&2; rc=1; continue; }
          fi
          echo "ocl: logging into https://$host:6443"
          oc login "https://$host:6443" --certificate-authority="$ca" -u "$user" -p "$password" || rc=1
        done
        return $rc
      }

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
      zex() { _zj elixir; }
      zgs() { _zj gappel-solutions; }
      zdc() { _zj decon; }
      zco() { _zj colony; }
      zig() { _zj iggy; }
      zmm() { _zj mmgdm; }
      zwa() { _zj watcher; }

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

      # if [[ -z "$ZELLIJ" ]]; then
      #   zellij attach welcome || zellij --session welcome --new-session-with-layout welcome-custom
      # fi

      clear
      $HOME/.local/bin/nerdfetch
      echo "\n"
    '';
  };
}
