#!/usr/bin/env bash

source "$(dirname "$0")/lib/utils.sh"

function setup_shell() {
  header "$TERMINAL  Swimming in the Fish Shell"

  # Detect architecture for prefix
  local homebrew_prefix
  if [[ $(uname -m) == "arm64" ]]; then
    homebrew_prefix="/opt/homebrew"
  else
    homebrew_prefix="/usr/local"
  fi
  local shell_path="$homebrew_prefix/bin/fish"

  if [ ! -f "$shell_path" ]; then
    warn "Fish shell not found at $shell_path. Did you install the shell brew bundle?"
    return 1
  fi

  if [ ! -w "$shell_path" ] || [ "$(ls -ld "$shell_path" | awk '{print $3}')" != "$(whoami)" ]; then
    info "Setting permissions for fish..."
    sudo chown $(whoami) "$shell_path" 2>/dev/null || true
    chmod u+w "$shell_path" 2>/dev/null || true
  fi

  if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
    info "Adding fish to /etc/shells..."
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi

  local current_shell
  if [[ "$OSTYPE" == "darwin"* ]]; then
    current_shell=$(dscl . -read /Users/$(whoami) UserShell | awk '{print $2}')
  else
    if command_exists getent; then
      current_shell=$(getent passwd $(whoami) | cut -d: -f7)
    else
      current_shell="$SHELL"
    fi
  fi

  if [ "$current_shell" != "$shell_path" ]; then
    info "Changing default shell to fish..."
    sudo chsh -s "$shell_path" $(whoami)
    success "Default shell changed to fish."
  else
    success "Fish is already your default shell."
  fi

  info "Installing Fisher plugin manager..."
  if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    "$shell_path" -c "curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
  fi
  
  # Ensure fisher is available even if just installed
  if [ -f "$HOME/.config/fish/functions/fisher.fish" ]; then
    success "Fisher is installed."
  else
    error "Fisher installation failed."
    return 1
  fi

  info "Installing Tide theme..."
  if "$shell_path" -c "functions -q fisher" && "$shell_path" -c "fisher list" 2>/dev/null | grep -q "tide"; then
    success "Tide theme is already installed."
  else
    "$shell_path" -c "fisher install IlanCosman/tide"
  fi
}
