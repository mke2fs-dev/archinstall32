#!/bin/bash

################################################################################
# Arch Linux 32 GUI Installer
# A comprehensive interactive installer for Arch Linux 32 (i686 architecture)
# Usage: sudo bash arch32-installer.sh
################################################################################

set -e

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
INSTALL_DEVICE=""
INSTALL_HOSTNAME=""
INSTALL_USERNAME=""
INSTALL_TIMEZONE="UTC"
INSTALL_LOCALE="en_US.UTF-8"
SWAP_SIZE="2G"
INSTALL_DESKTOP="none"
INSTALL_PACKAGES=""
ROOT_PASSWORD=""
USER_PASSWORD=""

# Ensure running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Check for required tools
check_dependencies() {
    local missing_tools=()
    
    for tool in dialog fdisk mkfs.ext4 mount chroot arch-chroot pacstrap; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        echo -e "${YELLOW}Warning: The following tools are missing: ${missing_tools[*]}${NC}"
        echo "Some features may not work properly."
    fi
}

# Display welcome screen
show_welcome() {
    dialog --title "Arch Linux 32 Installer" \
           --msgbox "Welcome to the Arch Linux 32 GUI Installer\n\nThis script will guide you through installing Arch Linux 32 on your system.\n\nMake sure you have:\n- A USB drive or bootable media\n- Backed up important data\n- Internet connection\n\nPress OK to continue." \
           12 60
}

