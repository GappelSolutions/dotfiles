#!/bin/bash
set -e

# =============================================================================
# Nix Darwin Bootstrap Script
# =============================================================================
#
# This script sets up a fresh macOS machine with nix-darwin + home-manager
# and agenix for secrets management.
#
# Usage (fresh machine):
#   curl -fsSL https://raw.githubusercontent.com/GappelSolutions/dotfiles/main/nix/bootstrap.sh | bash
#
# Or (after cloning):
#   ./bootstrap.sh
#
# =============================================================================

DOTFILES_DIR="$HOME/dev/dotfiles"
NIX_DIR="$DOTFILES_DIR/nix"
REPO_URL="https://github.com/GappelSolutions/dotfiles.git"
AGE_DIR="$HOME/.age"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}=============================================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}=============================================================================${NC}\n"
}

print_step() {
    echo -e "${GREEN}>>>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!!${NC} $1"
}

print_error() {
    echo -e "${RED}ERROR:${NC} $1"
}

print_success() {
    echo -e "${GREEN}OK${NC} $1"
}

print_prompt() {
    echo -e "${CYAN}???${NC} $1"
}

# =============================================================================
# Step 1: Xcode Command Line Tools
# =============================================================================
print_header "Step 1/8: Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
    print_success "Xcode CLI tools already installed"
else
    print_step "Installing Xcode Command Line Tools..."
    xcode-select --install
    echo ""
    print_prompt "Press ENTER after Xcode CLI tools installation completes..."
    read -r
fi

# =============================================================================
# Step 2: Install Nix
# =============================================================================
print_header "Step 2/8: Nix Package Manager"

if command -v nix &>/dev/null; then
    print_success "Nix already installed"
else
    print_step "Installing Nix (Determinate Systems installer)..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

    # Source nix in current shell
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
fi

# Verify nix works
if ! command -v nix &>/dev/null; then
    print_error "Nix installation failed or not in PATH"
    print_step "Try opening a new terminal and running this script again"
    exit 1
fi

# =============================================================================
# Step 3: Clone Dotfiles
# =============================================================================
print_header "Step 3/8: Clone Dotfiles"

if [[ -d "$DOTFILES_DIR" ]]; then
    print_success "Dotfiles already cloned at $DOTFILES_DIR"
    cd "$DOTFILES_DIR" && git pull
else
    print_step "Cloning dotfiles..."
    mkdir -p "$HOME/dev"
    git clone "$REPO_URL" "$DOTFILES_DIR"
fi

cd "$NIX_DIR"

# =============================================================================
# Step 4: Setup Age Master Key
# =============================================================================
print_header "Step 4/8: Age Master Key Setup"

mkdir -p "$AGE_DIR"
chmod 700 "$AGE_DIR"

if [[ -f "$AGE_DIR/master.key" ]]; then
    print_success "Age master key already exists"
else
    echo ""
    print_prompt "Do you have an existing encrypted master.key backup? (y/n)"
    read -r HAS_BACKUP

    if [[ "$HAS_BACKUP" == "y" || "$HAS_BACKUP" == "Y" ]]; then
        echo ""
        print_prompt "Enter path to encrypted master.key.age file:"
        read -r BACKUP_PATH

        if [[ -f "$BACKUP_PATH" ]]; then
            print_step "Decrypting master key (enter your passphrase)..."
            age -d "$BACKUP_PATH" > "$AGE_DIR/master.key"
            chmod 600 "$AGE_DIR/master.key"
            print_success "Master key restored"
        else
            print_error "File not found: $BACKUP_PATH"
            exit 1
        fi
    else
        echo ""
        print_step "Generating new age master key..."
        print_warning "This key will be encrypted with a passphrase."
        print_warning "REMEMBER THIS PASSPHRASE - it's your 'one password' for everything!"
        echo ""

        # Generate key
        age-keygen > "$AGE_DIR/master.key.tmp" 2>&1

        # Extract public key
        PUBLIC_KEY=$(grep "public key:" "$AGE_DIR/master.key.tmp" | cut -d: -f2 | tr -d ' ')

        # Just keep the private key part
        grep -v "^#" "$AGE_DIR/master.key.tmp" > "$AGE_DIR/master.key"
        rm "$AGE_DIR/master.key.tmp"
        chmod 600 "$AGE_DIR/master.key"

        echo ""
        print_success "Master key generated!"
        echo ""
        echo -e "${CYAN}Your public key (save this, it goes in secrets.nix):${NC}"
        echo "$PUBLIC_KEY"
        echo ""

        # Create encrypted backup
        print_step "Creating encrypted backup of master key..."
        print_prompt "Enter a passphrase to encrypt the backup:"
        age -p -o "$AGE_DIR/master.key.age" "$AGE_DIR/master.key"

        echo ""
        print_success "Encrypted backup saved to: $AGE_DIR/master.key.age"
        print_warning "IMPORTANT: Copy master.key.age to a safe location (USB drive, etc.)"
        echo ""

        # Update secrets.nix with the public key
        print_step "Updating secrets.nix with your public key..."
        sed -i '' "s|age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx|$PUBLIC_KEY|" "$NIX_DIR/secrets/secrets.nix"
        print_success "secrets.nix updated"
    fi
