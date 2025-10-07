#!/bin/bash
# User Environment Aspect - Verification Script

set -euo pipefail

echo "Verifying User Environment Aspect..."
echo

# Check chezmoi is installed
echo "Checking chezmoi..."
if command -v chezmoi &>/dev/null; then
    echo "✓ chezmoi installed"
else
    echo "✗ chezmoi NOT installed"
    exit 1
fi
echo

# Check dotfiles applied
echo "Checking dotfiles..."
DOTFILES=(".zshrc" ".bashrc" ".gitconfig")
for dotfile in "${DOTFILES[@]}"; do
    if [ -f "$HOME/$dotfile" ]; then
        echo "✓ $dotfile exists"
    else
        echo "✗ $dotfile missing"
        exit 1
    fi
done
echo

# Check tools installed
echo "Checking tools..."
TOOLS=("eza" "bat" "fd" "rg" "starship")
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "✓ $tool installed"
    else
        echo "✗ $tool NOT installed"
        exit 1
    fi
done
echo

# Check directories
echo "Checking directory structure..."
DIRS=(
    "$HOME/.local/bin"
    "$HOME/.local/share"
    "$HOME/.config"
    "$HOME/Projects"
    "$HOME/workspace"
)
for dir in "${DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "✓ $dir exists"
    else
        echo "✗ $dir missing"
        exit 1
    fi
done
echo

# Check default shell
echo "Checking default shell..."
if [ "$SHELL" = "/bin/zsh" ]; then
    echo "✓ Default shell is zsh"
else
    echo "⚠ Default shell is $SHELL (expected /bin/zsh)"
fi
echo

echo "✓ User Environment aspect verification PASSED"
