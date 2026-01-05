#!/bin/bash

set -euo pipefail

GITHUB_REPO="MGross21/vscode-tomorrow-night-burns"
BRANCH="fix/brackets-coloring"
EXTENSION_DIR="$HOME/.vscode/extensions"
EXTENSION_NAME="alii.vscode-tomorrow-night-burns-master"
WORK_DIR="$HOME/Documents/github/personal"
REPO_URL="https://github.com/$GITHUB_REPO.git"

# Check if required commands are available
command -v git &>/dev/null || { echo "Error: git not found"; exit 1; }
command -v code &>/dev/null || { echo "Error: code not found"; exit 1; }

# Create and navigate to work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR" || exit 1

# Clone or update repository
if [ -d ".git" ]; then
    git pull
else
    cd .. || exit 1
    git clone --branch "$BRANCH" "$REPO_URL" "$(basename "$WORK_DIR")"
    cd "$WORK_DIR" || exit 1
fi

# Create symlink to VSCode extensions
ln -sf "$WORK_DIR" "$EXTENSION_DIR/$EXTENSION_NAME"
