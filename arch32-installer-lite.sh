#!/bin/bash

################################################################################
# Arch Linux 32 GUI Installer (Lightweight Version)
# A text-based interactive installer for Arch Linux 32 (no dialog dependency)
# Usage: sudo bash arch32-installer-lite.sh
################################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Configuration variables
INSTALL_DEVICE=""
INSTALL_HOSTNAME="arch32-machine"
INSTALL_USERNAME="archuser"
INSTALL_TIMEZONE="UTC"
INSTALL_LOCALE="en_US.UTF-8"
ROOT_PASSWORD=""
USER_PASSWORD=""
INSTALL_DESKTOP="none"

# Clear screen helper
clear_screen() {
    clear
    echo -e "${CYAN}${BOLD}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║          Arch Linux 32 Installation Assistant           ║${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Pause helper
pause_menu() {
    echo ""
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Show welcome screen
show_welcome() {
    clear_screen
    echo -e "${GREEN}Welcome to the Arch Linux 32 Installation Assistant!${NC}"
    echo ""
    echo "This script will guide you through installing Arch Linux 32."
    echo ""
    echo -e "${YELLOW}Prerequisites:${NC}"
    echo "  • 4GB+ USB drive or bootable media"
    echo "  • Backed up important data"
    echo "  • Stable internet connection"
    echo "  • At least 10GB free disk space"
    echo ""
    echo -e "${BOLD}Disclaimer: All data on the selected disk will be erased!${NC}"
    echo ""
    pause_menu
}

# Menu prompt helper
prompt_menu() {
    local prompt="$1"
    local default="$2"
    local response
    
    echo -n -e "${BLUE}${prompt}${NC} [${GREEN}${default}${NC}]: "
    read -r response
    echo "${response:-$default}"
}

# Select installation device
select_device() {
    clear_screen
    echo -e "${BOLD}Step 1: Select Installation Device${NC}"
    echo ""
    
    echo "Available block devices:"
    echo ""
    lsblk -d -n -o NAME,SIZE,MODEL | awk '{printf "  /dev/%-8s %6s  %s\n", $1, $2, $3}' | grep -v loop | grep -v ram
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: All data on the selected device will be permanently erased!${NC}"
    echo ""
    
    INSTALL_DEVICE=$(prompt_menu "Enter device path" "/dev/sda")
    
    if [[ ! -b "$INSTALL_DEVICE" ]]; then
        echo -e "${RED}Error: $INSTALL_DEVICE is not a valid block device${NC}"
        pause_menu
        select_device
        return
    fi
    
    local size=$(lsblk -dn -o SIZE "$INSTALL_DEVICE" 2>/dev/null || echo "Unknown")
    echo ""
    echo -e "${CYAN}Selected device: ${GREEN}${INSTALL_DEVICE}${CYAN} (${size})${NC}"
    pause_menu
}

# Partition disk
partition_disk() {
    clear_screen
    echo -e "${BOLD}Step 2: Partition Disk${NC}"
    echo ""
    echo "Device: $INSTALL_DEVICE"
    echo "This will:"
    echo "  1. Clear the disk"
    echo "  2. Create boot partition (512MB)"
    echo "  3. Create root partition (remaining space)"
    echo ""
    echo -e "${YELLOW}⚠️  WARNING: This will erase all data on ${INSTALL_DEVICE}!${NC}"
    echo ""
    
    read -p "Continue with partitioning? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}Partitioning skipped${NC}"
        pause_menu
        return
    fi
    
    echo -e "${BLUE}Creating partitions...${NC}"
    
    # Clear partition table
    dd if=/dev/zero of="$INSTALL_DEVICE" bs=512 count=2048 2>/dev/null
    
    # Create partitions
    cat << EOF | fdisk "$INSTALL_DEVICE" 2>/dev/null
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
    
    # Determine partition naming
    local boot_part root_part
    if [[ -b "${INSTALL_DEVICE}1" ]]; then
        boot_part="${INSTALL_DEVICE}1"
        root_part="${INSTALL_DEVICE}2"
    elif [[ -b "${INSTALL_DEVICE}p1" ]]; then
        boot_part="${INSTALL_DEVICE}p1"
        root_part="${INSTALL_DEVICE}p2"
    else
        echo -e "${RED}Error: Could not find partitions${NC}"
        pause_menu
        return 1
    fi
    
    echo -e "${BLUE}Creating filesystems...${NC}"
    mkfs.fat -F 32 "$boot_part" > /dev/null 2>&1
    mkfs.ext4 -F "$root_part" > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Disk partitioned successfully${NC}"
    pause_menu
}

# Configure hostname
configure_hostname() {
    clear_screen
    echo -e "${BOLD}Step 3: System Hostname${NC}"
    echo ""
    echo "This is the name of your computer on the network."
    echo ""
    
    INSTALL_HOSTNAME=$(prompt_menu "Enter hostname" "arch32-machine")
    
    echo -e "${GREEN}✓ Hostname set to: ${INSTALL_HOSTNAME}${NC}"
    pause_menu
}

# Configure timezone
configure_timezone() {
    clear_screen
    echo -e "${BOLD}Step 4: Select Timezone${NC}"
    echo ""
    echo "Common timezones:"
    echo "  UTC, America/New_York, America/Chicago, America/Denver,"
    echo "  America/Los_Angeles, Europe/London, Europe/Paris,"
    echo "  Europe/Moscow, Asia/Tokyo, Australia/Sydney"
    echo ""
    
    INSTALL_TIMEZONE=$(prompt_menu "Enter timezone" "UTC")
    
    echo -e "${GREEN}✓ Timezone set to: ${INSTALL_TIMEZONE}${NC}"
    pause_menu
}

# Configure locale
configure_locale() {
    clear_screen
    echo -e "${BOLD}Step 5: Select Locale${NC}"
    echo ""
    echo "Common locales:"
    echo "  en_US.UTF-8, en_GB.UTF-8, de_DE.UTF-8, fr_FR.UTF-8,"
    echo "  es_ES.UTF-8, ja_JP.UTF-8, pt_BR.UTF-8, zh_CN.UTF-8"
    echo ""
    
    INSTALL_LOCALE=$(prompt_menu "Enter locale" "en_US.UTF-8")
    
    echo -e "${GREEN}✓ Locale set to: ${INSTALL_LOCALE}${NC}"
    pause_menu
}

# Configure root password
configure_root_password() {
    clear_screen
    echo -e "${BOLD}Step 6: Set Root Password${NC}"
    echo ""
    echo "Enter a strong password for the root user."
    echo ""
    
    while true; do
        read -sp "Root password: " ROOT_PASSWORD
        echo ""
        
        if [[ -z "$ROOT_PASSWORD" ]]; then
            echo -e "${RED}Password cannot be empty!${NC}"
            continue
        fi
        
        read -sp "Confirm password: " confirm_pass
        echo ""
        
        if [[ "$ROOT_PASSWORD" == "$confirm_pass" ]]; then
            echo -e "${GREEN}✓ Root password set${NC}"
            break
        else
            echo -e "${RED}Passwords do not match. Try again.${NC}"
        fi
    done
    
    pause_menu
}

# Configure user account
configure_user() {
    clear_screen
    echo -e "${BOLD}Step 7: Create User Account${NC}"
    echo ""
    
    INSTALL_USERNAME=$(prompt_menu "Enter username" "archuser")
    
    while true; do
        read -sp "User password: " USER_PASSWORD
        echo ""
        
        if [[ -z "$USER_PASSWORD" ]]; then
            echo -e "${RED}Password cannot be empty!${NC}"
            continue
        fi
        
        read -sp "Confirm password: " confirm_pass
        echo ""
        
        if [[ "$USER_PASSWORD" == "$confirm_pass" ]]; then
            echo -e "${GREEN}✓ User account configured${NC}"
            break
        else
            echo -e "${RED}Passwords do not match. Try again.${NC}"
        fi
    done
    
    pause_menu
}

# Select desktop environment
select_desktop() {
    clear_screen
    echo -e "${BOLD}Step 8: Select Desktop Environment${NC}"
    echo ""
    echo "Options:"
    echo "  1) None (Server/CLI only)"
    echo "  2) XFCE (Lightweight, Recommended)"
    echo "  3) LXDE (Very Lightweight)"
    echo "  4) KDE Plasma (Full-featured)"
    echo "  5) GNOME (Feature-rich)"
    echo "  6) i3 (Tiling Window Manager)"
    echo "  7) Openbox (Minimal)"
    echo ""
    
    read -p "Select desktop environment (1-7): " choice
    
    case "$choice" in
        1) INSTALL_DESKTOP="none" ;;
        2) INSTALL_DESKTOP="xfce" ;;
        3) INSTALL_DESKTOP="lxde" ;;
        4) INSTALL_DESKTOP="kde" ;;
        5) INSTALL_DESKTOP="gnome" ;;
        6) INSTALL_DESKTOP="i3" ;;
        7) INSTALL_DESKTOP="openbox" ;;
        *) INSTALL_DESKTOP="none" ;;
    esac
    
    echo -e "${GREEN}✓ Desktop: ${INSTALL_DESKTOP}${NC}"
    pause_menu
}