fi

# Show public key for reference
echo ""
print_step "Your age public key:"
age-keygen -y "$AGE_DIR/master.key"
echo ""

# =============================================================================
# Step 5: SSH Keys Setup
# =============================================================================
print_header "Step 5/8: SSH Keys Setup"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Check if secrets are already encrypted
SECRETS_EXIST=false
if [[ -f "$NIX_DIR/secrets/ssh-github-personal.age" ]] && \
   [[ -f "$NIX_DIR/secrets/ssh-github-work.age" ]] && \
   [[ -f "$NIX_DIR/secrets/ssh-azure.age" ]]; then
    print_success "Encrypted SSH keys found in repo"
    SECRETS_EXIST=true
fi

if [[ "$SECRETS_EXIST" == "false" ]]; then
    echo ""
    print_warning "SSH keys need to be encrypted and added to the repo."
    print_warning "You'll need to provide your existing SSH private keys."
    echo ""

    # Install agenix CLI temporarily
    print_step "Installing agenix CLI..."
    nix profile install github:ryantm/agenix

    echo ""
    echo -e "${CYAN}For each key, you can either:${NC}"
    echo "  1. Paste the key content directly"
    echo "  2. Provide a path to the key file"
    echo ""

    # GitHub Personal
    print_header "SSH Key: GitHub Personal"
    print_prompt "Enter path to your GitHub personal SSH private key (e.g., ~/.ssh/id_ed25519):"
    read -r GITHUB_PERSONAL_KEY
    if [[ -f "$GITHUB_PERSONAL_KEY" ]]; then
        cp "$GITHUB_PERSONAL_KEY" /tmp/ssh-key-temp
        chmod 600 /tmp/ssh-key-temp
        cd "$NIX_DIR/secrets"
        age -r "$(age-keygen -y $AGE_DIR/master.key)" -o ssh-github-personal.age /tmp/ssh-key-temp
        rm /tmp/ssh-key-temp
        print_success "GitHub personal key encrypted"
    else
        print_error "File not found: $GITHUB_PERSONAL_KEY"
    fi

    # GitHub Work
    print_header "SSH Key: GitHub Work"
    print_prompt "Enter path to your GitHub work SSH private key:"
    read -r GITHUB_WORK_KEY
    if [[ -f "$GITHUB_WORK_KEY" ]]; then
        cp "$GITHUB_WORK_KEY" /tmp/ssh-key-temp
        chmod 600 /tmp/ssh-key-temp
        cd "$NIX_DIR/secrets"
        age -r "$(age-keygen -y $AGE_DIR/master.key)" -o ssh-github-work.age /tmp/ssh-key-temp
        rm /tmp/ssh-key-temp
        print_success "GitHub work key encrypted"
    else
        print_error "File not found: $GITHUB_WORK_KEY"
    fi

    # Azure DevOps
    print_header "SSH Key: Azure DevOps"
    print_prompt "Enter path to your Azure DevOps SSH private key:"
    read -r AZURE_KEY
    if [[ -f "$AZURE_KEY" ]]; then
        cp "$AZURE_KEY" /tmp/ssh-key-temp
        chmod 600 /tmp/ssh-key-temp
        cd "$NIX_DIR/secrets"
        age -r "$(age-keygen -y $AGE_DIR/master.key)" -o ssh-azure.age /tmp/ssh-key-temp
        rm /tmp/ssh-key-temp
        print_success "Azure DevOps key encrypted"
    else
        print_error "File not found: $AZURE_KEY"
    fi

    cd "$NIX_DIR"
    echo ""
    print_warning "Don't forget to commit the .age files to your repo!"
