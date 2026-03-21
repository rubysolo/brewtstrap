#!/usr/bin/env bash

# Homebrew Logic



BREWTSTRAP_CACHE_DIR="${HOME}/.brewtstrap"
CASK_ARTIFACTS_CACHE="${BREWTSTRAP_CACHE_DIR}/cask_artifacts.json"
CASK_CACHE_MAX_AGE_DAYS=7

CACHED_CASKS=""

function ensure_cache_dir() {
  if [ ! -d "$BREWTSTRAP_CACHE_DIR" ]; then
    mkdir -p "$BREWTSTRAP_CACHE_DIR"
  fi
}

function is_cache_valid() {
  if [ ! -f "$CASK_ARTIFACTS_CACHE" ]; then
    return 1
  fi
  
  local cache_age
  cache_age=$(($(date +%s) - $(stat -f %m "$CASK_ARTIFACTS_CACHE" 2>/dev/null || stat -c %Y "$CASK_ARTIFACTS_CACHE" 2>/dev/null)))
  local max_age_seconds=$((CASK_CACHE_MAX_AGE_DAYS * 86400))
  
  [ "$cache_age" -lt "$max_age_seconds" ]
}

function get_cached_app_name() {
  local cask_name="$1"
  echo "$CACHED_CASKS" | jq -r ".\"$cask_name\" // empty" 2>/dev/null
}

function update_cached_app_name() {
  local cask_name="$1"
  local app_name="$2"
  
  if [ -z "$app_name" ]; then
    CACHED_CASKS=$(echo "$CACHED_CASKS" | jq "del(.\"$cask_name\")" 2>/dev/null)
  else
    CACHED_CASKS=$(echo "$CACHED_CASKS" | jq ".\"$cask_name\" = \"$app_name\"" 2>/dev/null)
  fi
}

function save_cask_cache() {
  ensure_cache_dir
  echo "$CACHED_CASKS" | jq '.' > "$CASK_ARTIFACTS_CACHE"
}

function load_cask_cache() {
  if is_cache_valid; then
    CACHED_CASKS=$(cat "$CASK_ARTIFACTS_CACHE" 2>/dev/null)
    return 0
  fi
  CACHED_CASKS="{}"
  return 1
}

function get_cask_app_name() {
  local cask_name="$1"
  
  local cached
  cached=$(get_cached_app_name "$cask_name")
  
  if [ -n "$cached" ]; then
    echo "$cached"
    return
  fi
  
  local app_name
  app_name=$(brew info --cask --json=v2 "$cask_name" 2>/dev/null | jq -r '.casks[0].artifacts[] | select(.app) | .app[0]' 2>/dev/null)
  
  if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
    update_cached_app_name "$cask_name" "$app_name"
    echo "$app_name"
  else
    update_cached_app_name "$cask_name" ""
    echo ""
  fi
}

function batch_get_cask_apps() {
  local cask_names=("$@")
  
  if [ ${#cask_names[@]} -eq 0 ]; then
    return
  fi
  
  local json_output
  json_output=$(brew info --cask --json=v2 "${cask_names[@]}" 2>/dev/null)
  
  local cask
  for cask in "${cask_names[@]}"; do
    local app_name
    app_name=$(echo "$json_output" | jq -r ".casks[] | select(.token == \"$cask\") | .artifacts[] | select(.app) | .app[0]" 2>/dev/null)
    
    if [ -n "$app_name" ] && [ "$app_name" != "null" ]; then
      update_cached_app_name "$cask" "$app_name"
    else
      update_cached_app_name "$cask" ""
    fi
  done
}

function is_app_installed() {
  local cask_name="$1"
  
  if brew list --cask "$cask_name" >/dev/null 2>&1; then
    return 0
  fi
  
  local app_name
  app_name=$(get_cask_app_name "$cask_name")
  
  if [ -z "$app_name" ]; then
    return 1
  fi
  
  if [ -d "/Applications/$app_name" ] || [ -d "$HOME/Applications/$app_name" ]; then
    return 0
  fi
  
  return 1
}

function extract_cask_names() {
  local bundle_file="$1"
  grep -E '^cask "' "$bundle_file" | sed -E 's/cask "(.+)"/\1/' | tr -d ' '
}

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

  if [ ! -f "$bundle_file" ]; then
    warn "No bundle file found for $category_name at $bundle_file"
    return
  fi

  local cask_names_str
  cask_names_str=$(extract_cask_names "$bundle_file")
  
  if [ -z "$cask_names_str" ]; then
    subheader "$PACKAGE  Installing $category_name"
    brew bundle --file="$bundle_file"
    success "$category_name installed successfully."
    return
  fi

  local cask_names=()
  while IFS= read -r line; do
    [ -n "$line" ] && cask_names+=("$line")
  done <<< "$cask_names_str"

  if [ ${#cask_names[@]} -eq 0 ]; then
    subheader "$PACKAGE  Installing $category_name"
    brew bundle --file="$bundle_file"
    success "$category_name installed successfully."
    return
  fi

  local homebrew_installed
  homebrew_installed=$(brew list --cask 2>/dev/null)
  
  local casks_to_install=()
  local skipped_count=0
  
  ensure_cache_dir
  load_cask_cache || true

  for cask in "${cask_names[@]}"; do
    if echo "$homebrew_installed" | grep -q "^${cask}$"; then
      casks_to_install+=("$cask")
    else
      if is_app_installed "$cask"; then
        skipped_count=$((skipped_count + 1))
      else
        casks_to_install+=("$cask")
      fi
    fi
  done

  save_cask_cache

  if [ ${#casks_to_install[@]} -eq 0 ]; then
    subheader "$PACKAGE  $category_name"
    info "All ${#cask_names[@]} apps already installed, skipping."
    return
  fi

  subheader "$PACKAGE  Installing $category_name"
  
  if [ "$skipped_count" -gt 0 ]; then
    info "Skipping $skipped_count already installed app(s)."
  fi

  local temp_bundle
  temp_bundle=$(mktemp)
  trap "rm -f $temp_bundle" RETURN
  
  for cask in "${casks_to_install[@]}"; do
    echo "cask \"$cask\"" >> "$temp_bundle"
  done
  
  brew bundle --file="$temp_bundle"
  success "$category_name installed successfully."
}

function cleanup_homebrew() {
  header "$SPARKLES  Brew Cleanup"
  info "Upgrading packages..."
  brew upgrade
  info "Cleaning up..."
  brew cleanup
}
