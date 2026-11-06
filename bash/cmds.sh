# source "cmds.sh" >/dev/null 2>&1

# --- SHELL ---

function shell_init {
  if [[ -n ${BASH_VERSION:-} ]]; then
    SHELL_RC="$HOME/.bashrc"
    CMDS_FILE="${BASH_SOURCE[0]}"

    # Shell prefix
    PS1="${PS1%\\$ }"
    PS1="${PS1//\\w/\$PWD}\\[\033[01;31m\]\$(git branch --show-current 2>/dev/null | sed 's/^/(/;s/$/)/')\\[\033[00m\]\$ "
  elif [[ -n ${ZSH_VERSION:-} ]]; then
    SHELL_RC="$HOME/.zshrc"
    CMDS_FILE="${(%):-%x}"

    # Enable Zsh completion.
    if [[ -z ${_CMDS_COMPINIT_DONE:-} ]]; then
      autoload -Uz compinit
      compinit
      _CMDS_COMPINIT_DONE=1
    fi

    # Shell prefix
    setopt prompt_subst
    PROMPT='%/$(git symbolic-ref --quiet --short HEAD 2>/dev/null | sed "s/.*/(&)/") > '
  fi

  # Resolve cmds.sh to an absolute path.
  CMDS_FILE="$(cd -P "$(dirname "$CMDS_FILE")" && pwd -P)/$(basename "$CMDS_FILE")"
}
shell_init

function shell_sync {
  source "$SHELL_RC"
}

function shell_set {
  nano "$SHELL_RC" && source "$SHELL_RC"
}


# --- GITHUB ---

function git_commit {
  msg=$1
  git add -A && git commit -m "$msg"
}

function git_fixup {
  qnt=$1
  msg=$2
  if [ -z "$qnt" ]; then qnt=1; fi
  if [ -z "$msg" ]; then msg=$(git show -s --format=%B); fi
  git reset HEAD~$qnt && git add -A && git commit -m "$msg" && git push -f
}

function git_move {
  branchSrc=$1
  branchNew=$2
  git add -A && git stash && git checkout "$branchSrc" && git pull --rebase
  if [ -n "$branchNew" ]; then git checkout -b "$branchNew"; fi
  git stash pop
}

function git_update {
  branchSrc=$1
  git add -A && git stash && git pull origin "$branchSrc" --rebase && git stash pop
}


# --- AWS ---

function aws_login {
  aws sso login --sso-session lp
}

function aws_profiles {
  sed -n "s/^\[profile \(.*\)\]/\1/p" "$HOME/.aws/config"
}

function aws_profile {
  export AWS_PROFILE="$1"
  aws_info
}
complete -W '$(aws_profiles)' aws_profile 2>/dev/null ||
  compdef '_values profile $(aws_profiles)' aws_profile

function aws_region {
  export AWS_REGION="$1"
  export AWS_DEFAULT_REGION="$1"
  aws_info
}
complete -W 'us-east-1 us-east-2 us-west-1 us-west-2 eu-west-1' aws_region 2>/dev/null ||
  compdef '_values region us-east-1 us-east-2 us-west-1 us-west-2 eu-west-1' aws_region

function aws_info {
  echo "profile:  ${AWS_PROFILE:-unset}"
  echo "region:   ${AWS_REGION:-$(aws configure get region 2>/dev/null || echo unset)}"
  identity=$(aws sts get-caller-identity --query '[Account,Arn]' --output text 2>/dev/null)
  if [ -n "$identity" ]; then
    echo "account:  $(echo "$identity" | cut -f1)"
    echo "arn:      $(echo "$identity" | cut -f2)"
  else
    echo "account:  no valid session, run aws_login"
  fi
}


# --- KUBERNETES ---

# clusters have private endpoints, tailscale must be up first

function kube_login {
  aws eks update-kubeconfig --region us-east-1 --profile [profile] --name [name] --alias [alias]
}

function kube_contexts {
  kubectl config view -o json | jq -r '."current-context" as $cur | .contexts[] | [if .name == $cur then "*" else " " end, .name, (.context.namespace // "-")] | @tsv' | column -t -s $'\t'
}

function kube_context {
  kubectl config use-context "$1" >/dev/null && kube_info
}
complete -W '$(kubectl config get-contexts -o name)' kube_context 2>/dev/null ||
  compdef '_values context $(kubectl config get-contexts -o name)' kube_context

function kube_namespace {
  kubectl config set-context --current --namespace="$1" >/dev/null && kube_info
}

function kube_info {
  echo "context:   $(kubectl config current-context 2>/dev/null)"
  echo "namespace: $(kubectl config view --minify -o jsonpath='{..namespace}' 2>/dev/null)"
  echo "profile:   ${AWS_PROFILE:-unset}"
}