fi

# =============================================================================
# Step 6: Set Hostname
# =============================================================================
print_header "Step 6/8: Hostname Configuration"

CURRENT_HOSTNAME=$(scutil --get LocalHostName 2>/dev/null || hostname -s)
echo ""
print_step "Current hostname: $CURRENT_HOSTNAME"
print_prompt "Enter hostname for this machine (or press ENTER to use '$CURRENT_HOSTNAME'):"
read -r NEW_HOSTNAME

if [[ -z "$NEW_HOSTNAME" ]]; then
    NEW_HOSTNAME="$CURRENT_HOSTNAME"
fi

# Update flake.nix with hostname
print_step "Updating flake.nix with hostname: $NEW_HOSTNAME"
sed -i '' "s|hostname = \"cgpp-mac\";|hostname = \"$NEW_HOSTNAME\";|" "$NIX_DIR/flake.nix"

# =============================================================================
# Step 7: Build and Switch
# =============================================================================
print_header "Step 7/8: Building Configuration"

print_step "Running darwin-rebuild..."
print_warning "This may take a while on first run (downloading packages)..."
echo ""

cd "$NIX_DIR"
nix run nix-darwin -- switch --flake ".#$NEW_HOSTNAME"

# =============================================================================
# Step 8: Service Authentication
# =============================================================================
print_header "Step 8/8: Service Authentication"

echo ""
echo -e "${CYAN}Authenticating your services (browser will open for each)...${NC}"
echo ""

# GitHub CLI
print_step "GitHub CLI..."
gh auth login
print_success "GitHub CLI authenticated"

# Azure CLI
print_step "Azure CLI..."
az login
print_success "Azure CLI authenticated"

# Claude Code
print_step "Claude Code..."
claude login
print_success "Claude Code authenticated"

# =============================================================================
# Done!
# =============================================================================
print_header "Setup Complete!"

echo -e "${GREEN}Your development environment is ready!${NC}"
echo ""
echo "What was set up:"
echo "  - Nix package manager"
echo "  - nix-darwin (system configuration)"
echo "  - home-manager (user configuration)"
echo "  - agenix (secrets management)"
echo "  - All your packages and dotfiles"
echo ""
echo "Useful commands:"
echo "  rebuild          - Rebuild after config changes"
echo "  darwin-rebuild switch --flake ~/dev/dotfiles/nix"
echo ""
echo -e "${YELLOW}Remember to:${NC}"
echo "  1. Backup ~/.age/master.key.age to a safe location"
echo "  2. Commit the encrypted .age files if you added new secrets"
echo ""
echo -e "${YELLOW}IMPORTANT: Grant macOS Permissions${NC}"
echo ""
echo "  Open System Settings > Privacy & Security and grant:"
echo ""
echo "  Accessibility:"
echo "    - Alacritty      (for Karabiner keybindings in terminal)"
echo "    - AeroSpace      (for window management)"
echo "    - Karabiner-Elements"
echo "    - Raycast        (for window management, snippets)"
echo ""
echo "  Input Monitoring:"
echo "    - Karabiner-Elements"
echo ""
echo "  Screen Recording:"
echo "    - Flameshot      (for screenshots)"
echo ""
echo -e "  ${RED}Apps will NOT work correctly without these permissions!${NC}"
echo ""
echo "  After granting, restart each app."
echo ""
echo -e "${YELLOW}Restore Raycast Settings:${NC}"
echo "  1. Open Raycast (Cmd+Space)"
echo "  2. Search 'Import Settings & Data'"
echo "  3. Select ~/dev/dotfiles/raycast/settings.rayconfig"
echo ""
echo -e "${CYAN}Restart your terminal to apply all changes.${NC}"
