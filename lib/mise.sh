#!/usr/bin/env bash
# Mise runtime manager setup

MISE_LANGUAGES=(
  "node"
  "python"
  "ruby"
  "rust"
  "go"
  "java"
  "elixir"
  "erlang"
  "php"
  "lua"
)

setup_mise() {
  header "$TOOLS  Setting up Mise"
  
  if ! command -v mise >/dev/null 2>&1; then
    warn "Mise is not installed. Please install it first (should be in dev.Brewfile)."
    return 1
  fi
  
  info "Mise found at: $(which mise)"
  echo
  
  local -a selected_languages=()
  
  if [ "$AUTO_INSTALL" = true ]; then
    selected_languages=("${MISE_LANGUAGES[@]}")
  else
    if command -v gum >/dev/null 2>&1; then
      while IFS= read -r lang; do
        for l in "${MISE_LANGUAGES[@]}"; do
          if [ "$l" = "$lang" ]; then
            selected_languages+=("$l")
            break
          fi
        done
      done < <( (unset BOLD ITALIC UNDERLINE; printf "%s\n" "${MISE_LANGUAGES[@]}" | gum choose --no-limit --header="Select languages/runtimes to install (Space to toggle, Enter to confirm)") )
    else
      echo "Select languages/runtimes to install via mise:"
      echo
      local -a sel
      for i in "${!MISE_LANGUAGES[@]}"; do sel[i]=0; done
      
      while true; do
        echo
        for i in "${!MISE_LANGUAGES[@]}"; do
          idx=$((i+1))
          mark="[ ]"
          [ "${sel[i]}" -eq 1 ] && mark="[x]"
          printf "  %2d) %s %s\n" "$idx" "$mark" "${MISE_LANGUAGES[i]}"
        done
        echo
        echo "Commands: all none done q"
        read -rp "Selection> " input
        case "$input" in
          all) for i in "${!sel[@]}"; do sel[i]=1; done ;;
          none) for i in "${!sel[@]}"; do sel[i]=0; done ;;
          done)
            for i in "${!sel[@]}"; do
              [ "${sel[i]}" -eq 1 ] && selected_languages+=("${MISE_LANGUAGES[i]}")
            done
            break
            ;;
          q|quit) echo "Aborted."; return 1 ;;
          *)
            IFS=',' read -ra parts <<< "$input"
            for p in "${parts[@]}"; do
              p="${p//[[:space:]]/}"
              if [[ "$p" =~ ^([0-9]+)-([0-9]+)$ ]]; then
                a=${BASH_REMATCH[1]}; b=${BASH_REMATCH[2]}
                for ((k=a;k<=b;k++)); do
                  idx=$((k-1))
                  if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#MISE_LANGUAGES[@]}" ]; then
                    sel[idx]=$((1 - sel[idx]))
                  fi
                done
              elif [[ "$p" =~ ^[0-9]+$ ]]; then
                idx=$((p-1))
                if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#MISE_LANGUAGES[@]}" ]; then
                  sel[idx]=$((1 - sel[idx]))
                fi
              fi
            done
            ;;
        esac
      done
    fi
  fi
  
  if [ ${#selected_languages[@]} -eq 0 ]; then
    info "No languages selected. Skipping mise setup."
    return 0
  fi
  
  echo
  info "Installing via mise: ${selected_languages[*]}"
  
  local mise_config_dir="$HOME/.config/mise"
  local mise_config_file="$mise_config_dir/config.toml"
  
  if [ ! -d "$mise_config_dir" ]; then
    mkdir -p "$mise_config_dir"
  fi
  
  local -a config_lines
  
  local -a install_order
  install_order=("erlang" "elixir")

  for dep in "${install_order[@]}"; do
    if [[ " ${selected_languages[*]} " =~ " $dep " ]]; then
      info "Installing $dep first (required dependency)..."
      if mise install "$dep@latest" 2>&1; then
        success "$dep installed"
      else
        warn "Failed to install $dep - skipping (required for elixir)"
        selected_languages=("${selected_languages[@]/$dep}")
      fi
    fi
  done

  for lang in "${selected_languages[@]}"; do
    if [ "$lang" = "erlang" ] || [ "$lang" = "elixir" ]; then
      continue
    fi

    info "Installing latest stable $lang..."
    local output
    if output=$(mise install "$lang@latest" 2>&1); then
      success "$lang installed"
      local current_version
      current_version=$(mise current "$lang" 2>/dev/null | head -1)
      if [ -n "$current_version" ]; then
        config_lines+=("$lang = \"$current_version\"")
      fi
    else
      if echo "$output" | grep -qi "not found\|invalid\|unknown"; then
        warn "Failed to install $lang: not a valid mise plugin or missing dependency"
      else
        warn "Failed to install $lang (check output above for details)"
      fi
    fi
  done
  
  if [ ${#config_lines[@]} -gt 0 ]; then
    {
      for line in "${config_lines[@]}"; do
        echo "$line"
      done
    } > "$mise_config_file"
    success "Mise config updated at $mise_config_file"
  fi
  
  info "Run 'mise list' to see installed tool versions."
}
