set TERM xterm-256color

for f in $HOME/.config/fish/env.d/*.fish;
  if test -f $f
    source $f
  end
end
