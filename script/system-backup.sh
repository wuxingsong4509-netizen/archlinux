#!/bin/bash
# Arch Linux System Backup Script
# Creates a complete system backup excluding unnecessary directories

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Arch Linux System Backup ===${NC}"
echo ""

# Default backup location
BACKUP_DIR="${1:-/tmp/system-backup}"
BACKUP_FILE="archlinux-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Backup location:${NC} $BACKUP_PATH"
echo -e "${YELLOW}Estimated size:${NC} $(du -sh --exclude=/proc --exclude=/sys --exclude=/dev --exclude=/tmp --exclude=/run / 2>/dev/null | cut -f1)"
echo ""

# Confirm
read -p "Continue with backup? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Backup cancelled."
    exit 1
fi

echo ""
echo -e "${GREEN}Starting backup...${NC}"
echo "This may take a while depending on system size..."
echo ""

# List of excluded directories
EXCLUDE_DIRS=(
    "/dev/*"
    "/proc/*"
    "/sys/*"
    "/tmp/*"
    "/run/*"
    "/mnt/*"
    "/media/*"
    "/lost+found"
    "/var/cache/pacman/pkg/*"
    "/var/tmp/*"
    "/home/*/.cache/*"
    "/home/*/.local/share/Trash/*"
    "$BACKUP_DIR/*"
)

# Build exclude parameters
EXCLUDE_PARAMS=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_PARAMS="$EXCLUDE_PARAMS --exclude=$dir"
done

# Create backup with progress
echo "Creating compressed archive..."
sudo tar -czpvf "$BACKUP_PATH" \
    $EXCLUDE_PARAMS \
    --warning=no-file-changed \
    / 2>&1 | pv -l -s $(sudo find / -path /proc -prune -o -path /sys -prune -o -path /dev -prune -o -print 2>/dev/null | wc -l) > /dev/null || true

# If pv not available, use without progress
if [ $? -ne 0 ]; then
    echo "Note: Install 'pv' for progress bar (sudo pacman -S pv)"
    sudo tar -czpf "$BACKUP_PATH" $EXCLUDE_PARAMS / 2>/dev/null
fi

# Create backup info file
INFO_FILE="$BACKUP_DIR/backup-info.txt"
cat > "$INFO_FILE" << EOF
Arch Linux System Backup Information
=====================================
Backup Date: $(date)
Hostname: $(hostname)
Kernel: $(uname -r)
Architecture: $(uname -m)

Installed Packages:
$(pacman -Q | wc -l) packages

Backup File: $BACKUP_FILE
Backup Size: $(du -h "$BACKUP_PATH" | cut -f1)

Excluded Directories:
$(printf '%s\n' "${EXCLUDE_DIRS[@]}")

=== Package List ===
$(pacman -Q)

=== Explicitly Installed Packages ===
$(pacman -Qe)

=== AUR Packages ===
$(pacman -Qm)

=== System Info ===
$(uname -a)
$(cat /etc/os-release)
EOF

# Save package list separately
pacman -Qe > "$BACKUP_DIR/pkglist-explicit.txt"
pacman -Q > "$BACKUP_DIR/pkglist-all.txt"
pacman -Qm > "$BACKUP_DIR/pkglist-aur.txt" 2>/dev/null || touch "$BACKUP_DIR/pkglist-aur.txt"

echo ""
echo -e "${GREEN}=== Backup Complete ===${NC}"
echo ""
echo "Backup file: $BACKUP_PATH"
echo "Backup size: $(du -h "$BACKUP_PATH" | cut -f1)"
echo "Backup info: $INFO_FILE"
echo ""
echo -e "${YELLOW}To restore on a new system:${NC}"
echo "1. Boot from Arch installation media"
echo "2. Mount target partition: mount /dev/sdX /mnt"
echo "3. Extract backup: tar -xzpf $BACKUP_FILE -C /mnt"
echo "4. Mount system: arch-chroot /mnt"
echo "5. Regenerate fstab: genfstab -U /mnt > /mnt/etc/fstab"
echo "6. Install bootloader and reboot"
echo ""
echo -e "${YELLOW}Package restoration:${NC}"
echo "pacman -S --needed \$(cat pkglist-explicit.txt | awk '{print \$1}')"
