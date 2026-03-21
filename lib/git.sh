#!/usr/bin/env bash

source "$(dirname "$0")/lib/utils.sh"

function setup_git() {
  header "$GIT  Configuring Git"

  local gitconfig_local="$HOME/.gitconfig.local"

  if [ -f "$gitconfig_local" ]; then
    success "Local git configuration found at $gitconfig_local."
    return 0
  fi

  info "No local git configuration found. Let's set it up!"
  
  local user_name=""
  local user_email=""

  read -p "Enter your Git user name: " user_name
  read -p "Enter your Git user email: " user_email

  if [ -n "$user_name" ] && [ -n "$user_email" ]; then
    cat > "$gitconfig_local" <<EOF
[user]
  name = $user_name
  email = $user_email
EOF
    success "Local git configuration created at $gitconfig_local."
  else
    warn "Git configuration skipped. You can manually create $gitconfig_local later."
  fi
}
