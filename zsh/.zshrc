if [[ ":$FPATH:" != *":/home/cgpp/.zsh/completions:"* ]]; then export FPATH="/home/cgpp/.zsh/completions:$FPATH"; fi
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
plugins=(zsh-syntax-highlighting zsh-autosuggestions)

# Initialize the plugins using Oh-My-Zsh or similar
for plugin in "${plugins[@]}"; do
  source "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/${plugin}/${plugin}.zsh"
done

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
alias dcu="docker compose up -d --build"
alias dcd="docker compose down"
alias ld='lazydocker'
alias stowm='stow -v -R -t ~'

echo ""
neofetch
echo -e "\e[1;36m\n• • • • • • • • • • • • • • • • • • • • ✦ • • • • • • • • • • • • • • • • • • • •\n\n\e[0m"
echo -e "\e[1;36m$(echo 'Gappel' | figlet -f Fraktur -d /home/cgpp/figlet-fonts -w 100)\e[0m"
echo ""

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
source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Enable instant prompt for Powerlevel10k
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
export P10K_THEME='powerlevel10k/iceberg' # Assuming you have icebergs integrated
export PATH="$PATH:$HOME/.dotnet/tools"
