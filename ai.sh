echo Freeing System
umount /dev/vda1
sleep 2
umount /dev/vda3
sleep 2
umount /dev/vda3
sleep 2
umount /dev/vda4
sleep 2
swapoff /dev/vda2
sleep 2

echo Setting vi
ln -s /usr/bin/vim /usr/bin/vi

echo Mirrors
reflector -c NL > /etc/pacman.d/mirrorlist
pacman -Syy

echo Partitioning disk
sgdisk --zap-all /dev/vda
sleep 2
sfdisk --delete /dev/vda
sleep 2

cat << EOF > vda.layout
label: gpt
label-id: 3C2B0ABF-A1BC-4AE1-824E-C884F1D0B890
device: /dev/vda
unit: sectors
first-lba: 34
last-lba: 41943006
sector-size: 512

/dev/vda1 : start=        2048, size=      512000, type=U, 
/dev/vda2 : start=      514048, size=     4194304, type=S,
/dev/vda3 : start=     4708352, size=    27262976, type=L,
/dev/vda4 : start=    31971328, size=     9971679, type=H,
EOF

sfdisk /dev/vda < vda.layout
fdisk -l

echo Swap
mkswap /dev/vda2
swapon /dev/vda2

echo Formatting disks
mkfs.fat -F -F 32 /dev/vda1
mkfs.ext4 -F -F /dev/vda3
mkfs.ext4 -F -F /dev/vda4

echo Mounting
mount /dev/vda3 /mnt
mkdir /mnt/boot
mkdir /mnt/home
mount /dev/vda1 /mnt/boot
sleep 2
mount /dev/vda4 /mnt/home


echo Pacstrap
pacstrap /mnt base base-devel linux linux-firmware vim grub efibootmgr os-prober openssh dhclient networkmanager

echo FSTAB
genfstab -U /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab

echo CHROOT
arch-chroot /mnt /bin/bash <<EOF
echo LOCALE and stuff
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
export LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
ln -s /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
echo Arch-VM > /etc/hostname
sed -i "/localhost/s/$/ Arch-VM" /etc/hosts
mkinitcpio -p linux
echo "root:qazwsx12" | chpasswd

echo Installing Bootloader
pacman --noconfirm -S grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB-EFI
grub-mkconfig -o /boot/grub/grub.cfg

echo INSTALLING Window Manager i3 offcourse
pacman -Syy
pacman -S xorg xorg-server xorg-apps xorg-xinit i3-gaps i3status i3blocks dmenu rofi termite --noconfirm --needed
pacman -S lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings --noconfirm --needed
pacman -S noto-fonts ttf-ubuntu-font-family ttf-dejavu ttf-freefont terminus-font ttf-font-awesome --noconfirm --needed  
pacman -S alsa-utils alsa-plugins alsa-lib pavucontrol --noconfirm --needed

systemctl enable --now NetworkManager
systemctl enable --now lightdm

EOF
