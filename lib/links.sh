#!/usr/bin/env bash

source "$(dirname "$0")/lib/utils.sh"

function setup_links() {
  header "$LINK  Forging Symlinks"

  local dot_dir="$PWD/dotfiles"
  
  if [ ! -d "$dot_dir" ]; then
    error "dotfiles directory not found!"
    return 1
  fi

  info "Linking asdf..."
  ln -sf "$dot_dir/asdf/asdfrc" "$HOME/.asdfrc"
  ln -sf "$dot_dir/asdf/tool-versions" "$HOME/.tool-versions"

  info "Linking .config..."
  ln -sf "$dot_dir/config" "$HOME/.config"

  info "Linking git..."
  ln -sf "$dot_dir/git/gitattributes" "$HOME/.gitattributes"
  ln -sf "$dot_dir/git/gitconfig" "$HOME/.gitconfig"
  ln -sf "$dot_dir/git/gitignore" "$HOME/.gitignore"
  ln -sf "$dot_dir/git/gitmessage" "$HOME/.gitmessage"

  info "Setting iTerm2 preferences..."
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$dot_dir/iterm2"
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

  mkdir -p "$HOME/.local/bin"

  info "Linking psql..."
  ln -sf "$dot_dir/sql/psqlrc" "$HOME/.psqlrc"

  mkdir -p "$HOME/.ssh"

  info "Linking tmux..."
  ln -sf "$dot_dir/tmux/tmux.conf" "$HOME/.tmux.conf"

  success "All core symlinks forged."
}
