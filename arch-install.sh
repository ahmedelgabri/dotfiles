# curl -O <URL>
# bash arch-install.sh

set -e

function log {
  echo "[arch-linux-install] $*"
}

log "Checking network reachability"
ping -c 3 google.com

log "Refreshing packages"
pacman -Syy

log "Partitioning disk"
cat << HERE | sfdisk /dev/sda
label: gpt
device: /dev/sda

/dev/sda1: size=500MiB, type=uefi
/dev/sda2: size=10GiB, type=linux
/dev/sda3: type=linux
HERE

log "Formatting partitions"
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3

log "Mounting /dev/sda2 at /"
mount /dev/sda2 /mnt

log "Mounting /dev/sda3 at /home"
mkdir /mnt/home
mount /dev/sda3 /mnt/home

log "Creating /etc/fstab"
mkdir /mnt/etc
genfstab -U -p /mnt >> /mnt/etc/fstab

log "Installing base packages"
pacstrap /mnt base base-devel

cat << HERE > /mnt/arch-install-chroot.sh
set -e

function log {
  echo "[arch-linux-install] \$*"
}

log "Installing kernel and other packages"
pacman -S --noconfirm linux linux-lts linux-headers linux-lts-headers

log "Installing other packages you want"
pacman -S --noconfirm man-db

log "Preparing ramdisks for kernel boot"
# Note: this might be redundant; pacman already did it?
mkinitcpio -p linux
mkinitcpio -p linux-lts

log "Setting up locale"
sed -i \
  -e 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' \
  -e 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

log "Setting up users"
echo root:pass | chpasswd
useradd -m -g users -G wheel ahmed
echo ahmed:pass | chpasswd
echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel

log "Setting up boot"
pacman -S --noconfirm grub efibootmgr dosfstools os-prober mtools
mkdir -p /boot/EFI
mount /dev/sda1 /boot/EFI
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
cp /usr/share/locale/en\@quot/LC_MESSAGES/grub.mo /boot/grub/locale/en.mo
grub-mkconfig -o /boot/grub/grub.cfg

log "Setting up swap"
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
echo -e '\n/swapfile none swap sw 0 0' >> /etc/fstab

log "Installing other dependencies"
pacman -S --noconfirm git neovim ruby tmux vi vim xorg-server

log "Installing VirtualBox support"
pacman -S --noconfirm virtualbox-guest-utils xf86-video-vmware # just in VirtualBox

log "Installing network support"
pacman -S --noconfirm networkmanager wpa_supplicant wireless_tools netctl
pacman -S --noconfirm dialog # for wifi-menu
systemctl enable NetworkManager

log "Applying other settings"
# echo KEYMAP=colemak >> /etc/vconsole.conf
ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime

exit
HERE

log "Entering chroot environment"
arch-chroot /mnt /bin/bash arch-install-chroot.sh

log "Finished: rebooting"
rm /mnt/arch-install-chroot.sh

# Ignoring errors about unmounting...
set +e
umount -a

reboot
