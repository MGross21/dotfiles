###############
# PERMISSIONS #
###############

sudo usermod -aG sudo $USER
sudo usermod -aG input $USER

#########
# SHELL #
#########

sudo chsh -s $(which zsh) $USER # Change default shell to zsh

#############
# LANGUAGES #
#############

rustup install stable # Pull Stable Rust Version