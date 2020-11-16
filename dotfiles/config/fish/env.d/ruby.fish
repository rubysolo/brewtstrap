function unused_ruby_methods
  for i in $argv/*.rb
    gsed "s/\s\+def \(self\.\)\?\([^( ]*\).*\|\s+scope :\([^,]*\).*/\2\3/;tx;d;:x" $i | while read j
      echo (grep -R $j app/ lib/ config/ | wc -l) $j
    end
  end | sort -rn
end

function unused_views
  for i in (find app/views/ -type f)
    echo (grep -R (echo $i | gsed "s/.*\/_\?\([^.]*\).*/\1/") app/ | wc -l) $i
  end | sort -rn
end