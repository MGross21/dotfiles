###############
# PERMISSIONS #
###############

groups=(sudo input docker)

for group in "${groups[@]}"; do
    if getent group "$group" > /dev/null; then
        sudo usermod -aG "$group" "$USER" || { echo "Failed to add $USER to $group group"; exit 1; }
    else
        echo "Group $group does not exist, skipping."
    fi
done

#########
# SHELL #
#########

sudo chsh -s "$(command -v zsh)" "$USER" || { echo "Failed to change shell to zsh for $USER"; exit 1; }