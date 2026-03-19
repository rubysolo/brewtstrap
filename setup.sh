#!/bin/bash

# ./setup.sh

# - installs system packages with Homebrew package manager
# - changes shell to fish from Homebrew
# - creates symlinks from `$(pwd)/dotfiles` to `$HOME`
# - installs programming language runtimes with asdf
# - installs or updates Vim plugins

# This script can be run safely multiple times.
# It is tested on macOS Big Sur (11.0).

set -eux

#------------------------------------------------------------------------------
# Homebrew and packages
HOMEBREW_PREFIX="/opt/homebrew"

if [ -d "$HOMEBREW_PREFIX" ]; then
  if ! [ -r "$HOMEBREW_PREFIX" ]; then
    sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
  fi
else
  sudo mkdir "$HOMEBREW_PREFIX"
  sudo chflags norestricted "$HOMEBREW_PREFIX"
  sudo chown -R "$LOGNAME:admin" "$HOMEBREW_PREFIX"
fi

if ! command -v brew >/dev/null; then
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash
  export PATH="$HOMEBREW_PREFIX/bin:$PATH"
fi

brew analytics off
brew update
brew bundle -v --file=- <<EOF
  brew "ack"
  brew "awscli"
  brew "coreutils"
  brew "csvkit"
  brew "curl"
  brew "dos2unix"
  brew "exercism"
  brew "fd"
  brew "fish"
  brew "fzf"
  brew "gemini-cli"
  brew "gh"
  brew "gifsicle"
  brew "git"
  brew "git-lfs"
  brew "glew"
  brew "glfw3"
  brew "goreleaser"
  brew "gpg"
  brew "graphviz"
  brew "helix"
  brew "hub"
  brew "jq"
  brew "k9s"
  brew "kubectl"
  brew "libyaml"
  brew "lsd"
  brew "mas"
  brew "miller"
  brew "mkcert"
  brew "ocrmypdf"
  brew "ollama"
  brew "openconnect"
  brew "openssl"
  brew "pkg-config"
  brew "postgresql"
  brew "protobuf"
  brew "pgformatter"
  brew "redis"
  brew "ripgrep"
  brew "shared-mime-info"
  brew "shellcheck"
  brew "the_silver_searcher"
  brew "tfenv"
  brew "tflint"
  brew "tldr"
  brew "tmux"
  brew "tor"
  brew "tree"
  brew "tree-sitter-cli"
  brew "vim"
  brew "watch"
  brew "watchman"
  brew "yt-dlp"
  brew "zellij"
  brew "zlib"

  cask "1password-cli"
  cask "alfred"
  cask "boop"
  cask "claude-code"
  cask "clipy"
  cask "copilot-cli"
  cask "dash"
  cask "discord"
  cask "docker-desktop"
  cask "dropbox"
  cask "fontforge-app"
  cask "font-cascadia-code"
  cask "font-consolas-for-powerline"
  cask "font-envy-code-r"
  cask "font-inconsolata"
  cask "font-monaspace"
  cask "ghostty"
  cask "gitup-app"
  cask "iterm2"
  cask "maccy"
  cask "ngrok"
  cask "rectangle"
  cask "the-unarchiver"
  cask "tunnelblick"
  cask "visual-studio-code"
  cask "vlc"
EOF

brew install --cask ./font-envy-code-r-nerd-font.rb

brew upgrade
brew cleanup

#------------------------------------------------------------------------------
# Set preferences
$PWD/dotfiles/macprefs

#------------------------------------------------------------------------------
# Shell
update_shell() {
  (
    sudo chown -R $(whoami) /usr/local/share/fish
    chmod u+w /usr/local/share/fish
  )

  local shell_path;
  shell_path="$(command -v fish)"

  if ! grep "$shell_path" /etc/shells > /dev/null 2>&1 ; then
    sudo sh -c "echo $shell_path >> /etc/shells"
  fi
  chsh -s "$shell_path"
}

case "$SHELL" in
  */fish)
    if [ "$(command -v fish)" != "$HOMEBREW_PREFIX/bin/fish" ] ; then
      update_shell
    fi
    ;;
  *)
    update_shell
    ;;
esac

#------------------------------------------------------------------------------
# Symlinks
(
  cd "dotfiles"

  ln -sf "$PWD/asdf/asdfrc" "$HOME/.asdfrc"
  ln -sf "$PWD/asdf/tool-versions" "$HOME/.tool-versions"

  ln -sf "$PWD/config" "$HOME/.config"

  ln -sf "$PWD/git/gitattributes" "$HOME/.gitattributes"
  ln -sf "$PWD/git/gitconfig" "$HOME/.gitconfig"
  ln -sf "$PWD/git/gitignore" "$HOME/.gitignore"
  ln -sf "$PWD/git/gitmessage" "$HOME/.gitmessage"

  # Specify the preferences directory
  defaults write com.googlecode.iterm2.plist PrefsCustomFolder -string "$PWD/iterm2"
  # Tell iTerm2 to use the custom preferences in the directory
  defaults write com.googlecode.iterm2.plist LoadPrefsFromCustomFolder -bool true

  mkdir -p "$HOME/.local/bin"

  ln -sf "$PWD/sql/psqlrc" "$HOME/.psqlrc"

  mkdir -p "$HOME/.ssh"

  ln -sf "$PWD/tmux/tmux.conf" "$HOME/.tmux.conf"

  mkdir -p "$HOME/Library/Application Support/Code/User"
  ln -s "$PWD/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
  ln -s "$PWD/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
  ln -s "$PWD/vscode/snippets" "$HOME/Library/Application Support/Code/User/snippets"

  cat "$PWD/vscode/extensions" | grep -v '^#' | egrep -v '^\s*$' | xargs -L1 code --install-extension

  defaults write com.microsoft.VSCode ApplePressAndHoldEnabled -bool false
)

#------------------------------------------------------------------------------
# Languages
asdf_install() {
  if ! asdf plugin-list | grep -Fq "$1"; then
    asdf plugin-add $1
  fi

  asdf install $1 latest
  asdf global $1 $(asdf latest $1)
}

# link against brew libraries
BREW_PACKAGES=(openssl zlib readline)
SYSROOT=$(xcrun --sdk macosx --show-sdk-path)

INCLUDES=""
LIBRARIES=""
for INDEX in ${!BREW_PACKAGES[@]}; do
    BREW_PACKAGE=${BREW_PACKAGES[${INDEX}]}
    PATH_PREFIX=$(brew --prefix ${BREW_PACKAGE})
    INCLUDES="-I${PATH_PREFIX}/include ${INCLUDES}"
    LIBRARIES="-L${PATH_PREFIX}/lib ${LIBRARIES}"
done
INCLUDES="${INCLUDES} -I${SYSROOT}/usr/include"
LIBRARIES="${LIBRARIES} -L${SYSROOT}/usr/lib"

export CFLAGS="-isysroot ${SYSROOT} ${INCLUDES}"
export LDFLAGS="${LIBRARIES}"

# we don't need no steenking signatures!
export NODEJS_CHECK_SIGNATURES=no

asdf_install elixir
asdf_install elm
asdf_install gleam
asdf_install golang
asdf_install nodejs
asdf_install purescript
asdf_install python
asdf_install ruby
asdf_install rust
asdf_install yarn
