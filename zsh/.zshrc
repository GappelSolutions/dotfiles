if [[ ":$FPATH:" != *":/Users/cgpp/.zsh/completions:"* ]]; then export FPATH="/Users/cgpp/.zsh/completions:$FPATH"; fi
if [ "$TMUX" = "" ]; then 
  tmux attach || tmux new-session
 fi

# Enable command auto-completion and history features
autoload -Uz compinit
compinit

# Set up instant prompt if the cache file exists
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Load plugins for enhanced shell functionality
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions.zsh/zsh-autosuggestions.zsh"

# Aliases for common commands
alias ls="ls --color"
alias micro="~/micro"
alias ls='eza --icons'
alias ll='eza -l --icons'
alias lt='eza --tree --level=1 --icons'
alias lsa='eza -a --icons'
alias lla='eza -al --icons'
alias lta='eza -a --tree --level=1 --icons'
alias y='yazi'
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

clear
echo ""
neofetch
echo -e "\e[1;32m• • • • • • • • • • • • • • • • • • • • ✦ • • • • • • • • • • • • • • • • • • • •\n\e[0m"
echo -e "\e[1;33m$(echo 'Gappel' | figlet -f Fraktur -d /Users/cgpp/figlet-fonts -w 100)\e[0m"

# Setup history file and options
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Initialize Zoxide for directory jumping
eval "$(zoxide init zsh)"

# Initialize ng completion script
source <(ng completion script)

# Setup Powerlevel10k theme
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Enable instant prompt for Powerlevel10k
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export P10K_THEME='powerlevel10k/iceberg' # Assuming you have icebergs integrated
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

# pnpm
export PNPM_HOME="/Users/cgpp/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