# Review configuration
review_configuration() {
    clear_screen
    echo -e "${BOLD}Installation Summary${NC}"
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║          Installation Settings         ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  Device:          ${GREEN}${INSTALL_DEVICE}${NC}"
    echo -e "  Hostname:        ${GREEN}${INSTALL_HOSTNAME}${NC}"
    echo -e "  Timezone:        ${GREEN}${INSTALL_TIMEZONE}${NC}"
    echo -e "  Locale:          ${GREEN}${INSTALL_LOCALE}${NC}"
    echo -e "  Username:        ${GREEN}${INSTALL_USERNAME}${NC}"
    echo -e "  Desktop:         ${GREEN}${INSTALL_DESKTOP}${NC}"
    echo ""
    
    read -p "Proceed with installation? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        echo -e "${YELLOW}Installation cancelled${NC}"
        exit 0
    fi
}

# Begin installation
begin_installation() {
    clear_screen
    echo -e "${BOLD}${GREEN}Beginning Installation...${NC}"
    echo ""
    echo "This process will take several minutes depending on your internet speed."
    echo ""
    pause_menu
}

# Completion message
show_completion() {
    clear_screen
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║    Arch Linux 32 Installation Complete!              ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "System Details:"
    echo -e "  ${CYAN}Hostname:${NC}  ${GREEN}${INSTALL_HOSTNAME}${NC}"
    echo -e "  ${CYAN}Username:${NC}  ${GREEN}${INSTALL_USERNAME}${NC}"
    echo -e "  ${CYAN}Desktop:${NC}   ${GREEN}${INSTALL_DESKTOP}${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Remove installation media"
    echo "  2. Reboot your computer"
    echo "  3. Login and enjoy Arch Linux 32!"
    echo ""
    read -p "Press Enter to reboot now (or Ctrl+C to cancel)..."
    # reboot
}

# Main function
main() {
    check_root
    
    show_welcome
    select_device
    partition_disk
    configure_hostname
    configure_timezone
    configure_locale
    configure_root_password
    configure_user
    select_desktop
    review_configuration
    begin_installation
    
    echo -e "${YELLOW}Installation process would start here...${NC}"
    echo -e "${YELLOW}(Full implementation requires pacstrap and arch-chroot)${NC}"
    
    show_completion
}

# Run
main "$@"
