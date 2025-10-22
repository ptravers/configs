#!/bin/bash
set -e

echo "=== Ubuntu Setup Script ==="
echo "This script will set up a new Ubuntu installation with your dotfiles and preferences."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check if running on Ubuntu/Debian
if [ ! -f /etc/debian_version ]; then
    print_error "This script is designed for Ubuntu/Debian systems."
    exit 1
fi

# Ensure we're in the configs directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -f "$SCRIPT_DIR/README.md" ] || [ ! -d "$SCRIPT_DIR/shell" ]; then
    print_error "This script must be run from the configs directory."
    print_error "Usage: git clone <your-configs-repo> && cd configs && ./setup.sh"
    exit 1
fi

print_status "Running from configs directory: $SCRIPT_DIR"
echo ""

# Ask for confirmation
read -p "This will install packages and set up dotfiles. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Setup cancelled."
    exit 1
fi

print_status "Updating package lists..."
sudo apt update

print_status "Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    build-essential \
    software-properties-common \
    stow \
    tmux \
    fzf \
    fd-find

# Install Fish shell
print_status "Installing Fish shell..."
if ! command -v fish &> /dev/null; then
    sudo apt-add-repository -y ppa:fish-shell/release-3
    sudo apt update
    sudo apt install -y fish
else
    print_status "Fish already installed"
fi

# Install Helix editor
print_status "Installing Helix editor..."
if ! command -v helix &> /dev/null && ! command -v hx &> /dev/null; then
    sudo add-apt-repository -y ppa:maveonair/helix-editor
    sudo apt update
    sudo apt install -y helix
else
    print_status "Helix already installed"
fi

# Install jujutsu (jj) for version control
print_status "Installing jujutsu (jj)..."
if ! command -v jj &> /dev/null; then
    # Install cargo if not present
    if ! command -v cargo &> /dev/null; then
        print_status "Installing Rust/Cargo for jj installation..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    cargo install --git https://github.com/martinvonz/jj.git --locked jj-cli
else
    print_status "jj already installed"
fi

# Create backup of existing dotfiles
print_status "Creating backup of existing dotfiles..."
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

for file in .bashrc .zshrc .tmux.conf .pam_environment; do
    if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        print_status "Backing up $file"
        mv "$HOME/$file" "$BACKUP_DIR/"
    fi
done

# Backup .config items
if [ -d "$HOME/.config" ]; then
    for dir in fish git nvim helix; do
        if [ -e "$HOME/.config/$dir" ] && [ ! -L "$HOME/.config/$dir" ]; then
            print_status "Backing up .config/$dir"
            mkdir -p "$BACKUP_DIR/.config"
            mv "$HOME/.config/$dir" "$BACKUP_DIR/.config/"
        fi
    done
fi

# Use stow to symlink configs
print_status "Using stow to symlink configurations..."
cd "$SCRIPT_DIR"

# List of config groups to stow
GROUPS="bins editor env gui mail server shell"

for group in $GROUPS; do
    if [ -d "$group" ]; then
        print_status "Stowing $group..."
        stow -v "$group" 2>&1 || print_warning "Failed to stow $group (may already exist)"
    else
        print_warning "Group '$group' not found in configs directory"
    fi
done

# Install NVM (Node Version Manager)
print_status "Installing NVM..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    print_status "NVM already installed"
fi

# Install pnpm
print_status "Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
else
    print_status "pnpm already installed"
fi

# Change default shell to fish
print_status "Setting fish as default shell..."
if [ "$SHELL" != "$(which fish)" ]; then
    chsh -s "$(which fish)"
    print_status "Default shell changed to fish. You'll need to log out and back in for this to take effect."
else
    print_status "Fish is already the default shell"
fi

# Create .local/bin if it doesn't exist
mkdir -p "$HOME/.local/bin"

print_status "Setup complete!"
echo ""
echo "Summary:"
echo "  - Installed: fish, helix, jj, stow, tmux, fzf, fd-find"
echo "  - Configs directory: $SCRIPT_DIR"
echo "  - Dotfiles backed up to: $BACKUP_DIR"
echo "  - Stowed config groups: bins, editor, env, gui, mail, server, shell"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in for shell changes to take effect"
echo "  2. Review and test your configurations"
echo "  3. Run 'hx --health' to check helix language server setup"
echo ""
echo "To use this setup on another machine:"
echo "  git clone $(git remote get-url origin 2>/dev/null || echo '<your-repo-url>')"
echo "  cd configs"
echo "  ./setup.sh"
