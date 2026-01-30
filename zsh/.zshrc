# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE appendhistory

# --- Completion ---
fpath=(~/.zsh/completions $fpath)
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'
zstyle ':completion:*:warnings' format '%F{red}No matches%f'

# --- Colors ---
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
export CLICOLOR=1

# --- Plugins (Homebrew) ---
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
bindkey '^f' autosuggest-accept

# Syntax highlighting colors
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
  if [[ -n "${vcs_info_msg_0_}" ]]; then
    if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
      _git_info="%K{yellow}%F{blue}${_bubble_right}%f%F{black}  ${_git_icon} ${vcs_info_msg_0_} ${_dirty_icon} %f%k%F{yellow}${_bubble_right}%f"
    else
      _git_info="%K{green}%F{blue}${_bubble_right}%f%F{black}  ${_git_icon} ${vcs_info_msg_0_} %f%k%F{green}${_bubble_right}%f"
    fi
  else
    _git_info="%F{blue}${_bubble_right}%f"
  fi
}

# Transient prompt - collapse to minimal on Enter
_transient_accept_line() {
  local cmd="$BUFFER"

  # Clear the 3-line prompt, go to column 1, print minimal prompt
  print -n "\e[2A\e[J\r\e[35m\u276f\e[0m $cmd"

  # Accept and execute
  zle accept-line
}
zle -N _transient_accept_line
bindkey '^M' _transient_accept_line

setopt PROMPT_SUBST
PROMPT=$'\n %F{cyan}${_bubble_left}%K{magenta} %K{red}%F{black}${_apple_icon}%K{yellow} %K{blue}%F{green}${_bubble_right}%f%F{blue}%K{blue}%F{black}  %~ %f%k${_git_info}\n %F{magenta}╰─❯%f '

# --- Tools ---
eval "$(zoxide init zsh)"
source <(ng completion script) 2>/dev/null || true
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

# --- Aliases ---
alias ls='eza --icons'
alias ll='eza -l --icons'
alias lt='eza --tree --level=1 --icons'
alias lsa='eza -a --icons'
alias lla='eza -al --icons'
alias lta='eza -a --tree --level=1 --icons'
alias ssh-cloud="ssh cgpp@192.168.178.33"
alias ftp-cloud="sftp cgpp@192.168.178.33"
alias cvpn="sudo systemctl start openvpn-client@client1"
alias dcu="docker-compose up -d --build"
alias dcd="docker-compose down"
alias ld='lazydocker'
alias stowm='stow -v -R -t ~'
alias dnbo='dotnet watch run --project="Evulution.BackOffice.Webapi"'
alias dneb='dotnet watch run --project="Repower.CustomerPortal.Webapi" --launch-profile="eb"'
alias ai='claude --dangerously-skip-permissions'
alias db='rainfrog --driver postgresql --username cgpp --password ASDQWEasdqweASDQWE123 --host localhost --port 5430 --database gappel-cloud'
alias dotnet-csharpier='dotnet csharpier'
alias sz='source ~/.zshrc'
alias zr='zellij run -i --'
alias vi='nvim'
alias vim='nvim --listen /tmp/nvim-server.pipe'
alias sc="~/bin/macos-screensaver"
alias lg="lazygit"
alias wt="/Applications/work-tuimer-macos-aarch64"
alias notifs-on='cp ~/.claude/settings-notifs-on.json ~/.claude/settings.json'
alias notifs-off='cp ~/.claude/settings-notifs-off.json ~/.claude/settings.json'
alias py="python3"
alias pip="pip3"

# --- Paths ---
export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"
export PATH="/Users/cgpp/.local/share/bob/nvim-bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
export PATH="$PATH:$HOME/.dotnet/tools"
export PNPM_HOME="/Users/cgpp/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH="/usr/local/share/dotnet:$PATH"
mkdir -p ~/bin
export PATH=~/bin:$PATH
export PATH="$PATH:/Users/cgpp/.local/bin"
export PATH=/Users/cgpp/.opencode/bin:$PATH
export PATH=~/.local/bin:$PATH

# --- Yazi integration ---
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# --- Vim wrapper ---
if [[ ! -f ~/bin/vim ]]; then
  cat > ~/bin/vim << 'EOF'
#!/bin/bash
if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
  /usr/bin/vim "$@"
else
  /Users/cgpp/.local/share/bob/nvim-bin/nvim "$@"
fi
EOF
  chmod +x ~/bin/vim
fi

# --- Splash screen ---
clear
echo ""
nerdfetch
echo "\n"
