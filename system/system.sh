###############
# PERMISSIONS #
###############

sudo usermod -aG sudo $USER
sudo usermod -aG input $USER

#########
# SHELL #
#########

chsh -s $(which zsh) $USER # Change default shell to zsh

#############
# LANGUAGES #
#############

rustup install stable # Pull Stable Rust Version