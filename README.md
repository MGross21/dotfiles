# Dotfiles & Installation

> [!WARNING]
> This code is currently a work in progress. Please note that the implementation may not be complete or fully functional. Any feedback, suggestions, or issues encountered would be greatly appreciated. Feel free to contribute by opening an issue on GitHub.

## System Info

| **Component**   | **Details**                                                           |    **Notes**                |
|------------------|----------------------------------------------------------------------|-----------------------------|
| **Kernel**       | Linux                                                                |                             |
| **Distribution** | [Arch](https://archlinux.org)                                        | *I use Arch btw*            |
| **Window Manager**| [Hyprland](https://wiki.hyprland.org)                               |    Tiling / Wayland         |
| **Graphics**     | NVIDIA                                                               |                             |
| **GRUB Theme**   | [Elegant-Grub2](https://github.com/vinceliuice/Elegant-grub2-themes) | Mojave Window Dark Right    |
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
