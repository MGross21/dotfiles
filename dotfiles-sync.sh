#!/bin/bash
set -euo pipefail

# Dotfiles Sync Script
# Supports initialization (symlinks) and syncing changes back to repository
# Avoids cp/rsync to prevent duplicates and overwrites

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_LIST="$SCRIPT_DIR/dotfiles.list"
HOME_DIR="${HOME_DIR:-${HOME:-$(eval echo ~$(whoami))}}"

# Color output functions
info()    { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
warning() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error()   { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

# Show usage information
usage() {
    cat << EOF
Usage: $0 [COMMAND]

Commands:
    init     Initialize dotfiles by creating symlinks from repo to home directory
    sync     Sync changes from home directory back to repository
    status   Show status of dotfile symlinks
    help     Show this help message

Examples:
    $0 init    # Create symlinks for all dotfiles
    $0 sync    # Commit and push changes to repository
    $0 status  # Check symlink status
EOF
}

# Check if dotfiles.list exists
check_dotfiles_list() {
    if [[ ! -f "$DOTFILES_LIST" ]]; then
        error "dotfiles.list not found at: $DOTFILES_LIST"
    fi
}

# Expand glob patterns in dotfiles.list
expand_path() {
    local pattern="$1"
    
    # If pattern contains wildcards, expand it
    if [[ "$pattern" == *"*"* ]]; then
        # Use find to expand the pattern
        find "$SCRIPT_DIR" -path "$SCRIPT_DIR/$pattern" -type f 2>/dev/null | \
            sed "s|^$SCRIPT_DIR/||" | \
            grep -v '^\.git/' || true
    else
        # Just return the literal path
        echo "$pattern"
    fi
}

# Initialize dotfiles by creating symlinks
init_dotfiles() {
    info "Initializing dotfiles with symlinks..."
    check_dotfiles_list
    
    local backed_up=false
    
    while IFS= read -r path; do
        # Skip blank lines and comments
        [[ -z "$path" || "$path" == \#* ]] && continue
        
        # Expand glob patterns
        while IFS= read -r expanded_path; do
            [[ -z "$expanded_path" ]] && continue
            
            local src="$SCRIPT_DIR/$expanded_path"
            local dest="$HOME_DIR/$expanded_path"
            
            # Skip if source doesn't exist in repo
            if [[ ! -e "$src" ]]; then
                warning "Source not found in repo: $src"
                continue
            fi
        
            # Handle existing files/directories at destination
            if [[ -e "$dest" || -L "$dest" ]]; then
                if [[ -L "$dest" ]]; then
                    local current_target
                    current_target=$(readlink "$dest")
                    if [[ "$current_target" == "$src" ]]; then
                        info "Symlink already correct: $dest -> $src"
                        continue
                    else
                        info "Updating symlink: $dest"
                        rm "$dest"
                    fi
                else
                    # Backup existing file/directory
                    local backup_dir="$HOME_DIR/.dotfiles-backup"
                    if ! $backed_up; then
                        info "Creating backup directory: $backup_dir"
                        mkdir -p "$backup_dir"
                        backed_up=true
                    fi
                    
                    local backup_path="$backup_dir/$expanded_path.$(date +%Y%m%d_%H%M%S)"
                    info "Backing up existing file: $dest -> $backup_path"
                    mkdir -p "$(dirname "$backup_path")"
                    mv "$dest" "$backup_path"
                fi
            fi
            
            # Create destination directory if needed
            mkdir -p "$(dirname "$dest")"
            
            # Create symlink
            info "Creating symlink: $dest -> $src"
            ln -s "$src" "$dest"
            
        done < <(expand_path "$path")
        
    done < "$DOTFILES_LIST"
    
    if $backed_up; then
        info "Original files backed up to: $HOME_DIR/.dotfiles-backup"
    fi
    
    success "Dotfiles initialization complete!"
}

# Sync changes from home directory back to repository
sync_dotfiles() {
    info "Syncing dotfiles changes to repository..."
    check_dotfiles_list
    
    # Ensure we're in the repo directory
    cd "$SCRIPT_DIR" || error "Failed to change to script directory"
    
    # Pull latest changes first
    info "Pulling latest changes from repository..."
    git pull --rebase origin main || warning "Failed to pull latest changes"
    
    local changes_found=false
    
    while IFS= read -r path; do
        # Skip blank lines and comments
        [[ -z "$path" || "$path" == \#* ]] && continue
        
        # Expand glob patterns
        while IFS= read -r expanded_path; do
            [[ -z "$expanded_path" ]] && continue
            
            local src="$HOME_DIR/$expanded_path"
            local dest="$SCRIPT_DIR/$expanded_path"
            
            # Skip if source doesn't exist in home
            if [[ ! -e "$src" ]]; then
                warning "Source not found in home: $src"
                continue
            fi
            
            # Skip if it's a symlink pointing to our repo (no need to sync back)
            if [[ -L "$src" ]]; then
                local target
                target=$(readlink "$src")
                if [[ "$target" == "$dest" ]]; then
                    continue # This is our symlink, no need to sync
                fi
            fi
            
            # Check if files are different
            if [[ -e "$dest" ]]; then
                if cmp -s "$src" "$dest" 2>/dev/null; then
                    continue # Files are identical
                fi
            fi
            
            info "Syncing: $src -> $dest"
            changes_found=true
            
            # Create destination directory if needed
            mkdir -p "$(dirname "$dest")"
            
            # Copy file or directory (only for sync, not init)
            if [[ -d "$src" ]]; then
                rsync -av --delete "$src/" "$dest/"
            else
                cp "$src" "$dest"
            fi
            
        done < <(expand_path "$path")
        
    done < "$DOTFILES_LIST"
    
    if ! $changes_found; then
        info "No changes found to sync"
        return 0
    fi
    
    # Show git status
    info "Git status:"
    git status --short
    
    # Commit and push changes
    if git diff --quiet && git diff --cached --quiet; then
        info "No changes to commit"
    else
        local commit_msg="Sync dotfiles ($(date +'%m/%d/%y %H:%M:%S %Z'))"
        info "Committing changes: $commit_msg"
        git add .
        git commit -m "$commit_msg"
        
        info "Pushing changes to repository..."
        git push origin main || warning "Failed to push changes"
        
        success "Changes synced and pushed to repository!"
    fi
}

# Show status of dotfile symlinks
show_status() {
    info "Checking dotfile symlink status..."
    check_dotfiles_list
    
    while IFS= read -r path; do
        # Skip blank lines and comments
        [[ -z "$path" || "$path" == \#* ]] && continue
        
        # Expand glob patterns
        while IFS= read -r expanded_path; do
            [[ -z "$expanded_path" ]] && continue
            
            local src="$SCRIPT_DIR/$expanded_path"
            local dest="$HOME_DIR/$expanded_path"
            
            printf "%-40s" "$expanded_path"
            
            if [[ ! -e "$src" ]]; then
                echo -e "\033[1;31m[MISSING IN REPO]\033[0m"
            elif [[ ! -e "$dest" && ! -L "$dest" ]]; then
                echo -e "\033[1;33m[NOT LINKED]\033[0m"
            elif [[ -L "$dest" ]]; then
                local target
                target=$(readlink "$dest")
                if [[ "$target" == "$src" ]]; then
                    echo -e "\033[1;32m[OK]\033[0m"
                else
                    echo -e "\033[1;33m[WRONG TARGET: $target]\033[0m"
                fi
            else
                echo -e "\033[1;31m[FILE EXISTS]\033[0m"
            fi
            
        done < <(expand_path "$path")
        
    done < "$DOTFILES_LIST"
}

# Main command handling
case "${1:-help}" in
    init)
        init_dotfiles
        ;;
    sync)
        sync_dotfiles
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        error "Unknown command: $1\nUse '$0 help' for usage information"
        ;;
esac