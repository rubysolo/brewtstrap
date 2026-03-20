#!/usr/bin/env bash

source "$(dirname "$0")/lib/utils.sh"

function setup_macos() {
  header "$COMPUTER  Setting macOS Preferences"
  
  if [ -f "dotfiles/macprefs" ]; then
    info "Running macos preferences script..."
    bash "dotfiles/macprefs"
    success "macOS preferences set. Note: some changes require logout/restart."
  else
    error "macprefs script not found in dotfiles/"
  fi
}