# Select installation device
select_device() {
    local devices=()
    local device_list=()
    
    # Get list of block devices (excluding loop devices and RAM disks)
    while IFS= read -r device; do
        local device_name="/dev/$device"
        local size=$(lsblk -dn -o SIZE "$device_name" 2>/dev/null || echo "Unknown")
        devices+=("$device_name" "$size")
        device_list+=("$device_name")
    done < <(lsblk -dn -o NAME | grep -v loop | grep -v ram)
    
    if [[ ${#device_list[@]} -eq 0 ]]; then
        dialog --title "Error" \
               --msgbox "No suitable block devices found!" \
               6 40
        return 1
    fi
    
    INSTALL_DEVICE=$(dialog --title "Select Installation Device" \
                            --menu "Choose the device to install Arch Linux 32 on:\n\nWARNING: All data on this device will be erased!" \
                            15 60 5 \
                            "${devices[@]}" \
                            3>&1 1>&2 2>&3)
    
    if [[ -z "$INSTALL_DEVICE" ]]; then
        return 1
    fi
}

# Partition the disk
partition_disk() {
    dialog --title "Confirm Partitioning" \
           --yesno "This will erase all data on $INSTALL_DEVICE\n\nContinue?" \
           7 50
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Clear partition table
    dd if=/dev/zero of="$INSTALL_DEVICE" bs=512 count=2048
    
    # Create partition table and partitions using fdisk
    cat << EOF | fdisk "$INSTALL_DEVICE"
o
n
p
1

+512M
n
p
2


t
1
83
t
2
83
a
1
w
EOF
    
    sleep 2
    
    # Format partitions
    local boot_part="${INSTALL_DEVICE}1"
    local root_part="${INSTALL_DEVICE}2"
    
    if [[ ! -e "$boot_part" ]]; then
        boot_part="${INSTALL_DEVICE}p1"
        root_part="${INSTALL_DEVICE}p2"
    fi
    
    dialog --title "Creating Filesystems" \
           --infobox "Formatting $boot_part as FAT32...\nFormatting $root_part as ext4..." \
           5 50
    
    mkfs.fat -F 32 "$boot_part" > /dev/null 2>&1
    mkfs.ext4 -F "$root_part" > /dev/null 2>&1
    
    dialog --title "Success" \
           --msgbox "Disk partitioned successfully!" \
           5 40
}

# Configure hostname
configure_hostname() {
    INSTALL_HOSTNAME=$(dialog --title "System Hostname" \
                              --inputbox "Enter your system hostname:" \
                              8 50 "arch32-machine" \
                              3>&1 1>&2 2>&3)
    
    if [[ -z "$INSTALL_HOSTNAME" ]]; then
        INSTALL_HOSTNAME="arch32-machine"
    fi
}

# Configure timezone
configure_timezone() {
    INSTALL_TIMEZONE=$(dialog --title "Select Timezone" \
                              --menu "Select your timezone:" \
                              20 60 10 \
                              "UTC" "UTC/GMT" \
                              "America/New_York" "Eastern Time" \
                              "America/Chicago" "Central Time" \
                              "America/Denver" "Mountain Time" \
                              "America/Los_Angeles" "Pacific Time" \
                              "Europe/London" "London" \
                              "Europe/Paris" "Central European" \
                              "Europe/Moscow" "Moscow" \
                              "Asia/Tokyo" "Tokyo" \
                              "Australia/Sydney" "Sydney" \
                              3>&1 1>&2 2>&3)
    
    if [[ -z "$INSTALL_TIMEZONE" ]]; then
        INSTALL_TIMEZONE="UTC"
    fi
}

# Configure locale
configure_locale() {
    INSTALL_LOCALE=$(dialog --title "Select Locale" \
                            --menu "Select your locale:" \
                            15 60 8 \
                            "en_US.UTF-8" "English (US)" \
                            "en_GB.UTF-8" "English (UK)" \
                            "de_DE.UTF-8" "German" \
                            "fr_FR.UTF-8" "French" \
                            "es_ES.UTF-8" "Spanish" \
                            "ja_JP.UTF-8" "Japanese" \
                            "pt_BR.UTF-8" "Portuguese (Brazil)" \
                            "zh_CN.UTF-8" "Chinese (Simplified)" \
                            3>&1 1>&2 2>&3)
    
    if [[ -z "$INSTALL_LOCALE" ]]; then
        INSTALL_LOCALE="en_US.UTF-8"
    fi
}

# Configure user account
configure_user() {
    INSTALL_USERNAME=$(dialog --title "User Account" \
                              --inputbox "Enter username for your account:" \
                              8 50 "archuser" \
                              3>&1 1>&2 2>&3)
    
    if [[ -z "$INSTALL_USERNAME" ]]; then
        INSTALL_USERNAME="archuser"
    fi
    
    USER_PASSWORD=$(dialog --title "User Password" \
                           --passwordbox "Enter password for $INSTALL_USERNAME:" \
                           8 50 \
                           3>&1 1>&2 2>&3)
    
    if [[ -z "$USER_PASSWORD" ]]; then
        dialog --title "Error" \
               --msgbox "Password cannot be empty!" \
               5 40
        configure_user
    fi
}

# Configure root password
configure_root_password() {
    ROOT_PASSWORD=$(dialog --title "Root Password" \
                           --passwordbox "Enter password for root user:" \
                           8 50 \
                           3>&1 1>&2 2>&3)
    
    if [[ -z "$ROOT_PASSWORD" ]]; then
        dialog --title "Error" \
               --msgbox "Root password cannot be empty!" \
               5 40
        configure_root_password
    fi
}

# Select desktop environment
select_desktop() {
    INSTALL_DESKTOP=$(dialog --title "Desktop Environment" \
                             --menu "Select a desktop environment (optional):" \
                             15 60 8 \
                             "none" "No desktop (server)" \
                             "xfce" "XFCE - Lightweight" \
                             "lxde" "LXDE - Very Lightweight" \
                             "kde" "KDE Plasma - Full-Featured" \
                             "gnome" "GNOME - Feature-Rich" \
                             "i3" "i3 - Tiling WM" \
                             "openbox" "Openbox - Minimal WM" \
                             3>&1 1>&2 2>&3)
    
    if [[ -z "$INSTALL_DESKTOP" ]]; then
        INSTALL_DESKTOP="none"
    fi
}

# Configure additional packages
configure_packages() {
    INSTALL_PACKAGES=$(dialog --title "Additional Packages" \
                              --checklist "Select additional packages to install:" \
                              20 60 12 \
                              "vim" "Advanced text editor" on \
                              "nano" "Simple text editor" off \
                              "git" "Version control system" on \
                              "wget" "Download utility" on \
                              "curl" "Data transfer tool" on \
                              "htop" "System monitor" on \
                              "neofetch" "System information" off \
                              "networkmanager" "Network manager" on \
                              "firefox" "Web browser" off \
                              "vlc" "Media player" off \
                              "gimp" "Image editor" off \
                              3>&1 1>&2 2>&3)
}

# Review installation configuration
review_config() {
    local review_text="Installation Configuration Summary:\n\n"
    review_text+="Device: $INSTALL_DEVICE\n"
    review_text+="Hostname: $INSTALL_HOSTNAME\n"
    review_text+="Timezone: $INSTALL_TIMEZONE\n"
    review_text+="Locale: $INSTALL_LOCALE\n"
    review_text+="Username: $INSTALL_USERNAME\n"
    review_text+="Desktop Environment: $INSTALL_DESKTOP\n"
    review_text+="Additional Packages: ${INSTALL_PACKAGES:-None}\n\n"
    review_text+="Ready to proceed with installation?"
    
    dialog --title "Review Configuration" \
           --yesno "$review_text" \
           18 60
}

# Mount filesystems and prepare chroot
mount_filesystems() {
    local boot_part="${INSTALL_DEVICE}1"
    local root_part="${INSTALL_DEVICE}2"
    
    if [[ ! -e "$boot_part" ]]; then
        boot_part="${INSTALL_DEVICE}p1"
        root_part="${INSTALL_DEVICE}p2"
    fi
    
    dialog --title "Mounting Filesystems" \
           --infobox "Mounting filesystems...\nDo not interrupt this process." \
           5 50
    
    mkdir -p /mnt/arch32
    mount "$root_part" /mnt/arch32
    mkdir -p /mnt/arch32/boot
    mount "$boot_part" /mnt/arch32/boot
}

# Bootstrap Arch Linux 32
bootstrap_system() {
    dialog --title "Installing Base System" \
           --infobox "Bootstrapping Arch Linux 32 base system...\nThis may take several minutes." \
           5 50
    
    # Mirror list for Arch Linux 32
    cat > /etc/pacman.d/mirrorlist.arch32 << 'EOF'
Server = http://mirror.archlinux32.org/$arch/$repo
Server = http://arch32.mirror.sys4.de/$arch/$repo
EOF
    
    pacstrap -i /mnt/arch32 base linux linux-firmware base-devel 2>&1 | tail -5
}

# Generate fstab
generate_fstab() {
    dialog --title "Generating fstab" \
           --infobox "Generating filesystem table..." \
           5 50
    
    genfstab -U /mnt/arch32 >> /mnt/arch32/etc/fstab
}

# Configure system in chroot
configure_chroot() {
    dialog --title "Configuring System" \
           --infobox "Configuring system settings in chroot environment...\nPlease wait." \
           5 50
    
    # Create a script to run in chroot
    cat > /mnt/arch32/root/configure.sh << CHROOT_EOF
#!/bin/bash

# Set timezone
ln -sf /usr/share/zoneinfo/$INSTALL_TIMEZONE /etc/localtime
hwclock --systohc

# Set locale
echo "$INSTALL_LOCALE UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=$INSTALL_LOCALE" > /etc/locale.conf

# Set hostname
echo "$INSTALL_HOSTNAME" > /etc/hostname

# Configure hosts
cat > /etc/hosts << 'EOF'
127.0.0.1   localhost
::1         localhost
127.0.1.1   $INSTALL_HOSTNAME.localdomain   $INSTALL_HOSTNAME
EOF

# Install bootloader
pacman -S --noconfirm grub efibootmgr
grub-install --target=i386-pc --recheck $INSTALL_DEVICE
grub-mkconfig -o /boot/grub/grub.cfg

# Set root password
echo "root:$ROOT_PASSWORD" | chpasswd

# Create user
useradd -m -G wheel -s /bin/bash $INSTALL_USERNAME
echo "$INSTALL_USERNAME:$USER_PASSWORD" | chpasswd

# Configure sudo for wheel group
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# Install desktop environment
case "$INSTALL_DESKTOP" in
    xfce)
        pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
        systemctl enable lightdm
        ;;
    kde)
        pacman -S --noconfirm plasma-desktop sddm
        systemctl enable sddm
        ;;
    gnome)
        pacman -S --noconfirm gnome gnome-extra gdm
        systemctl enable gdm
        ;;
    lxde)
        pacman -S --noconfirm lxde lxdm
        systemctl enable lxdm
        ;;
    i3)
        pacman -S --noconfirm i3-wm i3status dmenu lightdm lightdm-gtk-greeter
        systemctl enable lightdm
        ;;
    openbox)
        pacman -S --noconfirm openbox obconf lightdm lightdm-gtk-greeter
        systemctl enable lightdm
        ;;
