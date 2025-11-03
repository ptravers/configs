#!/bin/bash
set -e

echo "=== macOS Setup Script ==="
echo "This script will set up shell and editor configurations on macOS."
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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS systems."
    exit 1
fi

# Ensure we're in the configs directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
if [ ! -f "$SCRIPT_DIR/README.md" ] || [ ! -d "$SCRIPT_DIR/shell" ]; then
    print_error "This script must be run from the configs directory."
    print_error "Usage: git clone <your-configs-repo> && cd configs && ./setup_macos.sh"
    exit 1
fi

print_status "Running from configs directory: $SCRIPT_DIR"
echo ""

# Ask for confirmation
read -p "This will install packages and set up shell/editor dotfiles. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_error "Setup cancelled."
    exit 1
fi

# Verify Homebrew is available
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is required but not found in PATH."
    print_error "Please install Homebrew first: https://brew.sh"
    exit 1
fi

print_status "Updating Homebrew..."
brew update

print_status "Installing essential packages..."
brew install \
    curl \
    wget \
    git \
    stow \
    tmux \
    fzf \
    fd

# Install Fish shell
print_status "Installing Fish shell..."
if ! command -v fish &> /dev/null; then
    brew install fish

    # Add fish to /etc/shells if not already there
    if ! grep -q "$(brew --prefix)/bin/fish" /etc/shells; then
        print_status "Adding fish to /etc/shells..."
        echo "$(brew --prefix)/bin/fish" | sudo tee -a /etc/shells
    fi
else
    print_status "Fish already installed"
fi

# Install Helix editor
print_status "Installing Helix editor..."
if ! command -v helix &> /dev/null && ! command -v hx &> /dev/null; then
    brew install helix
else
    print_status "Helix already installed"
fi

# Install jujutsu (jj) for version control
print_status "Installing jujutsu (jj)..."
if ! command -v jj &> /dev/null; then
    brew install jj
else
    print_status "jj already installed"
fi

# Create backup of existing dotfiles
print_status "Creating backup of existing dotfiles..."
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Backup shell-related dotfiles
for file in .bashrc .zshrc .tmux.conf .fdignore; do
    if [ -f "$HOME/$file" ] && [ ! -L "$HOME/$file" ]; then
        print_status "Backing up $file"
        mv "$HOME/$file" "$BACKUP_DIR/"
    fi
done

# Backup .config items for shell and editor
if [ -d "$HOME/.config" ]; then
    for dir in fish git helix; do
        if [ -e "$HOME/.config/$dir" ] && [ ! -L "$HOME/.config/$dir" ]; then
            print_status "Backing up .config/$dir"
            mkdir -p "$BACKUP_DIR/.config"
            mv "$HOME/.config/$dir" "$BACKUP_DIR/.config/"
        fi
    done
fi

# Use stow to symlink shell and editor configs
print_status "Using stow to symlink configurations..."
cd "$SCRIPT_DIR"

# Only stow shell and editor groups as requested
GROUPS="shell editor"

for group in $GROUPS; do
    if [ -d "$group" ]; then
        print_status "Stowing $group..."
        stow -v "$group" 2>&1 || print_warning "Failed to stow $group (may already exist)"
    else
        print_warning "Group '$group' not found in configs directory"
    fi
done

# Install NVM (Node Version Manager) - optional but commonly needed for editor LSPs
print_status "Installing NVM (for language servers)..."
if [ ! -d "$HOME/.nvm" ]; then
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
    print_status "NVM already installed"
fi

# Install pnpm - optional but useful
print_status "Installing pnpm..."
if ! command -v pnpm &> /dev/null; then
    curl -fsSL https://get.pnpm.io/install.sh | sh -
else
    print_status "pnpm already installed"
fi

# Change default shell to fish
print_status "Setting fish as default shell..."
FISH_PATH="$(brew --prefix)/bin/fish"
if [ "$SHELL" != "$FISH_PATH" ]; then
    chsh -s "$FISH_PATH"
    print_status "Default shell changed to fish. You'll need to open a new terminal for this to take effect."
else
    print_status "Fish is already the default shell"
fi

# Create .local/bin if it doesn't exist
mkdir -p "$HOME/.local/bin"

# macOS specific: Install useful clipboard utilities if not present
print_status "Checking clipboard utilities..."
if ! command -v pbcopy &> /dev/null; then
    print_warning "pbcopy not found (should be installed by default on macOS)"
fi

print_status "Setup complete!"
echo ""
echo "Summary:"
echo "  - Installed: fish, helix, jj, stow, tmux, fzf, fd"
echo "  - Configs directory: $SCRIPT_DIR"
echo "  - Dotfiles backed up to: $BACKUP_DIR"
echo "  - Stowed config groups: shell, editor"
echo ""
echo "Next steps:"
echo "  1. Open a new terminal for shell changes to take effect"
echo "  2. Review and test your configurations"
echo "  3. Run 'hx --health' to check helix language server setup"
echo ""
echo "To use this setup on another macOS machine:"
echo "  git clone $(git remote get-url origin 2>/dev/null || echo '<your-repo-url>')"
echo "  cd configs"
echo "  ./setup_macos.sh"