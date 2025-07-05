# Dotfiles & Installation

![Desktop Preview](Pictures/screenshots/monochrome1.png)

## System Info

| **Component**   | **Details**                                                           |    **Notes**                |
|------------------|----------------------------------------------------------------------|-----------------------------|
| **Kernel**       | [Linux](https://github.com/torvalds/linux)                           |  Year of the Linux Desktop  |
| **Distribution** | [Arch](https://archlinux.org)                                        |       *Arch btw*            |
| **Window Manager**| [Hyprland](https://wiki.hyprland.org)                               |    Tiling / Wayland         |
| **Graphics**     | NVIDIA                                                               |     Open Drivers            |
| **GRUB Theme**   | [Elegant-Grub2](https://github.com/vinceliuice/Elegant-grub2-themes) | Mojave, Window, Dark, Right |
| **Terminal**    | [Alacritty](https://github.com/alacritty/alacritty)                   | Fast, GPU-accelerated       |
| **Shell**       | [Zsh](https://www.zsh.org)                                            | With [Oh My Zsh](https://ohmyz.sh/) |
| **Font**        | [Ubuntu](https://design.ubuntu.com/font/)                             |                             |
| **System Theme**| [Materia Dark](https://github.com/nana-4/materia-theme)               | Based on Adwaita            |
| **Icon Theme** | [Tela Circle](https://github.com/vinceliuice/Tela-circle-icon-theme) | Black, Dark |

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

### Arch on WSL2

To set up Arch Linux on WSL2:

1. Open Command Prompt (`Win + R`, type `cmd`, press `Enter`).
2. Run the following commands:

```bash
wsl --update
wsl --set-default-version 2
wsl --install archlinux
wsl --set-default archlinux
wsl ~
pacman -Syu
```

### User Setup

Create a new user and grant sudo privileges:

1. Add a user:

```bash
useradd -m -G wheel -s /bin/bash <username>
passwd <username>
```

2. Edit the sudoers file:

```bash
EDITOR=nano visudo
```

Uncomment:

```plaintext
%wheel ALL=(ALL) ALL
```

3. Switch to the new user:

```bash
su - <username>
```

### Custom GRUB Theme

<img src="https://raw.githubusercontent.com/vinceliuice/Elegant-grub2-themes/refs/heads/main/preview-02.jpg"
     width="840" height="500"
     style="object-fit: none; object-position: -1020px -1100px;">

```bash
git clone https://github.com/vinceliuice/Elegant-grub2-themes
cd Elegant-grub2-themes
sudo ./install.sh -b -t mojave -i right
```
