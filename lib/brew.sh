#!/usr/bin/env bash

# Homebrew Logic

source "$(dirname "$0")/lib/utils.sh"

function install_homebrew() {
  header "$BREW  Brewing Up Homebrew"

  # Detect architecture for prefix
  if [[ $(uname -m) == "arm64" ]]; then
    HOMEBREW_PREFIX="/opt/homebrew"
  else
    HOMEBREW_PREFIX="/usr/local"
  fi

  if [ -d "$HOMEBREW_PREFIX" ]; then
    info "Checking permissions for $HOMEBREW_PREFIX"
    if ! [ -r "$HOMEBREW_PREFIX" ]; then
      sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
    fi
  else
    info "Creating $HOMEBREW_PREFIX"
    sudo mkdir -p "$HOMEBREW_PREFIX"
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sudo chflags norestricted "$HOMEBREW_PREFIX"
    fi
    sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
  fi

  if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Load brew environment
    if [ -f "/opt/homebrew/bin/brew" ]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f "/usr/local/bin/brew" ]; then
      eval "$(/usr/local/bin/brew shellenv)"
    fi
  else
    success "Homebrew is already installed."
  fi

  info "Turning off analytics..."
  brew analytics off
  
  info "Updating Homebrew..."
  brew update
}

function brew_bundle() {
  local bundle_file="$1"
  local category_name="$2"

  if [ -f "$bundle_file" ]; then
    subheader "$PACKAGE  Installing $category_name"
    brew bundle --file="$bundle_file"
    success "$category_name installed successfully."
  else
    warn "No bundle file found for $category_name at $bundle_file"
  fi
}

function cleanup_homebrew() {
  header "$SPARKLES  Brew Cleanup"
  info "Upgrading packages..."
  brew upgrade
  info "Cleaning up..."
  brew cleanup
}
