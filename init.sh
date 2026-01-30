#!/bin/bash
set -e

# =============================================================================
# macOS Development Environment Setup
# =============================================================================
# Run: curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/init.sh | bash
# Or:  ./init.sh
# =============================================================================

DOTFILES_DIR="$HOME/dev/dotfiles"
REPO_URL="https://github.com/GappelSolutions/dotfiles.git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

print_step() {
    echo -e "${GREEN}▶${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✖${NC} $1"
}

print_success() {
    echo -e "${GREEN}✔${NC} $1"
}

# =============================================================================
# 1. Xcode Command Line Tools
# =============================================================================
print_header "Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
    print_success "Xcode CLI tools already installed"
else
    print_step "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Press any key after Xcode CLI tools installation completes..."
    read -n 1 -s
fi

# =============================================================================
# 2. Homebrew
# =============================================================================
print_header "Homebrew"

if command -v brew &>/dev/null; then
    print_success "Homebrew already installed"
else
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Add Homebrew to PATH for this session
eval "$(/opt/homebrew/bin/brew shellenv)"

# =============================================================================
# 3. Clone Dotfiles
# =============================================================================
print_header "Dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
    print_success "Dotfiles already cloned at $DOTFILES_DIR"
    cd "$DOTFILES_DIR" && git pull
else
    print_step "Cloning dotfiles..."
    mkdir -p "$HOME/dev"
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

# =============================================================================
# 4. Homebrew Formulae (CLI tools)
# =============================================================================
print_header "Homebrew Formulae"

FORMULAE=(
    # Core tools
    git
    stow
    zsh
    neovim-remote

    # Terminal & Shell
    zsh-autosuggestions
    zsh-syntax-highlighting
    zoxide
    fzf
    eza
    ripgrep
    fd
    bat
    git-delta

    # File managers & viewers
    yazi
    btop
    bottom
    lazygit
    lazydocker

    # Multiplexers
    zellij
    tmux

    # Development
    node
    pnpm
    dotnet@8
    bob           # Neovim version manager

    # Containers & K8s
    docker
    docker-compose
    colima
    minikube
    helm
    k9s

    # Cloud & DevOps
    azure-cli
    gh
    sops

    # Database
    postgresql@14
    redis
    rainfrog
    libpq

    # Languages & Build
    elixir
    luarocks
    pipx
    cocoapods

    # Utilities
    wget
    mas           # Mac App Store CLI
    jq
    ffmpeg
    pandoc
    unar
    zip
    socat
    rclone

    # Utilities
    nowplaying-cli
)

print_step "Installing Homebrew formulae..."
for formula in "${FORMULAE[@]}"; do
    if brew list "$formula" &>/dev/null; then
        echo "  ✓ $formula"
    else
        echo "  Installing $formula..."
        brew install "$formula" || print_warning "Failed to install $formula"
    fi
done

# Tap for Dart
brew tap dart-lang/dart 2>/dev/null || true
brew install dart 2>/dev/null || true

# =============================================================================
# 5. Homebrew Casks (GUI apps)
# =============================================================================
print_header "Homebrew Casks"

CASKS=(
    # Terminal
    alacritty

    # Window Management
    aerospace
    karabiner-elements
    jordanbaird-ice

    # Development
    android-studio
    android-platform-tools
    flutter
    postman
    ngrok

    # Editors
    obsidian

    # Utilities
    appcleaner
    keka
    localsend
    balenaetcher
    flameshot

    # Fonts
    font-fira-code-nerd-font
    font-hack-nerd-font
    font-sf-mono
    font-sf-pro
    sf-symbols

    # PDF & Docs
    master-pdf-editor
    basictex

    # Communication
    thunderbird

    # Microsoft
    microsoft-outlook
    microsoft-remote-desktop
    microsoft-auto-update

    # Misc
    wine-stable
    gstreamer-runtime
)

print_step "Installing Homebrew casks..."
for cask in "${CASKS[@]}"; do
    if brew list --cask "$cask" &>/dev/null; then
        echo "  ✓ $cask"
    else
        echo "  Installing $cask..."
        brew install --cask "$cask" || print_warning "Failed to install $cask"
    fi
done

# =============================================================================
# 6. Stow Dotfiles
# =============================================================================
print_header "Stowing Dotfiles"

cd "$DOTFILES_DIR"

STOW_PACKAGES=(
    zsh
    nvim
    alacritty
    lazygit
    yazi
    zellij
    aerospace
    vscode
    vim
    jetbrains
    mcphub
    claude
)

for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$DOTFILES_DIR/$pkg" ]]; then
        print_step "Stowing $pkg..."
        stow --no-folding -t ~ "$pkg" 2>/dev/null || stow -t ~ "$pkg" 2>/dev/null || print_warning "Failed to stow $pkg"
    fi
done

# =============================================================================
# 7. Neovim (via bob)
# =============================================================================
print_header "Neovim"

