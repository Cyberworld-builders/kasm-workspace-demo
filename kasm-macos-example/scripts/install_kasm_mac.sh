#!/bin/bash
set -e

# Check if running as root (not needed on Mac with Docker Desktop, but good practice)
if [ "$EUID" -eq 0 ]; then
    echo "No need to run as root on macOS with Docker Desktop"
fi

# Verify Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Please install Docker Desktop and ensure it's running."
    exit 1
fi
if ! docker info &> /dev/null; then
    echo "Docker is not running. Start Docker Desktop and try again."
    exit 1
fi

# Set Kasm version
KASM_VERSION="1.16.1.98d6fa"

# Set proper locale to handle byte sequences
export LC_ALL=C

# Download Kasm release
echo "Downloading Kasm v${KASM_VERSION}..."
cd /tmp
curl -O --retry 3 https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz
tar -xzf kasm_release_${KASM_VERSION}.tar.gz

# Generate a UUID (macOS compatible way)
UUID=$(uuidgen)

# Before installing, create temporary proc structure for compatibility
echo "Setting up temporary compatibility structure..."
sudo mkdir -p /proc/sys/kernel/random
echo "$UUID" | sudo tee /proc/sys/kernel/random/uuid > /dev/null

# Install Kasm
echo "Installing Kasm Workspaces..."
cd kasm_release
sudo UUID="$UUID" bash install.sh --install-profile noninteractive --admin-password "kasmadmin123" --user-password "kasmuser123"

# Clean up temporary proc structure
sudo rm -rf /proc/sys/kernel/random

# Get local IP (optional, localhost works on Mac)
LOCAL_IP=$(ipconfig getifaddr en0 || echo "localhost")

echo "Kasm installed!"
echo "Access it at: https://${LOCAL_IP}"
echo "Credentials: admin@kasm.local / kasmadmin123"
echo "If SSL errors occur, use http:// temporarily or configure a certificate."