# Installation Instructions

**Kernel:** Linux  
**Distribution:** Arch  
**DE:** Hyprland  
**Graphics Card:** NVIDIA RTX  

## Installation

### Download ISO

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
pacstrap /mnt base linux linux-firmware linux-headers networkmanager grub efibootmgr sudo base-devel
```

### Install Additional Packages

```bash
pacman -S hyprland wayland wlroots xorg-xwayland \
swaybg swaylock swayidle grim slurp mako \
alacritty thunar thunar-archive-plugin thunar-volman \
base-devel git vim wget curl htop neofetch firefox \
pipewire pipewire-alsa pipewire-pulse wireplumber
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

## Installing Hyprland

Follow the [Hyprland Master Tutorial](https://wiki.hyprland.org/Getting-Started/Master-Tutorial/).

### Install Required Packages

```bash
sudo pacman -Syu \
wayland xorg-xwayland xdg-desktop-portal-wlr pipewire wireplumber wl-clipboard wlroots
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

### Install Basic Apps

```bash
sudo pacman -S \
kitty \   # Terminal
waybar \  # Top Bar
rofi      # App Launcher
```

### Install Hyprland Packages

```bash
sudo pacman -S hyprland hyprpaper
```

### Screenshot Tools

```bash
sudo pacman -S \
grim \    # Wayland screenshot tool
slurp \   # Area selector for screenshots
swappy    # GUI to edit/annotate screenshots
```

### Brightness and Volume Control

```bash
sudo pacman -S \
brightnessctl \   # Control monitor brightness
pamixer \         # Audio volume from terminal
playerctl         # Control media players (Spotify, etc.)
```

### Fonts

```bash
sudo pacman -S ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common
```

### GTK Tools (for Theming)

```bash
sudo pacman -S nwg-look
```
