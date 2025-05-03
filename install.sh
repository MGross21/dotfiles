#!/bin/bash
set -uo pipefail

# Source common utility functions
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Inline banner
cat << "EOF"
 █████╗ ██████╗  ██████╗██╗  ██╗    ██╗      ██╗███╗   ██╗██╗   ██╗██╗  ██╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██║      ██║████╗  ██║██║   ██║╚██╗██╔╝
███████║██████╔╝██║     ███████║    ██║      ██║██╔██╗ ██║██║   ██║ ╚███╔╝ 
██╔══██║██╔══██╗██║     ██╔══██║    ██║      ██║██║╚██╗██║██║   ██║ ██╔██╗ 
██║  ██║██║  ██║╚██████╗██║  ██║    ███████╗ ██║██║ ╚████║╚██████╔╝██╔╝ ██╗
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝
                                                                          
██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗      
██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗     
██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝     
██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗     
██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║     
╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝     
EOF

# Add support for non-interactive mode
NON_INTERACTIVE=false
if [[ "$*" == *--non-interactive* ]]; then
    NON_INTERACTIVE=true
fi

# Section header
section() {
    echo -e "\n${BOLD}${BLUE}=== $1 ===${RESET}"
    echo
}

# Safe exit with error message
safe_exit() {
    local msg=${1:-"Script execution cancelled."}
    error "$msg"
    exit 1
}

# Run a setup script with error handling
run_setup_script() {
    local script="$1"
    local description="$2"
    shift 2
    local args=("$@")

    if [[ ! -f "$script" ]]; then
        error "Setup script not found: $script"
        return 1
    fi

    section "$description"
    info "Running $script..."

    if bash "$script" "${args[@]}"; then
        success "$description completed successfully!"
    else
        error "$description failed!"
        safe_exit "Aborting due to error."
    fi
}

# Check prerequisites
check_prerequisites() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root!"
        exit 1
    fi

    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed to run on Arch Linux."
        exit 1
    fi

    if $NON_INTERACTIVE; then
        info "Running in non-interactive mode. Default values will be used."
    fi
}

# Check Internet Connection
check_internet() {
    run_setup_script "$SCRIPT_DIR/01_check_internet.sh" "Internet Connection Check"
}

# Disk Partitioning
partition_disk() {
    run_setup_script "$SCRIPT_DIR/00_partition.sh" "Disk Partitioning"
}

# System Update
update_system() {
    run_setup_script "$SCRIPT_DIR/03_system_update.sh" "System Update"
}

# Install Base Packages
install_base_packages() {
    section "Installing Base System"
    local BASE_PACKAGES="base base-devel linux linux-firmware linux-headers networkmanager grub efibootmgr sudo os-prober"
    eval "pacstrap /mnt $BASE_PACKAGES"
    eval "genfstab -U /mnt >> /mnt/etc/fstab"
    success "Base system installed successfully!"
}

# Configure System
configure_system() {
    section "System Configuration"
    if $NON_INTERACTIVE; then
        HOST_NAME="archlinux"
    else
        read -rp "Enter hostname [archlinux]: " HOST_NAME
        HOST_NAME=${HOST_NAME:-"archlinux"}
    fi
    eval "echo \"$HOST_NAME\" > /mnt/etc/hostname"
    eval "arch-chroot /mnt locale-gen"
    eval "arch-chroot /mnt passwd"
    success "System configuration completed!"
}

# Install Bootloader
install_bootloader() {
    run_setup_script "$SCRIPT_DIR/05_configure_grub.sh" "Installing Bootloader"
}

# Install Additional Packages
install_additional_packages() {
    section "Installing Additional Packages"
    local PACMAN_CONF="$PACKAGES_DIR/pacman.conf"
    if [[ -f "$PACMAN_CONF" ]]; then
        eval "cp \"$PACMAN_CONF\" /mnt/packages_pacman.conf"
    else
        warning "Package configuration not found. Skipping additional packages."
    fi
}

# Finalize Installation
finalize_installation() {
    section "Finalizing Installation"
    info "Unmounting partitions..."
    eval "umount -R /mnt"
    success "Installation completed!"
}

# Display menu and handle user input
display_menu() {
    if $NON_INTERACTIVE; then
        info "Skipping menu in non-interactive mode. Proceeding with full installation."
        full_installation
        return
    fi

    info "What would you like to do?"
    echo -e "1. Full system installation (from Arch live environment)"
    echo -e "2. Configure an existing Arch installation"
    echo -e "3. Exit"

    while true; do
        read -rp "Enter your choice [1-3]: " choice
        case $choice in
            1) full_installation; break ;;
            2) configure_system; break ;;
            3) info "Exiting installation."; exit 0 ;;
            *) error "Invalid option. Please try again." ;;
        esac
    done
}

# Full system installation
full_installation() {
    info "Starting full system installation..."
    check_internet
    partition_disk
    update_system
    install_base_packages
    configure_system
    install_bootloader
    install_additional_packages
    finalize_installation
}

# Start the script
main() {
    check_prerequisites
    display_menu
}