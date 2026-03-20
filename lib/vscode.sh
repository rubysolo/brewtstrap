#!/usr/bin/env bash

source "$(dirname "$0")/lib/utils.sh"

function setup_vscode() {
  header "$GEAR  Coding with VSCode"

  local dot_dir="$PWD/dotfiles"
  local vscode_dir="$HOME/Library/Application Support/Code/User"

  mkdir -p "$vscode_dir"

  info "Linking VSCode settings..."
  ln -sf "$dot_dir/vscode/settings.json" "$vscode_dir/settings.json"
  ln -sf "$dot_dir/vscode/keybindings.json" "$vscode_dir/keybindings.json"
  ln -sf "$dot_dir/vscode/snippets" "$vscode_dir/snippets"

  if command_exists code; then
    info "Installing VSCode extensions..."
    if [ -f "$dot_dir/vscode/extensions" ]; then
      grep -v '^#' "$dot_dir/vscode/extensions" | grep -v '^\s*$' | xargs -L1 code --install-extension
      success "VSCode extensions installed."
    else
      warn "VSCode extensions file not found."
    fi
  else
    warn "VSCode ('code') command not found. Skipping extension installation."
  fi

  info "Disabling press-and-hold for VSCode..."
  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
  
  success "VSCode configuration complete."
}
