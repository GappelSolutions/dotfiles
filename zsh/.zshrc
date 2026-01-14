# --- Completions ---
if [[ ":$FPATH:" != *":/Users/cgpp/.zsh/completions:"* ]]; then
  export FPATH="/Users/cgpp/.zsh/completions:$FPATH"
fi
autoload -Uz compinit
compinit

# --- Instant Prompt (Powerlevel10k) ---
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- Plugins ---
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions.zsh/zsh-autosuggestions.zsh"

# --- Aliases ---
alias ls="ls --color"
alias micro="~/micro"
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

# --- Claude Code notifications toggle ---
alias notifs-on='cp ~/.claude/settings-notifs-on.json ~/.claude/settings.json'
alias notifs-off='cp ~/.claude/settings-notifs-off.json ~/.claude/settings.json'

# --- Python (Homebrew) ---
export PATH="/opt/homebrew/opt/python@3.13/bin:$PATH"
alias py="python3"
alias pip="pip3"

# --- Fancy terminal banners ---
if [[ "$COLUMNS" -lt 75 ]]; then
  clear
  echo ""
  nerdfetch
  echo -e "\n\e[1;35m$(echo 'EVULution' | figlet -f slscript -d /Users/cgpp/figlet-fonts -w 100)\e[0m"
else
  clear
  echo ""
  neofetch
  echo -e "\e[1;34m• • • • • • • • • • • • • • • • • • ✦ • • • • • • • • • • • • • • • • • •\n\e[0m"
  echo -e "\e[1;35m$(echo 'EVULution' | figlet -f rounded -d /Users/cgpp/figlet-fonts -w 100)\e[0m\n"
  echo -e "\e[1;34m• • • • • • • • • • • • • • • • • • ✦ • • • • • • • • • • • • • • • • • •\n\n\e[0m"
fi

# --- History ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# --- Tools ---
eval "$(zoxide init zsh)"
source <(ng completion script)
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export P10K_THEME='powerlevel10k/iceberg'
setopt nocaseglob

# --- Editor ---
if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
  alias nvim="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
else
  export VISUAL="nvim"
  export EDITOR="nvim"
fi

# --- FZF ---
if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi

# --- Paths ---
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
if [ ! -f ~/bin/vim ]; then
  echo '#!/bin/bash' > ~/bin/vim
  echo 'if [ -n "$NVIM_LISTEN_ADDRESS" ]; then' >> ~/bin/vim
  echo '  /usr/bin/vim "$@"' >> ~/bin/vim
  echo 'else' >> ~/bin/vim
  echo '  /Users/cgpp/.local/share/bob/nvim-bin/nvim "$@"' >> ~/bin/vim
  echo 'fi' >> ~/bin/vim
  chmod +x ~/bin/vim
fi

# Created by `pipx` on 2025-11-02 11:08:50
export PATH="$PATH:/Users/cgpp/.local/bin"

# opencode
export PATH=/Users/cgpp/.opencode/bin:$PATH
export PATH=~/.local/bin:$PATH
