# Installation Instructions

**Kernel:** Arch Linux\
**DE:** Hyprland\
**Graphics Card:** NVIDIA RTX

## Installation

### Download ISO
[See Here](https://archlinux.org/download/)

### Connect to Internet

```bash
# For wired connection (already connected)
ping -c 3 archlinux.org

# For wireless connection
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

#### Create a New Partition
- Type `n` and press Enter.
- Select partition type `primary` and press Enter.
- Specify the partition number and press Enter.
- Specify the first sector (default) and press Enter.
- Specify the last sector or size (e.g., `+512M` for EFI) and press Enter.

#### Change the Partition Type to EFI
- Type `t` and press Enter.
- Select the partition number and press Enter.
- Type `1` (EFI System) and press Enter.

#### Create a Swap Partition
- Repeat the steps to create a new partition.
- Specify the size (e.g., `+<size_of_RAM>M`).

#### Change the Partition Type to Swap
- Type `t` and press Enter.
- Select the partition number and press Enter.
- Type `19` (Linux swap) and press Enter.

#### Create a Root Partition
- Repeat the steps to create a new partition.
- Use the remaining space for the root partition.

#### Write the Changes
- Type `w` and press Enter to write the changes and exit `fdisk`.

### Format Partitions

```bash
mkfs.fat -F32 /dev/sda1 # Format EFI
mkswap /dev/sda2 # Format Swap
swapon /dev/sda2
mkfs.ext4 /dev/sda3 # Format Root
```

### Mount Partitions

```bash
mount /dev/sda3 /mnt # Mount Root
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot # Mount Linux
```

### Install Base

```bash
pacstrap /mnt base linux linux-firmware linux-headers networkmanager grub efibootmgr sudo base-devel
```

```bash
pacman -S hyprland wayland wlroots xorg-xwayland \
swaybg swaylock swayidle grim slurp mako \
alacritty thunar thunar-archive-plugin thunar-volman \
base-devel git vim wget curl htop neofetch firefox \
pipewire pipewire-alsa pipewire-pulse wireplumber
```

## Installing GRUB

*For UEFI*

```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
```

### Custom GRUB Theme

Installs Mojave Dark Theme and auto-regenerates the config

```bash
git clone https://github.com/vinceliuice/Elegant-grub2-themes
cd Elegant-grub2-themes
sudo ./install.sh -b -t mojave -i right
# cd ..
# rm Elegant-grub2-themes
```

## Installing Hyprland

Following [this tutorial](https://wiki.hyprland.org/Getting-Started/Master-Tutorial/)

```bash
sudo pacman -Syu \
wayland xorg-xwayland xdg-desktop-portal-wlr pipewire wireplumber wl-clipboard wlroots
```

### Critical Invidia Drivers

```bash
sudo pacman -S nvidia-dkms nvidia-utils egl-wayland nvidia-settings
```

#### Edit GRUB

```bash
sudo nano /etc/default/grub
```

Find the `GRUB_CMDLINE_LINUX_DEFAULT` line and add:

```ini
nvidia_drm.modeset=1
```

Save and exit, then rebuild grub:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

*Note: Strangely Windows Drive was finally detected here*

```bash
sudo reboot
```

<!-- ### Install `yay`

```bash
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

```bash
yay -S hyprland
``` -->

### Move Default Hyprland Config to User Config

```bash
mkdir -p ~/.config/hypr
cp /usr/share/hyprland/hyprland.conf ~/.config/hypr/
```

### Install Basic Apps

```bash
sudo pacman -S \
kitty \   # Terminal
waybar \  # Top Bar
rofi     # App Launcher
```

### Install Hypr* Packages

```bash
sudo pacman -S hyprland hyprpaper
```

### Screenshot tools

```bash
sudo pacman -S \
grim \    # Wayland screenshot tool
slurp \   # Area selector for screenshots
swappy    # GUI to edit/annotate screenshots
```

### Brightness and Volume Control

```bash
sudo pacman -S \
brightnessctl \   # control monitor brightness
pamixer \         # audio volume from terminal
playerctl         # control media players (Spotify, etc)
```

### Fonts

```bash
sudo pacman -S ttf-jetbrains-mono ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-common
```

### GTK Tools (for theming apps)

```bash
sudo pacman -S nwg-look
```