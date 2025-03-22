#!/bin/bash
# Sigil Install Script
# This script installs Sigil by downloading the latest version from GitHub,
# making it executable, and placing it in /usr/local/bin.
# It also ensures all required dependencies (openssl and gum) are installed.

set -e  # Exit on any error

# Define the GitHub repository and script name
REPO="https://github.com/gourdian25/sigil"
SCRIPT_NAME="sigil"
INSTALL_DIR="/usr/local/bin"

# Function to check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to install a dependency using the system package manager
install_dependency() {
    local dependency="$1"
    local install_command="$2"
    
    if ! command_exists "$dependency"; then
        echo -e "\033[1;33m$dependency is required but not installed. Installing...\033[0m"
        if ! eval "$install_command"; then
            echo -e "\033[1;31mFailed to install $dependency. Please install it manually and try again.\033[0m"
            exit 1
        fi
    else
        echo -e "\033[1;32m$dependency is already installed.\033[0m"
    fi
}

# Check and install dependencies
echo -e "\033[1;36mChecking dependencies...\033[0m"
if command_exists "apt-get"; then
    # For Debian/Ubuntu-based systems
    install_dependency "openssl" "sudo apt-get install -y openssl"
    # install_dependency "gum" "sudo apt-get install -y gum"
elif command_exists "yum"; then
    # For CentOS/RHEL-based systems
    install_dependency "openssl" "sudo yum install -y openssl"
    install_dependency "gum" "sudo yum install -y gum"
elif command_exists "brew"; then
    # For macOS
    install_dependency "openssl" "brew install openssl"
    install_dependency "gum" "brew install gum"
else
    echo -e "\033[1;31mUnsupported package manager. Please install 'openssl' and 'gum' manually.\033[0m"
    exit 1
fi

# Download the script
echo -e "\033[1;32mDownloading Sigil...\033[0m"
curl -fsSL "${REPO}/raw/master/sigil.sh" -o "/tmp/${SCRIPT_NAME}"

# Make the script executable
echo -e "\033[1;32mMaking Sigil executable...\033[0m"
chmod +x "/tmp/${SCRIPT_NAME}"

# Move the script to /usr/local/bin
echo -e "\033[1;32mInstalling Sigil to ${INSTALL_DIR}...\033[0m"
sudo mv "/tmp/${SCRIPT_NAME}" "${INSTALL_DIR}/${SCRIPT_NAME}"

# Verify installation
if command -v "${SCRIPT_NAME}" &> /dev/null; then
    echo -e "\033[1;32mSigil installed successfully!\033[0m"
    echo -e "Run 'sigil' to start using the tool."
else
    echo -e "\033[1;31mInstallation failed. Please check your permissions and try again.\033[0m"
    exit 1
fi