# Dotfiles & Installation

> [!WARNING] 
> This code is currently a work in progress. Please note that the implementation may not be complete or fully functional. Any feedback, suggestions, or issues encountered would be greatly appreciated. Feel free to contribute by opening an issue on GitHub.

## System Info

| **Component**   | **Details**       |
|------------------|-------------------|
| **Kernel**       | Linux             |
| **Distribution** | [Arch](https://archlinux.org)               |
| **WM**           | [Hyprland](https://wiki.hyprland.org)          |
| **Graphics**     | NVIDIA            |

(*I use Arch btw*)

## Download ISO

[Download Arch Linux ISO](https://archlinux.org/download/)

### Connect to Internet

#### Wired Connection

```bash
ping -c 3 archlinux.org
```

#### Wireless Connection

```bash
iwctl
station wlan0 scan
station wlan0 get-networks
station wlan0 connect SSID
# Enter password when prompted
exit
```

### Update System Clock

```bash
timedatectl set-ntp true
```

### Partition Disks

#### Create Partitions

1. Type `n` and press Enter.
2. Select partition type `primary` and press Enter.
3. Specify the partition number and press Enter.
4. Specify the first sector (default) and press Enter.
5. Specify the last sector or size (e.g., `+512M` for EFI) and press Enter.

#### Change Partition Types

- **EFI Partition:**  
    Type `t`, select the partition number, and type `1` (EFI System).  
- **Swap Partition:**  
    Repeat the steps to create a new partition, specify the size (e.g., `+<size_of_RAM>M`), then type `t`, select the partition number, and type `19` (Linux swap).  
- **Root Partition:**  
    Use the remaining space for the root partition.

#### Write Changes

Type `w` and press Enter to write changes and exit `fdisk`.

### Format Partitions

```bash
mkfs.fat -F32 /dev/sdX1 # Format EFI
mkswap /dev/sdX2        # Format Swap
swapon /dev/sdX2
mkfs.ext4 /dev/sdX3     # Format Root
```

### Mount Partitions

```bash
mount /dev/sdX3 /mnt       # Mount Root
mkdir /mnt/boot
mount /dev/sdX1 /mnt/boot  # Mount EFI
```

### Install Base System

```bash
pacstrap /mnt base linux linux-firmware linux-headers networkmanager grub efibootmgr sudo nano base-devel git
```

## Installing GRUB

### UEFI Installation

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
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

### NVIDIA Drivers

```bash
sudo pacman -S nvidia-dkms nvidia-utils egl-wayland nvidia-settings
```

#### Edit GRUB Configuration

```bash
sudo nano /etc/default/grub
```

Add the following to `GRUB_CMDLINE_LINUX_DEFAULT`:

```ini
nvidia_drm.modeset=1
```

Save and exit, then rebuild GRUB:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### Reboot

```bash
sudo reboot
```

### Configure Hyprland

```bash
mkdir -p ~/.config/hypr
cp /usr/share/hyprland/hyprland.conf ~/.config/hypr/
```

## Additional Setup

### Package Installer

```bash
git clone --separate-git-dir=$HOME/.dotfiles https://github.com/MGross21/dotfiles.git $HOME
./install.sh
```

### Making Changes

```bash
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'
```

#### Examples

```bash
dotfiles status
dotfiles add .vimrc
dotfiles commit -m "Update vim config"
```
