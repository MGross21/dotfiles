#!/bin/bash

# Common functions for setup scripts

# Text formatting
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

# Print a section header
section() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}"
    echo
}

# Print a success message
success() {
    echo -e "${GREEN}[✓] $1${RESET}"
}

# Print an info message
info() {
    echo -e "${BLUE}[*] $1${RESET}"
}

# Print a warning message
warning() {
    echo -e "${YELLOW}[!] $1${RESET}" >&2
}

# Print an error message
error() {
    echo -e "${RED}[-] $1${RESET}" >&2
}

# Exit safely with an error message
safe_exit() {
    local msg=${1:-"Script execution cancelled."}
    error "$msg"
    exit 1
}

# Confirm an action
confirm_action() {
    local message="$1"
    local default=${2:-"no"}
    
    if [[ "$default" == "yes" ]]; then
        read -rp "$(echo -e "${YELLOW}!!! $message [Y/n]: ${RESET}")" confirm
        confirm=${confirm:-"y"}
    else
        read -rp "$(echo -e "${YELLOW}!!! $message [y/N]: ${RESET}")" confirm
        confirm=${confirm:-"n"}
    fi
    
    if [[ "${confirm,,}" =~ ^(y|yes)$ ]]; then
        return 0
    else
        return 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" &>/dev/null
}