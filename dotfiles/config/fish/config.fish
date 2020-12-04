set -x TERM xterm-256color
set -x EDITOR vim

for f in $HOME/.config/fish/env.d/*.fish;
  if test -f $f
    source $f
  end
end
