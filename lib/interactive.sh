#!/usr/bin/env bash
# Interactive selection library for brewtstrap
# Provides `choose_tasks` which populates `SELECTED_MODULES` array.

# Modules and human-friendly labels (order matters)
_MODULE_KEYS=(
  "brew_all"
  "homebrew" "dev" "runtimes" "cvml" "network" "modern" "apps" "fonts" "shell_media"
  "links" "macos" "fish" "vscode" "cleanup"
)
_MODULE_LABELS=(
  "📦 SELECT ALL HOMEBREW BUNDLES"
  "  ├── Core CLI Tools"
  "  ├── Development Tools (Git, K8s, etc.)"
  "  ├── Language Runtimes & Databases"
  "  ├── Computer Vision & ML (CVML)"
  "  ├── Networking Tools"
  "  ├── Modern AI Tools (Ollama, Claude, etc.)"
  "  ├── GUI Applications (Casks)"
  "  ├── Typography (Fonts)"
  "  └── Shell Environment & Media"
  "🔗 Link Dotfiles (Git, Tmux, psql, etc.)"
  "⚙️  Apply macOS System Preferences"
  "🐚 Switch default shell to Fish"
  "💻 Configure VSCode (Extensions & Settings)"
  "🧹 Run Homebrew cleanup & upgrade"
)

# choose_tasks: sets SELECTED_MODULES array (global) and returns.
choose_tasks() {
  if [ "${AUTO_INSTALL:-false}" = true ]; then
    SELECTED_MODULES=("${_MODULE_KEYS[@]}")
    return 0
  fi

  if command -v gum >/dev/null 2>&1; then
    SELECTED_MODULES=()
    # Read gum output line-by-line to stay compatible with older macOS bash
    while IFS= read -r ch; do
      for i in "${!_MODULE_LABELS[@]}"; do
        if [ "${_MODULE_LABELS[i]}" = "$ch" ]; then
          SELECTED_MODULES+=("${_MODULE_KEYS[i]}")
          break
        fi
      done
    # Run gum in a subshell with problematic style env vars unset
    done < <( (unset BOLD ITALIC UNDERLINE; printf "%s\n" "${_MODULE_LABELS[@]}" | gum choose --no-limit --header="Select modules to install (Space to toggle, Enter to confirm)") )

    if [ "${#SELECTED_MODULES[@]}" -eq 0 ]; then
      echo "No selection made; aborting." >&2
      exit 1
    fi

    # Expand "brew_all" if selected
    if is_selected "brew_all"; then
      for key in homebrew dev runtimes cvml network modern apps fonts shell_media; do
        if ! is_selected "$key"; then
          SELECTED_MODULES+=("$key")
        fi
      done
    fi

    return 0
  fi

  # gum not available: ask to bootstrap (install) or fall back
  if ask_yes_no "gum (nice TUI) is not installed. Install it now for a nicer UI?"; then
    if command -v brew >/dev/null 2>&1; then
      echo "Installing gum via Homebrew..."
      if brew install charmbracelet/gum/gum 2>/dev/null || brew install gum 2>/dev/null; then
        echo
        echo "gum was installed successfully. Please re-run this script to use the enhanced UI."
        echo "Exiting now so you can restart the script." >&2
        exit 0
      else
        echo "Automatic installation failed. Please install gum manually: https://github.com/charmbracelet/gum" >&2
        echo "Falling back to pure-bash UI."
      fi
    else
      echo "Homebrew not found; cannot auto-install gum. Falling back to pure-bash UI." >&2
    fi
  fi

  # Pure bash interactive checklist
  local -a sel
  for i in "${!_MODULE_KEYS[@]}"; do sel[i]=0; done

  while true; do
    echo
    echo "Toggle options (type numbers, ranges, or commands):"
    for i in "${!_MODULE_KEYS[@]}"; do
      idx=$((i+1))
      mark="[ ]"
      [ "${sel[i]}" -eq 1 ] && mark="[x]"
      printf "  %2d) %s %s\n" "$idx" "$mark" "${_MODULE_LABELS[i]}"
    done
    echo
    echo "Commands: all none invert done q"
    read -rp "Selection> " input
    case "$input" in
      all) for i in "${!sel[@]}"; do sel[i]=1; done ;;
      none) for i in "${!sel[@]}"; do sel[i]=0; done ;;
      invert) for i in "${!sel[@]}"; do sel[i]=$((1 - sel[i])); done ;;
      done)
        SELECTED_MODULES=()
        for i in "${!_MODULE_KEYS[@]}"; do
          [ "${sel[i]}" -eq 1 ] && SELECTED_MODULES+=("${_MODULE_KEYS[i]}")
        done
        # Expand "brew_all" if selected
        if is_selected "brew_all"; then
          for key in homebrew dev runtimes cvml network modern apps fonts shell_media; do
            if ! is_selected "$key"; then
              SELECTED_MODULES+=("$key")
            fi
          done
        fi
        return 0
        ;;
      q|quit) echo "Aborted."; exit 0 ;;
      *)
        IFS=',' read -ra parts <<< "$input"
        for p in "${parts[@]}"; do
          p="${p//[[:space:]]/}"
          if [[ "$p" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            a=${BASH_REMATCH[1]}; b=${BASH_REMATCH[2]}
            for ((k=a;k<=b;k++)); do
              idx=$((k-1))
              if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#_MODULE_KEYS[@]}" ]; then
                sel[idx]=$((1 - sel[idx]))
              fi
            done
          elif [[ "$p" =~ ^[0-9]+$ ]]; then
            idx=$((p-1))
            if [ "$idx" -ge 0 ] && [ "$idx" -lt "${#_MODULE_KEYS[@]}" ]; then
              sel[idx]=$((1 - sel[idx]))
            fi
          fi
        done
        ;;
    esac
  done
}

# Helper to test if a module key is selected
is_selected() {
  local key="$1"
  for v in "${SELECTED_MODULES[@]:-}"; do
    [ "$v" = "$key" ] && return 0
  done
  return 1
}
