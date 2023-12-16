git config --global --add --bool push.autoSetupRemote true
# git config --list --show-origin
# current=$(git branch --show-current)
# lastMsg=$(git show -s --format=%B)

function gitCommitFunc {
  msg=$1
  git add -A && git commit -m $msg
}
export -f gitCommitFunc
alias gitCommit="gitCommitFunc"

function gitFixupFunc {
  qnt=$1
  msg=$2
  if [ -z "$qnt" ]; then qnt=1; fi
  if [ -z "$msg" ]; then msg=$(git show -s --format=%B); fi
  git reset HEAD~$qnt && git add -A && git commit -m "$msg" && git push -f
}
export -f gitFixupFunc
alias gitFixup="gitFixupFunc"

function gitMoveFunc {
  branchDst=$1
  git add -A && git stash && git checkout $branchDst && git pull --rebase && git stash pop
}
export -f gitMoveFunc
alias gitMove="gitMoveFunc"

function gitMoveNewFunc {
  branchSrc=$1
  branchNew=$2
  git add -A && git stash && git checkout $branchSrc && git pull --rebase && git checkout -b $branchNew && git stash pop
}
export -f gitMoveNewFunc
alias gitMoveNew="gitMoveNewFunc"