if command -v bob &>/dev/null; then
    print_step "Installing latest stable Neovim via bob..."
    bob install stable
    bob use stable
else
    print_warning "Bob not found, skipping Neovim installation"
fi

# =============================================================================
# 8. Rust
# =============================================================================
print_header "Rust"

if command -v rustup &>/dev/null; then
    print_success "Rust already installed"
else
    print_step "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Rust tools
if command -v cargo &>/dev/null; then
    print_step "Installing Rust tools..."
    cargo install dioxus-cli 2>/dev/null || true
fi

# =============================================================================
# 9. Node.js Global Packages
# =============================================================================
print_header "Node.js Global Packages"

NPM_PACKAGES=(
    "@angular/cli"
    "prettier"
    "eslint"
    "agent-browser"
    "mcp-hub"
)

print_step "Installing global npm packages..."
for pkg in "${NPM_PACKAGES[@]}"; do
    if npm list -g "$pkg" &>/dev/null; then
        echo "  ✓ $pkg"
    else
        echo "  Installing $pkg..."
        npm install -g "$pkg" || print_warning "Failed to install $pkg"
    fi
done

# =============================================================================
# 10. .NET Global Tools
# =============================================================================
print_header ".NET Global Tools"

DOTNET_TOOLS=(
    "csharpier"
    "dotnet-ef"
    "csharp-ls"
)

if command -v dotnet &>/dev/null; then
    print_step "Installing .NET global tools..."
    for tool in "${DOTNET_TOOLS[@]}"; do
        if dotnet tool list -g | grep -q "$tool"; then
            echo "  ✓ $tool"
        else
            echo "  Installing $tool..."
            dotnet tool install -g "$tool" || print_warning "Failed to install $tool"
        fi
    done
else
    print_warning ".NET not found, skipping .NET tools"
fi

# =============================================================================
# 11. Python (pipx)
# =============================================================================
print_header "Python Tools (pipx)"

PIPX_PACKAGES=(
    "fastapi"
    "uvicorn"
)

if command -v pipx &>/dev/null; then
    print_step "Ensuring pipx path..."
    pipx ensurepath

    print_step "Installing Python tools via pipx..."
    for pkg in "${PIPX_PACKAGES[@]}"; do
        if pipx list | grep -q "$pkg"; then
            echo "  ✓ $pkg"
        else
            echo "  Installing $pkg..."
            pipx install "$pkg" || print_warning "Failed to install $pkg"
        fi
    done
else
    print_warning "pipx not found, skipping Python tools"
fi

# =============================================================================
# 12. Claude Code
# =============================================================================
print_header "Claude Code"

if command -v claude &>/dev/null; then
    print_success "Claude Code already installed"
else
    print_step "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code || print_warning "Failed to install Claude Code"
fi

# =============================================================================
# 13. Flutter Setup
# =============================================================================
print_header "Flutter"

if command -v flutter &>/dev/null; then
    print_step "Running flutter doctor..."
    flutter doctor || true

    print_step "Accepting Android licenses..."
    flutter doctor --android-licenses || true
else
    print_warning "Flutter not found"
fi

# =============================================================================
# 14. FZF Key Bindings
# =============================================================================
print_header "FZF Setup"

if [[ -f "$(brew --prefix)/opt/fzf/install" ]]; then
    print_step "Installing FZF key bindings..."
    "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# =============================================================================
# 15. Create directories & Shell Completions
# =============================================================================
print_header "Directory Setup & Completions"

print_step "Creating common directories..."
mkdir -p ~/dev
mkdir -p ~/bin
mkdir -p ~/.zsh/completions

# Generate pnpm completions
if command -v pnpm &>/dev/null; then
    print_step "Generating pnpm completions..."
    pnpm completion zsh > ~/.zsh/completions/_pnpm 2>/dev/null || true
fi

# =============================================================================
# 16. macOS Defaults
# =============================================================================
print_header "macOS Defaults"

print_step "Configuring macOS defaults..."

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles YES

# Show path bar in Finder
defaults write com.apple.finder ShowPathbar -bool true

# Show status bar in Finder
defaults write com.apple.finder ShowStatusBar -bool true

# Disable press-and-hold for keys (for vim)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Fast key repeat
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Restart Finder
killall Finder 2>/dev/null || true

print_success "macOS defaults configured"

# =============================================================================
# Done!
# =============================================================================
print_header "Setup Complete!"

echo -e "${GREEN}Your development environment is ready!${NC}\n"
echo "Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Open Alacritty for your configured terminal"
echo "  3. Run 'nvim' to set up Neovim plugins"
echo "  4. Run 'claude' to authenticate Claude Code"
echo ""
echo -e "${YELLOW}Some apps may require manual setup:${NC}"
echo "  - Karabiner Elements: Import your config"
echo "  - Aerospace: Grant accessibility permissions"
echo "  - Android Studio: Complete first-run setup"
echo ""