function kube_monitor_old {
  local CTX=$1 INTERVAL=${2:-10}
  if [ -z "$CTX" ]; then
    echo "usage: kube_monitor_old <context> [interval_seconds=10]   (contexts: $(kubectl config get-contexts -o name | tr '\n' ' '))" >&2
    return 1
  fi

  local ARN=$(kubectl config view -o json | jq -r --arg c "$CTX" '.contexts[] | select(.name==$c) | .context.cluster')
  if [ -z "$ARN" ]; then
    echo "kube_monitor_old: unknown context '$CTX'" >&2
    return 1
  fi
  local CLUSTER=${ARN##*:cluster/}
  local PROFILE=$(kubectl config view -o json | jq -r --arg c "$CTX" '(.contexts[] | select(.name==$c) | .context.user) as $u | .users[] | select(.name==$u) | (.user.exec.env // [])[] | select(.name=="AWS_PROFILE") | .value')

  # Use Bash for the watcher even when the interactive shell is Zsh.
  # The child sources this file, so it does not need an exported function.
  KM_CTX="$CTX" \
  KM_CLUSTER="$CLUSTER" \
  KM_PROFILE="$PROFILE" \
  KM_CMDS_FILE="$CMDS_FILE" \
    watch -n "$INTERVAL" -t -x bash -c \
    'source "$KM_CMDS_FILE" >/dev/null 2>&1; kube_monitor_snapshot'
}
complete -W '$(kubectl config get-contexts -o name)' kube_monitor_old 2>/dev/null ||
  compdef '_values context $(kubectl config get-contexts -o name)' kube_monitor_old

function kube_monitor_snapshot {
  local K=(--context "$KM_CTX" --request-timeout=20s)
  echo -e "[$KM_CTX | $KM_CLUSTER | $KM_PROFILE] @$(date -u '+%H:%M:%SZ')\n"
  # every <(...) starts at once; cat reads them in order, so sections run in parallel but print in sequence
  cat \
    <({ echo "> Cluster Info:"; aws eks describe-cluster --name "$KM_CLUSTER" --profile "$KM_PROFILE" --region us-east-1 --query 'cluster.{v:version,s:status}' --output text; } 2>&1) \
    <({ echo -n "Nodes: "; kubectl "${K[@]}" get nodes,nodeclaims -o json | jq -r '(.items | map(select(.kind=="NodeClaim") | {key: (.status.nodeName // ""), value: .}) | from_entries) as $nc | [.items[] | select(.kind=="Node") | ($nc[.metadata.name] // {}) as $cl | {ver: (.status.nodeInfo.kubeletVersion | split("-")[0]), st: (if (.metadata.deletionTimestamp or $cl.metadata.deletionTimestamp) then "Deleting" elif any(.status.conditions[]; .type=="Ready" and .status!="True") then "NotReady" elif any(($cl.status.conditions // [])[]; .type=="Drifted" and .status=="True") then "Drifted" elif .spec.unschedulable then "Cordoned" else "Ready" end)}] | [(group_by(.ver)[] | "\(length) \(.[0].ver)"), (group_by(.st) | sort_by(-length)[] | "\(length) \(.[0].st)")] | join(" / ")'; } 2>&1) \
    <({ echo -n "Volumes: "; { for n in $(kubectl "${K[@]}" get volumeattachments -o json | jq -r '[.items[] | select(.status.attached) | .spec.nodeName] | unique[]'); do kubectl "${K[@]}" get --raw /api/v1/nodes/$n/proxy/stats/summary 2>/dev/null | jq -c '[.pods[] | .podRef.name as $p | .volume[]? | select(.pvcRef) | {grp: ($p | sub("-[0-9]+$"; "") | sub("-[a-z0-9]{8,10}-[a-z0-9]{5}$"; "") | gsub("-?victoria-metrics-k8s-stack-?"; "")), used: .usedBytes, cap: .capacityBytes}]' & done; wait; } | jq -rs 'add // [] | "\(length) PVCs / \(map(.used)|add/1073741824|floor)/\(map(.cap)|add/1073741824|floor)Gi used / " + (map(.pct = (.used*100/.cap|floor)) | group_by(.grp) | sort_by(-(map(.pct)|max)) | map("\(.[0].grp) (\(map(.pct) | sort | map("\(.)%") | join(", ")))" ) | join(", "))'; } 2>&1) \
    <({ kubectl "${K[@]}" get nodes -l eks.amazonaws.com/nodegroup; } 2>&1) \
    <({ echo -e '\n> Addons:'; kubectl "${K[@]}" -n kube-system get ds; } 2>&1) \
    <({ echo -e '\n> Deleting Nodes:'; kubectl "${K[@]}" get nodeclaims -o json | jq -r '["NAME","NODE","DRIFTED_AT","DRIFT_REASON","DELETING_AT","DEL_REASON","DEL_STATUS"], (.items[] | (.status.conditions // []) as $c | select(any($c[]; .type=="Drifted" and .status=="True") or .metadata.deletionTimestamp) | [.metadata.name, .status.nodeName, ((first($c[]|select(.type=="Drifted" and .status=="True")|.lastTransitionTime) // "-") | sub("\\..*Z$"; "Z")), (first($c[]|select(.type=="Drifted" and .status=="True")|.reason) // "-"), (.metadata.deletionTimestamp // "-"), (first($c[]|select(.type=="DisruptionReason")|.reason) // "-"), ([$c[]|select(.status!="True")|"\(.type)=\(.reason)"] | if length==0 then "-" else join(",") end)]) | @tsv' | column -t | head -n 11; } 2>&1) \
    <({ echo -e '\n> Pending Pods:'; kubectl "${K[@]}" get pods -A --sort-by=.metadata.creationTimestamp | grep -vE 'Running|Completed' | head -n 11; } 2>&1)
}
