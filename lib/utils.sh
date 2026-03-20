#!/usr/bin/env bash

# Colors
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# Emojis
export CHECK_MARK="✅"
export CROSS_MARK="❌"
export INFO_CIRCLE="ℹ️"
export WARNING="⚠️"
export BREW="🍺"
export COMPUTER="💻"
export GEAR="⚙️"
export ROCKET="🚀"
export LINK="🔗"
export SPARKLES="✨"
export TERMINAL="🐚"
export PACKAGE="📦"
export TOOLS="🛠️"
export DATABASE="🗄️"
export BRAIN="🧠"
export APPLE="🍏"
export FISH="🐟"
export FONT="🔠"
export MEDIA="🎬"
export CLEAN="🧹"

# Logging functions
function info() {
  echo -e "${BLUE}${INFO_CIRCLE}  $1${NC}"
}

function success() {
  echo -e "${GREEN}${CHECK_MARK}  $1${NC}"
}

function warn() {
  echo -e "${YELLOW}${WARNING}  $1${NC}"
}

function error() {
  echo -e "${RED}${CROSS_MARK}  $1${NC}"
}

function header() {
  echo -e "\n${BOLD}${PURPLE}================================================================================"
  echo -e "  $1"
  echo -e "================================================================================${NC}\n"
}

function subheader() {
  echo -e "\n${BOLD}${CYAN}--- $1 ---${NC}\n"
}

# Interactive menu
function ask_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local choice

  if [ "$default" == "y" ]; then
    prompt="$prompt [Y/n]: "
  else
    prompt="$prompt [y/N]: "
  fi

  # Use read -p but handle the emoji spacing
  echo -en "${BOLD}${YELLOW}  $prompt${NC}"
  read choice
  choice="${choice:-$default}"

  case "$choice" in
    [yY][eE][sS]|[yY]) return 0 ;;
    *) return 1 ;;
  esac
}

# Check if command exists
function command_exists() {
  command -v "$1" >/dev/null 2>&1
}
