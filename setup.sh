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
source "$ROOT_DIR/lib/git.sh"
source "$ROOT_DIR/lib/links.sh"
source "$ROOT_DIR/lib/vscode.sh"
source "$ROOT_DIR/lib/interactive.sh"
source "$ROOT_DIR/lib/mise.sh"

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

  # Present all choices up-front and collect selections into SELECTED_MODULES
  choose_tasks

  # Helper for checking selections
  selected() {
    for v in "${SELECTED_MODULES[@]:-}"; do
      [ "$v" = "$1" ] && return 0
    done
    return 1
  }

# 1. Homebrew Core
if selected homebrew; then
  install_homebrew
  brew_bundle "$ROOT_DIR/lib/brew/core.Brewfile" "Core CLI Tools"
fi

# 2. Development Tools
if selected dev; then
  brew_bundle "$ROOT_DIR/lib/brew/dev.Brewfile" "Development Tools"
fi

# 3. Runtimes & DBs
if selected runtimes; then
  brew_bundle "$ROOT_DIR/lib/brew/runtimes.Brewfile" "Runtimes & Databases"
fi

# 4. Computer Vision & ML
if selected cvml; then
  brew_bundle "$ROOT_DIR/lib/brew/cvml.Brewfile" "Computer Vision & ML"
fi

# 5. Networking Tools
if selected network; then
  brew_bundle "$ROOT_DIR/lib/brew/network.Brewfile" "Networking Tools"
fi

# 6. Modern AI Tools
if selected modern; then
  brew_bundle "$ROOT_DIR/lib/brew/modern.Brewfile" "Modern AI Tools"
fi

# 7. Apps & Casks
if selected apps; then
  brew_bundle "$ROOT_DIR/lib/brew/apps.Brewfile" "Applications"
fi

# 8. Fonts
if selected fonts; then
  brew_bundle "$ROOT_DIR/lib/brew/fonts.Brewfile" "Fonts"
fi

# 9. Shell & Media
if selected shell_media; then
  brew_bundle "$ROOT_DIR/lib/brew/shell.Brewfile" "Shell Environment"
  brew_bundle "$ROOT_DIR/lib/brew/media.Brewfile" "Media Tools"
fi

# 10. Symlinks
if selected links; then
  setup_links
fi

# 11. macOS Preferences
if selected macos; then
  setup_macos
fi

# 12. Fish Shell Activation
if selected fish; then
  setup_shell
fi

# 13. Git Configuration
if selected git; then
  setup_git
fi

# 14. VSCode Setup
if selected vscode; then
  setup_vscode
fi

# 15. Mise Language Installation
if selected mise; then
  setup_mise
fi

# Cleanup
if selected cleanup; then
  cleanup_homebrew
fi

header "$SPARKLES  Machine Setup Complete!  $SPARKLES"
info "Please restart your terminal or log out/in for all changes to take effect."
success "Enjoy your new setup! (2026 Edition)"
