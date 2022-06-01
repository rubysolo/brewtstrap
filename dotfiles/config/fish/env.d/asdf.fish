if test -f (brew --prefix)/opt/asdf/asdf.fish
  source (brew --prefix)/opt/asdf/asdf.fish
else
  echo -e "\e[31mERROR: (brew --prefix)/opt/asdf/asdf.fish not found.\e[0m"
end
