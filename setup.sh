#!/usr/bin/env bash

# BREWTSTRAP - Modern Machine Setup (2026 Edition)
# 🚀 Refactored, Modular, and Interactive

set -eu

# Source all the things
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT_DIR/lib/utils.sh"
source "$ROOT_DIR/lib/brew.sh"
source "$ROOT_DIR/lib/macos.sh"
source "$ROOT_DIR/lib/shell.sh"
source "$ROOT_DIR/lib/links.sh"
source "$ROOT_DIR/lib/vscode.sh"

# Default to interactive mode
AUTO_INSTALL=false

# Simple flag parsing
for arg in "$@"; do
  case $arg in
    --all|-a)
      AUTO_INSTALL=true
      shift
      ;;
    --help|-h)
      echo "Usage: ./setup.sh [--all|-a]"
      echo "  --all: Install everything without asking (lights out mode)"
      exit 0
      ;;
  esac
done

header "$ROCKET  Welcome to BREWTSTRAP 2026"
info "This script will help you set up your new machine."
info "It is recommended to run this from a terminal with Full Disk Access."

if [ "$AUTO_INSTALL" = true ]; then
  warn "LIGHTS OUT MODE ACTIVATED: Installing the whole enchilada..."
else
  info "INTERACTIVE MODE: You'll be asked which bundles to install."
  echo ""
fi

# 1. Homebrew Core
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$BREW  Install Homebrew and Core CLI tools?"; then
  install_homebrew
  brew_bundle "$ROOT_DIR/lib/brew/core.Brewfile" "Core CLI Tools"
fi

# 2. Development Tools
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$TOOLS  Install Development Tools (Git, K8s, etc.)?"; then
  brew_bundle "$ROOT_DIR/lib/brew/dev.Brewfile" "Development Tools"
fi

# 3. Runtimes & DBs
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$DATABASE  Install Language Runtimes & Databases?"; then
  brew_bundle "$ROOT_DIR/lib/brew/runtimes.Brewfile" "Runtimes & Databases"
fi

# 4. Modern AI Tools
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$BRAIN  Install Modern AI Tools (Ollama, Claude, Copilot)?"; then
  brew_bundle "$ROOT_DIR/lib/brew/modern.Brewfile" "Modern AI Tools"
fi

# 5. Apps & Casks
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$COMPUTER  Install GUI Apps (Casks)?"; then
  brew_bundle "$ROOT_DIR/lib/brew/apps.Brewfile" "Applications"
fi

# 6. Fonts
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$FONT  Install Typography (Fonts)?"; then
  brew_bundle "$ROOT_DIR/lib/brew/fonts.Brewfile" "Fonts"
fi

# 7. Shell & Media
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$TERMINAL  Install Shell (Fish, Tmux) & $MEDIA Media tools?"; then
  brew_bundle "$ROOT_DIR/lib/brew/shell.Brewfile" "Shell Environment"
  brew_bundle "$ROOT_DIR/lib/brew/media.Brewfile" "Media Tools"
fi

# 8. Symlinks
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$LINK  Link Dotfiles (Git, Tmux, psql, etc.)?"; then
  setup_links
fi

# 9. macOS Preferences
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$APPLE  Apply macOS System Preferences?"; then
  setup_macos
fi

# 10. Fish Shell Activation
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$FISH  Switch default shell to Fish?"; then
  setup_shell
fi

# 11. VSCode Setup
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$GEAR  Configure VSCode (Links & Extensions)?"; then
  setup_vscode
fi

# Cleanup
if [ "$AUTO_INSTALL" = true ] || ask_yes_no "$CLEAN  Run Homebrew cleanup and upgrade?"; then
  cleanup_homebrew
fi

header "$SPARKLES  Machine Setup Complete!  $SPARKLES"
info "Please restart your terminal or log out/in for all changes to take effect."
success "Enjoy your new setup! (2026 Edition)"
