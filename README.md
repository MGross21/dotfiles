# Dotfiles & Installation

## System Info

| **Component**   | **Details**                                                           |    **Notes**                |
|------------------|----------------------------------------------------------------------|-----------------------------|
| **Kernel**       | [Linux](https://github.com/torvalds/linux)                           |  Year of the Linux Desktop  |
| **Distribution** | [Arch](https://archlinux.org)                                        | *I use Arch btw*            |
| **Window Manager**| [Hyprland](https://wiki.hyprland.org)                               |    Tiling / Wayland         |
| **Graphics**     | NVIDIA                                                               |                             |
| **GRUB Theme**   | [Elegant-Grub2](https://github.com/vinceliuice/Elegant-grub2-themes) | Mojave, Window, Dark, Right    |
| **Terminal**    | [Alacritty](https://github.com/alacritty/alacritty)                   | Fast, GPU-accelerated       |
| **Shell**       | [Zsh](https://www.zsh.org)                                           | With [Oh My Zsh](https://ohmyz.sh/) |

## Download ISO

[Download Arch Linux ISO](https://archlinux.org/download/)

Use tool like Rufus to flash `.iso` to boot drive

## Installation Script

```bash
git clone --bare https://github.com/MGross21/dotfiles.git ~/.dotfiles
./install.sh
```

### Making Changes

```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
dotfiles checkout
dotfiles config --local status.showUntrackedFiles no
```

#### Examples

```bash
dotfiles status
dotfiles add .vimrc
dotfiles commit -m "Update vim config"
```

### Installing on WSL2

Open Command Prompt (`Win + R`, type `cmd`, press `Enter`):

```bash
wsl --update
wsl --set-default-version 2
wsl --install archlinux
wsl --set-default archlinux
wsl ~
pacman -Syu  # no sudo
```

<!--Need to add a user in the above commands. No $HOME DIR has been created yet-->