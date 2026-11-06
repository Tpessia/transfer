#!/usr/bin/env bash
# Creates <code dir>/.links with symlinks to config files outside the workspace.
# Usage: links.sh [code dir, default ~/code/.docs]
set -euo pipefail

CODE_DIR="${1:-$HOME/code/.docs}"
CODE_DIR="${CODE_DIR%/}"
LINKS="$CODE_DIR/.links"

VSCODE_USER=$([ "$(uname -s)" = "Darwin" ] && echo "$HOME/Library/Application Support/Code/User" || echo "${XDG_CONFIG_HOME:-$HOME/.config}/Code/User")

link() {
  mkdir -p "$(dirname "$2")"
  ln -sfn "$1" "$2"
  echo "$2 -> $1"
}

link "$HOME/.aws/config"                          "$LINKS/aws/config"
link "$HOME/.aws/config"                          "$LINKS/aws/config"
link "$HOME/.kube/config"                         "$LINKS/kube/config"
link "$HOME/.claude.json"                         "$LINKS/claude/.claude.json"
link "$HOME/.claude/settings.json"                "$LINKS/claude/settings.json"
link "$HOME/.claude/projects/${CODE_DIR//\//-}/memory" "$LINKS/claude/memory"
link "$HOME/.zshrc"                               "$LINKS/terminal/.zshrc"
link "$VSCODE_USER/mcp.json"                      "$LINKS/vscode/mcp.json"
link "$VSCODE_USER/chatLanguageModels.json"       "$LINKS/vscode/chatLanguageModels.json"
link "$VSCODE_USER/settings.json"                 "$LINKS/vscode/settings.json"
link "$VSCODE_USER/keybindings.json"              "$LINKS/vscode/keybindings.json"