esac

# Install additional packages
if [[ -n "$INSTALL_PACKAGES" ]]; then
    pacman -S --noconfirm $INSTALL_PACKAGES
fi

# Enable networking
systemctl enable systemd-networkd
systemctl enable systemd-resolved

echo "Configuration complete!"
CHROOT_EOF
    
    chmod +x /mnt/arch32/root/configure.sh
    arch-chroot /mnt/arch32 /root/configure.sh
}

# Install bootloader
install_bootloader() {
    dialog --title "Installing Bootloader" \
           --infobox "Installing GRUB bootloader..." \
           5 50
}

# Final cleanup
cleanup() {
    dialog --title "Finalizing Installation" \
           --infobox "Unmounting filesystems and cleaning up..." \
           5 50
    
    umount -R /mnt/arch32 2>/dev/null || true
}

# Show completion message
show_completion() {
    dialog --title "Installation Complete" \
           --msgbox "Arch Linux 32 has been successfully installed!\n\nSystem Details:\n- Hostname: $INSTALL_HOSTNAME\n- Username: $INSTALL_USERNAME\n- Desktop: $INSTALL_DESKTOP\n\nRemove the installation media and reboot to start your new system.\n\nPress OK to reboot." \
           15 60
    
    if [[ $? -eq 0 ]]; then
        reboot
    fi
}

# Main installation flow
main() {
    check_root
    check_dependencies
    
    trap cleanup EXIT
    
    show_welcome
    
    # Configuration phase
    select_device || exit 1
    partition_disk || exit 1
    configure_hostname
    configure_timezone
    configure_locale
    configure_root_password
    configure_user
    select_desktop
    configure_packages
    
    # Review before installation
    review_config || exit 1
    
    # Installation phase
    mount_filesystems
    bootstrap_system
    generate_fstab
    configure_chroot
    install_bootloader
    cleanup
    show_completion
}

# Run main function
main "$@"
