function gb
  git branch
end

function gbd
  git branch -d $argv
end

function gp
  git pull
end

function gf
  git push --force-with-lease
end

function grpo
  git remote prune origin
end

function fcp
  mix format
  git commit -am "formats for the format gods"
  git push
end
