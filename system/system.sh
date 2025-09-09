###############
# PERMISSIONS #
###############

groups=(sudo input docker)

for group in "${groups[@]}"; do
    sudo usermod -aG "$group" "$USER" || { echo "Failed to add $USER to $group group"; exit 1; }
done

#########
# SHELL #
#########

sudo chsh -s "$(command -v zsh)" "$USER" || { echo "Failed to change shell to zsh for $USER"; exit 1; }