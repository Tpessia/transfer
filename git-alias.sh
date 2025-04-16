# git config --global --add --bool push.autoSetupRemote true
# git config --list --show-origin
# current=$(git branch --show-current)
# lastMsg=$(git show -s --format=%B)

function git_commit {
  msg=$1
  git add -A && git commit -m "$msg"
}
export -f git_commit
# alias git_commit="git_commit"

function git_fixup {
  qnt=$1
  msg=$2
  if [ -z "$qnt" ]; then qnt=1; fi
  if [ -z "$msg" ]; then msg=$(git show -s --format=%B); fi
  git reset HEAD~$qnt && git add -A && git commit -m "$msg" && git push -f
}
export -f git_fixup
# alias git_fixup="git_fixup"

function git_move {
  branchSrc=$1
  branchNew=$2
  git add -A && git stash && git checkout $branchSrc && git pull --rebase
  if [ -n "$branchNew" ]; then git checkout -b $branchNew; fi
  git stash pop
}
export -f git_move
# alias git_move="git_move"

function git_update {
  branchSrc=$1
  git add -A && git stash && git pull origin $branchSrc --rebase && git stash pop
}
export -f git_update
# alias git_update="git_update"

