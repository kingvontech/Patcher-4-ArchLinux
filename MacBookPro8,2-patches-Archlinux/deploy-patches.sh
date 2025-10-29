#!/bin/bash

# ==============================================================================
# MacBook Pro 8,2 Performance Patcher for Arch Linux
# Script: deploy-patches.sh
# Version: 1.0.1 (Refined Dependencies)
# Description: Installs necessary packages, backs up original files, and
#              deploys performance-focused configuration files for GRUB,
#              CPU power management, and fan control.
# ==============================================================================

# Configuration
# Ensures SCRIPT_DIR is the current directory of the script, regardless of where it is executed from
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BACKUP_DIR="${SCRIPT_DIR}/backup-$(date +%Y%m%d-%H%M%S)"

# Files to be copied and their destination paths (relative to root /)
declare -A FILES_TO_DEPLOY=(
    # Custom systemd service to enforce 'performance' governor and aggressive power tweaks
    ["cpupower.service"]="/etc/systemd/system/cpupower.service"
    # Kernel module settings for I/O and specific hardware fixes
    ["99-performance.conf"]="/etc/modprobe.d/99-performance.conf"
    # mbpfan configuration for optimized fan curve
    ["mbpfan.conf"]="/etc/mbpfan.conf"
    # GRUB script containing the gmux (AMD GPU power-down) hack
    ["10_linux"]="/etc/grub.d/10_linux"
)

# Packages required for the patches to function (AUR/Repo mix)
REQUIRED_PACKAGES=(
    "cpupower"
    "mbpfan"
    "broadcom-wl" # User's preferred version for Wi-Fi stability (instead of dkms)
    "pommed"      # For keyboard backlight/function keys
)

# --- Functions ---

# Function to install the AUR helper 'yay' if it is not present.
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "=========================================================="
        echo " 🛠️ Installing 'yay' (AUR Helper)"
        echo "=========================================================="
        sudo pacman -S --noconfirm base-devel git
        
        mkdir -p /tmp/yay_install
        cd /tmp/yay_install
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        if [ $? -ne 0 ]; then
            echo "FATAL ERROR: Failed to install 'yay'. Cannot continue."
            exit 1
        fi
        cd "$SCRIPT_DIR"
        rm -rf /tmp/yay_install
    else
        echo "yay is already installed. Skipping installation."
    fi
}

# Function to safely create backup and copy file
copy_and_backup() {
    local SOURCE_FILE="$1"
    local DEST_PATH="$2"
    local DEST_FILE="/${DEST_PATH}"

    # 1. Back up existing file
    if [ -f "$DEST_FILE" ]; then
        echo "--> Backing up ${DEST_FILE}..."
        # Create the necessary folder structure in the backup directory
        sudo mkdir -p "${BACKUP_DIR}$(dirname "${DEST_FILE}")"
        # Copy the original file to the backup folder, preserving path structure
        sudo cp -v "$DEST_FILE" "${BACKUP_DIR}${DEST_FILE}"
    else
        echo "--> Original file ${DEST_FILE} not found. Ensuring destination directory exists."
        sudo mkdir -p "$(dirname "${DEST_FILE}")"
    fi

    # 2. Deploy patched file
    echo "--> Installing ${SOURCE_FILE} to ${DEST_FILE}..."
    sudo cp -v "${SCRIPT_DIR}/${SOURCE_FILE}" "$DEST_FILE"
}

# --- Main Script Execution ---

echo "=========================================================="
echo " Starting MacBookPro8,2 Patch Deployment "
echo "=========================================================="

# 1. Install 'yay'
install_yay

# 2. Create Backup Directory
echo ""
echo "Creating backup directory: ${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}"
echo "Backup directory created at: ${BACKUP_DIR}"

# 3. Update System and Install Required Packages
echo ""
echo "=========================================================="
echo " 📦 Updating System and Installing Packages"
echo "=========================================================="
yay -Syu --noconfirm

# Install required packages (AUR/Repo mix)
yay -S --noconfirm --needed "${REQUIRED_PACKAGES[@]}"

if [ $? -ne 0 ]; then
    echo ""
    echo "WARNING: One or more package installations failed (likely pommed)."
    echo "The core performance patches (CPU/GRUB/Fan/Wi-Fi) will still be applied."
fi

# 4. Deploy Configuration Files with Backup
echo ""
echo "=========================================================="
echo " 💾 Deploying Patched Files with Backup"
echo "=========================================================="
for SOURCE in "${!FILES_TO_DEPLOY[@]}"; do
    DEST="${FILES_TO_DEPLOY[$SOURCE]}"
    copy_and_backup "$SOURCE" "$DEST"
done

# 5. Enable and Start Services
echo ""
echo "=========================================================="
echo " 🚀 Enabling and Starting Services"
echo "=========================================================="

# 5.1. cpupower
sudo systemctl daemon-reload
sudo systemctl enable cpupower.service
sudo systemctl start cpupower.service
echo "cpupower.service enabled and started (Sets CPU to 'performance')."

# 5.2. mbpfan
if systemctl list-unit-files | grep -q mbpfan.service; then
    sudo systemctl enable mbpfan.service
    sudo systemctl restart mbpfan.service
    echo "mbpfan.service enabled and restarted with new config."
fi

# 5.3. pommed (Keyboard Backlight/Keys)
if systemctl list-unit-files | grep -q pommed.service; then
    sudo systemctl enable pommed.service
    sudo systemctl start pommed.service
    echo "pommed.service enabled and started."
fi

# 6. Apply GRUB Changes
echo ""
echo "=========================================================="
echo " ⚙️ Applying GRUB Changes"
echo "=========================================================="
sudo grub-mkconfig -o /boot/grub/grub.cfg
echo "GRUB configuration updated."

echo ""
echo "=========================================================="
echo " ✅ Deployment Complete!"
echo "=========================================================="
echo "Original files are backed up in: ${BACKUP_DIR}"
echo "You must REBOOT the system to load the new kernel parameters and permanently disable the AMD GPU."

