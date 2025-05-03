#!/bin/bash
set -euo pipefail

# Source common library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source common library if available
COMMON_LIB="$SCRIPT_DIR/lib/common.sh"
[[ -f "$COMMON_LIB" ]] && source "$COMMON_LIB"

# Process arguments
CONFIG_FILE="${1:-}"

# Default config files to look for if not specified
declare -A CONFIG_FILES=(
    ["pacman.conf"]="pacman"
    ["yay.conf"]="yay"
    ["external.sh"]="external"
)

# Non-interactive mode flag
NON_INTERACTIVE=false
[[ "$*" == *--non-interactive* ]] && NON_INTERACTIVE=true

# Function to install packages from a group
install_packages() {
    local -n packages=$1
    local installer=$2

    if [[ ${#packages[@]} -eq 0 ]]; then
        warning "No packages to install for group: $1"
        return
    fi

    info "Installing packages for group: $1..."
    printf " - %s\n" "${packages[@]}"
    echo

    if ! $NON_INTERACTIVE && ! confirm_action "Install these packages?" "yes"; then
        info "Skipping installation of $1 packages."
        return
    fi

    case "$installer" in
        pacman)
            execute "pacman -S --needed --noconfirm ${packages[*]}" "Installing packages with pacman..."
            ;;
        yay)
            if command_exists yay; then
                execute "yay -S --needed --noconfirm ${packages[*]}" "Installing packages with yay..."
            else
                warning "yay is not installed. Falling back to pacman."
                execute "pacman -S --needed --noconfirm ${packages[*]}" "Installing packages with pacman..."
            fi
            ;;
        external)
            [[ -n "$CONFIG_FILE" ]] && execute "curl -fsSL $CONFIG_FILE | bash" "Running external script from $CONFIG_FILE..." || warning "No external script URL provided. Skipping."
            ;;
        *)
            warning "Unknown installer: $installer. Falling back to pacman."
            execute "pacman -S --needed --noconfirm ${packages[*]}" "Installing packages with pacman..."
            ;;
    esac
}

# Function to process a config file
process_config_file() {
    local config_file=$1
    local installer=$2

    info "Sourcing $config_file..."
    source <(grep -v '^#' "$config_file")

    local package_groups=($(compgen -A variable | grep -E '^[A-Z_]+$'))

    if $NON_INTERACTIVE; then
        info "Running in non-interactive mode. Installing all package groups by default."
        for group in "${package_groups[@]}"; do
            declare -p "$group" &>/dev/null && install_packages "$group" "$installer"
        done
        return
    fi

    if [[ ${#package_groups[@]} -gt 0 ]]; then
        echo
        info "Available package groups in $config_file:"
        for i in "${!package_groups[@]}"; do
            echo "  $((i+1)). ${package_groups[$i]}"
        done
        echo "  $((${#package_groups[@]}+1)). All groups"
        echo "  $((${#package_groups[@]}+2)). Skip this config file"

        read -rp "Enter your choice [1-$((${#package_groups[@]}+2))]: " choice
        case "$choice" in
            $(( ${#package_groups[@]}+1 )))
                for group in "${package_groups[@]}"; do
                    declare -p "$group" &>/dev/null && install_packages "$group" "$installer"
                done
                ;;
            $(( ${#package_groups[@]}+2 )))
                info "Skipping $config_file"
                ;;
            [1-$((${#package_groups[@]}))])
                local group="${package_groups[$((choice-1))]}"
                install_packages "$group" "$installer"
                ;;
            *)
                warning "Invalid choice. Skipping $config_file"
                ;;
        esac
    else
        warning "No package groups found in $config_file"
    fi
}

# Handle specific config file if provided
if [[ -n "$CONFIG_FILE" ]]; then
    [[ ! -f "$CONFIG_FILE" ]] && error "Config file not found: $CONFIG_FILE" && exit 1

    info "Sourcing config file: $CONFIG_FILE..."
    source <(grep -v '^#' "$CONFIG_FILE")

    local installer="pacman"
    for key in "${!CONFIG_FILES[@]}"; do
        [[ "$CONFIG_FILE" == *"$key" ]] && installer="${CONFIG_FILES[$key]}" && break
    done

    local package_groups=($(compgen -A variable | grep -E '^[A-Z_]+$'))
    for group in "${package_groups[@]}"; do
        declare -p "$group" &>/dev/null && install_packages "$group" "$installer"
    done
    exit 0
fi

# Handle multiple config files if no specific one was provided
for config_file in "${!CONFIG_FILES[@]}"; do
    info "Looking for $config_file..."
    [[ ! -f "$config_file" ]] && warning "$config_file not found. Skipping." && continue
    process_config_file "$config_file" "${CONFIG_FILES[$config_file]}"
done

success "Package installation complete!"
