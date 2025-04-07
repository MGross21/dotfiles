# Installation Instructions

**Kernel:** Arch Linux\
**DE:** COSMIC\
**Internet:** Ethernet\
**Graphics Card:** NVIDIA RTX

### Installation

1. Download ISO
[See Here](https://archlinux.org/download/)

2. Connect to internet

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

3. Update system Clock

```bash
timedatectl set-ntp true
```

1. Partition Disks

- Create a new partition:
  - Type `n` and press Enter.
  - Select partition type `primary` and press Enter.
  - Specify the partition number and press Enter.
  - Specify the first sector (default) and press Enter.
  - Specify the last sector or size (e.g., `+512M` for EFI) and press Enter.

- Change the partition type to EFI:
  - Type `t` and press Enter.
  - Select the partition number and press Enter.
  - Type `1` (EFI System) and press Enter.

- Create a swap partition:
  - Repeat the steps to create a new partition.
  - Specify the size (e.g., `+<size_of_RAM>M`).

- Change the partition type to swap:
  - Type `t` and press Enter.
  - Select the partition number and press Enter.
  - Type `19` (Linux swap) and press Enter.

- Create a root partition:
  - Repeat the steps to create a new partition.
  - Use the remaining space for the root partition.

- Write the changes:
  - Type `w` and press Enter to write the changes and exit `fdisk`.

5. Format Partitions

```bash
mkfs.fat -F32 /dev/sda1 # Format EFI
mkswap /dev/sda2 # Format Swap
swapon /dev/sda2
mkfs.ext4 /dev/sda3 # Format Root
```

1. Mount Partitions

```bash
mount /dev/sda3 /mnt # Mount Root
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot # Mount Linux
```

7. Install Base

```bash
pacstrap /mnt base linux linux-firmware networkmanager grub efibootmgr sudo base-devel
```

```bash
pacman -S cosmic-session cosmic-panel cosmic-launcher cosmic-settings cosmic-bg cosmic-icon-theme \
gdm base-devel git vim wget curl htop neofetch firefox pulseaudio pulseaudio-alsa
```
