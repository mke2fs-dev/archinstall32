# Arch Linux 32 GUI Installer

A professional bash shell script GUI installer specifically designed for **Arch Linux 32** (i686 architecture).

## Features

### Full-Featured Version (arch32-installer.sh)
- **Dialog-based GUI** - Professional terminal UI with menus and dialog boxes
- **Automatic partitioning** - Creates boot and root partitions automatically
- **User configuration** - Set hostname, timezone, locale, and user accounts
- **Desktop environment selection** - Choose from XFCE, KDE, GNOME, LXDE, i3, or server-only
- **Package management** - Select additional packages to install
- **GRUB bootloader** - Automatic bootloader installation and configuration
- **chroot automation** - Streamlined system configuration in chroot environment

### Lightweight Version (arch32-installer-lite.sh)
- **No external dependencies** - Uses only bash and standard utilities
- **Colorful TUI** - Clean, visual terminal interface
- **Interactive prompts** - Step-by-step configuration
- **Review before install** - Summary screen to confirm all settings
- **Portable** - Works on minimal systems

## Requirements

### For Full-Featured Version
```bash
- Root access (sudo or direct root login)
- dialog package: sudo pacman -S dialog
- arch-install-scripts: sudo pacman -S arch-install-scripts
- Standard partitioning tools (fdisk, mkfs)
- At least 10GB free disk space
- Stable internet connection
```

### For Lightweight Version
```bash
- Root access
- No additional dependencies required
- Works with minimal installations
```

## Installation

### Option 1: Download and Make Executable
```bash
# Full version
sudo bash arch32-installer.sh

# Or lightweight version
sudo bash arch32-installer-lite.sh
```

### Option 2: Clone and Run
```bash
git clone https://your-repo-url.git
cd arch32-installer
sudo bash arch32-installer.sh
```

### Option 3: Direct Download
```bash
# Full version
curl -O https://your-url/arch32-installer.sh
chmod +x arch32-installer.sh
sudo ./arch32-installer.sh

# Lightweight version
curl -O https://your-url/arch32-installer-lite.sh
chmod +x arch32-installer-lite.sh
sudo ./arch32-installer-lite.sh
```

## Usage

### Quick Start
```bash
sudo bash arch32-installer.sh
```

### Step-by-Step Process

1. **Welcome Screen** - Review installation prerequisites
2. **Select Device** - Choose target disk (e.g., /dev/sda)
3. **Partition Disk** - Creates boot and root partitions
4. **Configure Hostname** - Set your computer's network name
5. **Select Timezone** - Choose your timezone
6. **Select Locale** - Choose your language/locale
7. **Set Root Password** - Secure root account
8. **Create User Account** - Standard user with sudo access
9. **Choose Desktop Environment** - Pick GUI (optional)
10. **Select Packages** - Add additional software
11. **Review & Confirm** - Final configuration check
12. **Installation** - Automatic installation and configuration

## Configuration Options

### Desktop Environments
- **none** - Server/CLI only (minimal)
- **xfce** - Lightweight (4 - 8GB RAM recommended)
- **lxde** - Very lightweight (2 - 4GB RAM recommended)
- **kde** - Full-featured (8GB+ RAM recommended)
- **gnome** - Feature-rich (8GB+ RAM recommended)
- **i3** - Tiling window manager (minimal resources)
- **openbox** - Minimal standalone WM

### Available Packages
- **vim** - Advanced text editor
- **nano** - Simple text editor
- **git** - Version control
- **wget/curl** - Download utilities
- **htop** - System monitor
- **neofetch** - System information
- **networkmanager** - Network configuration
- **firefox** - Web browser
- **vlc** - Media player
- **gimp** - Image editor

### Timezones
- UTC (default)
- America/New_York, America/Chicago, America/Denver, America/Los_Angeles
- Europe/London, Europe/Paris, Europe/Moscow
- Asia/Tokyo
- Australia/Sydney
- ... and many more

### Locales
- en_US.UTF-8 (default)
- en_GB.UTF-8, de_DE.UTF-8, fr_FR.UTF-8, es_ES.UTF-8
- ja_JP.UTF-8, pt_BR.UTF-8, zh_CN.UTF-8
- ... and many more

## Advanced Usage

### Modify Source Code
Edit the scripts to customize:
- Default package list
- Additional partitioning schemes
- Custom kernel parameters
- Mirror selection
- Post-installation hooks

### Example: Add Custom Packages
```bash
# In the configure_packages() function, modify the INSTALL_PACKAGES variable
INSTALL_PACKAGES="vim git wget curl htop neofetch networkmanager"
```

### Example: Change Default Hostname
```bash
# In configure_hostname() function, change:
INSTALL_HOSTNAME="my-custom-host"
```

## Troubleshooting

### "dialog: command not found"
**Solution:** Install dialog package
```bash
sudo pacman -S dialog
```

### "arch-chroot: command not found"
**Solution:** Install arch-install-scripts
```bash
sudo pacman -S arch-install-scripts
```

### Device Not Found
**Solution:** Run `lsblk` to see available devices
```bash
lsblk
# Then use the correct device name (e.g., /dev/sda)
```

### Partitioning Errors
**Solution:** Ensure the device is unmounted
```bash
# Check mounted partitions
mount | grep /dev/sdX

# Unmount if necessary
sudo umount /dev/sdX*
```

### Installation Hangs
**Solution:** Check internet connection
```bash
ping archlinux32.org
```

## Security Recommendations

1. **Strong Passwords**
   - Use at least 12 characters
   - Mix uppercase, lowercase, numbers, and symbols
   - Avoid common words or personal information

2. **User Permissions**
   - Create a standard user (avoid using root)
   - Grant sudo access only when needed
   - Regularly update your system

3. **Network Security**
   - Enable a firewall after installation
   - Use SSH keys instead of passwords
   - Keep your system updated

## Post-Installation

### Update System
```bash
sudo pacman -Syu
```

### Install AUR Helper (optional)
```bash
sudo pacman -S base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
```

### Configure Network (if not using NetworkManager)
```bash
sudo systemctl enable dhcpcd
sudo systemctl start dhcpcd
```

### Install Display Driver
```bash
# NVIDIA
sudo pacman -S nvidia

# AMD
sudo pacman -S xf86-video-amdgpu

# Intel
sudo pacman -S xf86-video-intel
```

## Performance Tips

- **XFCE** - Best balance of features and performance
- **LXDE** - Minimal overhead, suitable for older hardware
- **i3/Openbox** - Lightest, for maximum performance
- **KDE/GNOME** - Feature-rich but resource-hungry

## File Locations

After installation:
- **System Configuration** - `/etc/`
- **User Home** - `/home/$USERNAME/`
- **Boot Configuration** - `/boot/grub/grub.cfg`
- **Installed Packages** - Check with `pacman -Q`

## Support & Documentation

- **Arch Linux 32 Wiki** - https://archlinux32.org/
- **Arch Linux Documentation** - https://wiki.archlinux.org/
- **Community Forums** - https://bbs.archlinux.org/

## License

This installer is provided as-is for educational and personal use. 
Use at your own risk - always backup important data before running any installation script.

## Contributing

Found a bug? Have improvements? 
1. Test thoroughly before suggesting changes
2. Provide clear description of issues
3. Submit pull requests with explanations

## Version History

- **v1.0** - Initial release with full dialog support
- **v1.1-lite** - Lightweight version without dependencies

---

**Created for Arch Linux 32 Community**  
Last Updated: 2024
