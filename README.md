# Brewtstrap - Modern Machine Setup (2026 Edition)

`Brewtstrap` is a set of scripts to bootstrap a new macOS machine, tailored for developers. It's designed to be interactive, modular, and easily customizable. This project is heavily inspired by and borrows from [Dan Croak's laptop repo](https://github.com/croaky/laptop) and [Mathias Bynens' dotfiles](https://github.com/mathiasbynens/dotfiles).  Updated for Tahoe.

## Features

- **Interactive Setup**: Guides you through the installation process, asking which components you want to install.
- **"Lights Out" Mode**: An option to install everything without any user interaction.
- **Homebrew-based**: Uses `brew` to install a wide range of software, from core CLI tools to GUI applications.
- **Modular Brewfiles**: Separates Homebrew packages into logical bundles (`core`, `dev`, `apps`, etc.).
- **Dotfile Management**: Symlinks configuration files for common tools like Git, Tmux, Fish, and more.
- **macOS Defaults**: Applies sensible macOS preferences to improve the user experience.
- **Shell Configuration**: Sets up the [Fish shell](https://fishshell.com/) as the default shell.
- **VSCode Setup**: Configures VSCode settings, keybindings, and installs a list of extensions.

## Usage

1. **Clone the repository:**

    ```bash
    git clone https://github.com/your-username/brewtstrap.git
    cd brewtstrap
    ```

2. **Run the setup script:**
    - **Interactive Mode (Recommended)**:

      ```bash
      ./setup.sh
      ```

      The script will ask for confirmation at each major step (e.g., installing core tools, development tools, GUI apps, etc.).

    - **Non-Interactive ("Lights Out") Mode**:
      To install everything without being prompted, use the `--all` or `-a` flag:

      ```bash
      ./setup.sh --all
      ```

## Customization

You can easily customize `Brewtstrap` to fit your needs by modifying the files in the `lib/brew/` and `dotfiles/` directories.

- **Homebrew Packages**: To add or remove Homebrew packages, edit the `*.Brewfile` files located in the `lib/brew/` directory. For example, to add a new development tool, add it to `lib/brew/dev.Brewfile`.

- **Dotfiles**: The `dotfiles/` directory contains the configuration files that are symlinked into your home directory. You can add new files or modify existing ones to change the configuration of your tools.

- **VSCode Extensions**: The list of VSCode extensions to be installed is in `dotfiles/vscode/extensions`. Add or remove extension IDs from this file.

## Project Structure

- **`setup.sh`**: The main executable script.
- **`lib/`**: Contains the core logic of the setup script, broken down into modular shell scripts.
  - `brew.sh`: Handles Homebrew installation and bundle management.
  - `links.sh`: Manages dotfile symlinking.
  - `macos.sh`: Applies macOS preferences.
  - `shell.sh`: Configures the shell environment.
  - `utils.sh`: Provides logging and utility functions.
  - `vscode.sh`: Sets up Visual Studio Code.
  - **`lib/brew/`**: Contains `Brewfile`s for different categories of packages.
- **`dotfiles/`**: Contains all the configuration files to be symlinked.
- **`README.md`**: You are here.

## Enjoy your new setup
