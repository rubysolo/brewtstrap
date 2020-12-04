function fcp
  mix format
  git commit -am "formats for the format god"
  git push
end

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

# git config to bypass hooks
alias nhgit='env HOME=$HOME/.config/git/no-hooks git'
