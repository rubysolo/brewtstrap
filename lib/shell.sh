#!/usr/bin/env bash

source "$(dirname "$0")/lib/utils.sh"

function setup_shell() {
  header "$TERMINAL  Swimming in the Fish Shell"

  HOMEBREW_PREFIX="/opt/homebrew"
  local shell_path="$HOMEBREW_PREFIX/bin/fish"

  if [ ! -f "$shell_path" ]; then
    warn "Fish shell not found at $shell_path. Did you install the shell brew bundle?"
    return 1
  fi

  info "Setting permissions for fish..."
  sudo chown -R $(whoami) "$shell_path"
  chmod u+w "$shell_path"

  if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
    info "Adding fish to /etc/shells..."
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi

  if [ "$SHELL" != "$shell_path" ]; then
    info "Changing default shell to fish..."
    chsh -s "$shell_path"
    success "Default shell changed to fish."
  else
    success "Fish is already your default shell."
  fi
}
