# arch-xps15-9570
BTRFS-systemd-boot-UEFI
# Installation on Dell XPS 9570

## Boot from the usb (UEFI) (more comfortable with Antergos-Live-Image)
# F12 to enter boot menu


# Connect to Internet
wifi-menu

# Sync clock
timedatectl set-ntp true

# Create three partitions:
# 1 512MB EFI partition # Hex code ef00
# 2 rest Linux partiton  # Hex code 8300

cgdisk /dev/nvme0n1

# Format EFI partition
mkfs.vfat -F 32 -n BOOT /dev/nvme0n1p1



# Format BTRFS filesystem
mkfs.btrfs -L ARCH /dev/nvme**

# Mount BTRFS
mount /dev/mapper/root /mnt
cd /mnt

# Create BTRFS subvolumes + mount directories
btrfs subvolume create @

mkdir -p @/home
btrfs subvolume create @home

mkdir -p @/.snapshots
btrfs subvolume create @snapshots

mkdir -p @/tmp
btrfs subvolume create @tmp



mkdir -p @/var
btrfs subvolume create @var

mkdir -p @var/tmp
btrfs subvolume create @var-tmp

mkdir -p @var/cache/pacman/pkg
btrfs subvolume create @var-pkg


umount /mnt

# Mount BTRFS subvolumes
mount -o subvol=@,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt
mount -o subvol=@home,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt/home
mount -o subvol=@snapshots,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt/.snapshots
mount -o subvol=@tmp,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt/tmp
mount -o subvol=@var,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt/var
mount -o subvol=@var-tmp,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt/var/tmp
mount -o subvol=@var-cache-pacman-pkg,compress=lzo,space_cache,noatime,ssd /dev/mapper/root /mnt/var/cache/pacman/pkg

# Mount EFI partition
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot


# Install the base system plus a few packages
pacstrap /mnt base base-devel btrfs-progs fish vim git   wpa_supplicant dialog iw

genfstab -Up /mnt >>/mnt/etc/fstab

# Verify and adjust /mnt/etc/fstab
# Change relatime on all non-boot partitions to noatime (reduces wear if using an SSD)

arch-chroot /mnt

# Sprache festlegen
echo LANG=en_US.UTF-8 > /etc/locale.conf


# Setup time
ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# Generate required locales
locale-gen

# Set locale
echo 'LANG=en_US.UTF-8' > /etc/locale.conf

# set hostname
echo Xcloud >/etc/hostname

# Set password for root
passwd

# Add real group / user

useradd -m -g '<username>' -G wheel,input -s /usr/bin/fish '<username>'
passwd '<username>'
echo '<username> ALL=(ALL) ALL' > /etc/sudoers.d/<username>

# Configure mkinitcpio with modules needed for the initrd image
vi /etc/mkinitcpio.conf
# remove HOOK "fsck", add "keymap encrypt" before "filesystems": 
# HOOKS="base udev autodetect modconf block btrfs keymap encrypt filesystems keyboard"

# Regenerate initrd image
mkinitcpio -p linux

# Setup systemd-boot
bootctl --path=/boot install

# Enable Intel microcode updates
pacman -S intel-ucode

# Create bootloader entry

# Get root UUID with `blkid /dev/nvme0n1p2'
# Get cryptdevice UUID with `blkid /dev/nvme0n1p2'
---
/boot/loader/entries/arch.conf
---
title          Arc
linux          /vmlinuz-linux
initrd		/intel-ucode.img
initrd         /initramfs-linux.img
options root=PARTUUID=<root-UUID> rw rootflags=subvol=@ 
---

# Set default bootloader entry
---
/boot/loader/loader.conf
---
default		arch
timeout   0
editor    0




pacman -S bash-completion

vi /etc/modprobe.d/modprobe.conf
# content

pacman -S xorg-server xorg-xinit
pacman -S xf86-video-intel alsa-utils chromium  openssh

# exit arch-chroot
exit


# unmount all filesystems
umount -R /mnt
reboot
