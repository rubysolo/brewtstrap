set -x TERM xterm-256color
set -x EDITOR vim

fish_add_path /opt/homebrew/bin

eval (brew shellenv)

for f in $HOME/.config/fish/env.d/*.fish;
  if test -f $f
    source $f
  end
end

# pnpm
set -gx PNPM_HOME "/Users/solo/Library/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end