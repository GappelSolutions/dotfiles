if [[ ":$FPATH:" != *":/Users/cgpp/.zsh/completions:"* ]]; then
  export FPATH="/Users/cgpp/.zsh/completions:$FPATH"
fi

autoload -Uz compinit
compinit

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions.zsh/zsh-autosuggestions.zsh"

alias ls="ls --color"
alias micro="~/micro"
alias ls='eza --icons'
alias ll='eza -l --icons'
alias lt='eza --tree --level=1 --icons'
alias lsa='eza -a --icons'
alias lla='eza -al --icons'
alias lta='eza -a --tree --level=1 --icons'
alias ssh-cloud="ssh cgpp@192.168.178.33"
alias cvpn="sudo systemctl start openvpn-client@client1"
alias dcu="docker-compose up -d --build"
alias dcd="docker-compose down"
alias ld='lazydocker'
alias lg='lazygit'
alias lsql='lazysql'
alias stowm='stow -v -R -t ~'
alias dnbo='dotnet watch run --project="Evulution.BackOffice.Webapi"'
alias dneb='dotnet watch run --project="Repower.CustomerPortal.Webapi" --launch-profile="eb"'
alias ai=' docker model run ai/smollm2'
alias db='rainfrog --driver postgresql --username cgpp --password ASDQWEasdqweASDQWE123 --host localhost --port 5430 --database gappel-cloud'
alias dotnet-csharpier='dotnet csharpier'
alias sz='source ~/.zshrc'
alias zr='zellij run -i --'

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

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

eval "$(zoxide init zsh)"

source <(ng completion script)

source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export P10K_THEME='powerlevel10k/iceberg'
export PATH="$PATH:$HOME/.dotnet/tools"
setopt nocaseglob

if [ -n "$NVIM_LISTEN_ADDRESS" ]; then
  alias nvim=nvr -cc split --remote-wait +'set bufhidden=wipe'
  export VISUAL="nvr -cc split --remote-wait +'set bufhidden=wipe'"
  export EDITOR="nvr -cc split --remote-wait +'set bufhidden=wipe'"
else
  export VISUAL="nvim"
  export EDITOR="nvim"
fi

if [ -f ~/.fzf.zsh ]; then
  source ~/.fzf.zsh
fi
export PATH="/Users/cgpp/.local/share/bob/nvim-bin:$PATH"
export PATH="/opt/homebrew/opt/libpq/bin:$PATH"
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
export PNPM_HOME="/Users/cgpp/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
export PATH="/usr/local/share/dotnet:$PATH"

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}
