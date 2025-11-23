#!/bin/bash
# Custom Arch Linux ISO Builder
# This script creates a custom Arch Linux installation ISO with pre-configured settings

set -e

echo "=== Custom Arch Linux ISO Builder ==="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Check if archiso is installed
if ! command -v mkarchiso &> /dev/null; then
    echo "Installing archiso..."
    pacman -S --noconfirm archiso
fi

# Set up build directories (using HOME instead of /tmp to avoid space issues)
BUILD_DIR="$HOME/archiso-build/custom-archiso"
PROFILE_DIR="$BUILD_DIR/profile"
WORK_DIR="$HOME/archiso-build/work"
OUT_DIR="$HOME/iso-output"

echo "Cleaning previous build..."
rm -rf "$BUILD_DIR" "$WORK_DIR"
mkdir -p "$OUT_DIR"
mkdir -p "$BUILD_DIR"

echo "Creating custom profile..."
cp -r /usr/share/archiso/configs/releng "$PROFILE_DIR"

# Customize packages list
cat >> "$PROFILE_DIR/packages.x86_64" << 'EOF'

# Desktop Environment (optional - uncomment if needed)
# xorg
# plasma-meta
# sddm

# Input Method
fcitx5
fcitx5-chinese-addons
fcitx5-configtool
fcitx5-gtk
fcitx5-qt
fcitx5-rime

# Web Browser
# Note: Google Chrome needs to be installed from AUR or .deb package
firefox

# Development Tools
git
base-devel
vim
neovim

# System Utilities
wget
curl
htop
tmux

# Fonts
noto-fonts
noto-fonts-cjk
noto-fonts-emoji
ttf-dejavu
EOF

# Create airootfs directory structure
AIROOTFS="$PROFILE_DIR/airootfs"
mkdir -p "$AIROOTFS/root"
mkdir -p "$AIROOTFS/etc/skel/.config"

# Copy setup scripts
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
echo "Adding custom configuration scripts..."
if [ -f "$SCRIPT_DIR/setup-terminal.sh" ]; then
    cp "$SCRIPT_DIR/setup-terminal.sh" "$AIROOTFS/root/"
    echo "✓ Copied setup-terminal.sh"
else
    echo "⚠ Warning: setup-terminal.sh not found"
fi

# Create auto-setup script that runs after installation
cat > "$AIROOTFS/root/post-install.sh" << 'POSTINSTALL'
#!/bin/bash
# Post-installation setup script
# Run this after installing Arch Linux

echo "=== Post-Installation Setup ==="

# Setup fcitx5
if [ -f /root/setup-terminal.sh ]; then
    echo "Running fcitx5 setup..."
    bash /root/setup-terminal.sh
else
    echo "Warning: setup-terminal.sh not found"
fi

# Enable and start services if desktop is installed
if command -v sddm &> /dev/null; then
    echo "Enabling display manager..."
    systemctl enable sddm
fi

echo ""
echo "Setup complete! Please reboot."
POSTINSTALL

chmod +x "$AIROOTFS/root/post-install.sh"

# Create README for users
cat > "$AIROOTFS/root/README.txt" << 'README'
=== Custom Arch Linux Installation ISO ===

This ISO includes pre-configured settings for:
- fcitx5 Chinese input method
- Chrome browser configuration (X11 mode for input method support)
- Essential development tools
- Chinese fonts

After Installation:
1. Boot into your new system
2. Run: sudo bash /root/post-install.sh
3. Log out and log back in
4. Press Ctrl+Space to toggle Chinese input

Configuration Files:
- /root/setup-terminal.sh - Input method setup
- /root/post-install.sh - Post-installation script

For Chrome to work with fcitx5:
- Chrome flags are automatically configured for X11 mode
- Restart Chrome after first login

Enjoy your customized Arch Linux!
README

# Create a custom installation guide
cat > "$AIROOTFS/root/INSTALL-GUIDE.txt" << 'GUIDE'
=== Arch Linux Installation Guide ===

Basic Installation Steps:

1. Boot from this ISO

2. Connect to internet:
   - WiFi: iwctl
     > station wlan0 scan
     > station wlan0 get-networks
     > station wlan0 connect SSID
   - Ethernet: dhcpcd (usually automatic)

3. Partition disk:
   cfdisk /dev/sdX
   Example layout:
   - /dev/sda1: 512M (EFI System)
   - /dev/sda2: 4G (Linux swap)
   - /dev/sda3: Rest (Linux filesystem)

4. Format partitions:
   mkfs.fat -F32 /dev/sda1
   mkswap /dev/sda2
   mkfs.ext4 /dev/sda3

5. Mount:
   mount /dev/sda3 /mnt
   mkdir -p /mnt/boot/efi
   mount /dev/sda1 /mnt/boot/efi
   swapon /dev/sda2

6. Install base system:
   pacstrap /mnt base linux linux-firmware

7. Generate fstab:
   genfstab -U /mnt >> /mnt/etc/fstab

8. Chroot:
   arch-chroot /mnt

9. In chroot, configure system:
   # Set timezone
   ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
   hwclock --systohc
   
   # Set locale
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" > /etc/locale.conf
   
   # Set hostname
   echo "myhostname" > /etc/hostname
   
   # Set hosts
   cat >> /etc/hosts << HOSTS
127.0.0.1 localhost
::1       localhost
127.0.1.1 myhostname.localdomain myhostname
HOSTS
   
   # Set root password
   passwd
   
   # Install bootloader
   pacman -S grub efibootmgr
   grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
   grub-mkconfig -o /boot/grub/grub.cfg
   
   # Create user
   useradd -m -G wheel -s /bin/bash username
   passwd username
   
   # Enable sudo
   pacman -S sudo
   echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

10. Exit and reboot:
    exit
    umount -R /mnt
    reboot

After reboot:
- Login as your user
- Run: sudo bash /root/post-install.sh
- Follow the prompts for Chinese input setup
GUIDE

# Customize profiledef.sh
cat > "$PROFILE_DIR/profiledef.sh" << 'PROFILEDEF'
#!/usr/bin/env bash
iso_name="customarch"
iso_label="CUSTOM_ARCH_$(date +%Y%m)"
iso_publisher="Custom Arch Linux <https://archlinux.org>"
iso_application="Custom Arch Linux Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/root"]="0:0:750"
  ["/root/post-install.sh"]="0:0:755"
  ["/root/setup-terminal.sh"]="0:0:755"
)
PROFILEDEF

echo ""
echo "Building ISO..."
echo "This may take 10-30 minutes depending on your system..."
echo ""

# Build the ISO
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

echo ""
echo "=== Build Complete ==="
echo ""
echo "ISO Location: $OUT_DIR"
ls -lh "$OUT_DIR"/*.iso 2>/dev/null || echo "ISO file not found - check for errors above"
echo ""
echo "You can now:"
echo "1. Write to USB: sudo dd if=$OUT_DIR/customarch-*.iso of=/dev/sdX bs=4M status=progress oflag=sync"
echo "2. Or use tools like Rufus, Etcher, or Ventoy"
echo ""
echo "Cleaning up work directory..."
rm -rf "$WORK_DIR"
echo "Done!"
