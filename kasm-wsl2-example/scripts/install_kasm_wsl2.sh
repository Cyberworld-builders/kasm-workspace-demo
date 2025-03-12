#!/bin/bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Run with sudo"
    exit 1
fi

apt-get update -y
apt-get install -y curl ca-certificates

if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
fi

sudo dockerd &> /dev/null &
sleep 5
if ! docker info &> /dev/null; then
    echo "Docker failed to start"
    exit 1
fi

# Add swap space if missing
if ! swapon -s | grep -q "swapfile"; then
    echo "Adding swap space..."
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
fi

KASM_VERSION="1.16.1.98d6fa"
cd /tmp
echo "Downloading Kasm v${KASM_VERSION}..."
curl -O --retry 3 https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz
tar -xzf kasm_release_${KASM_VERSION}.tar.gz

echo "Installing Kasm..."
cd kasm_release
sudo bash install.sh --install-profile noninteractive --admin-password "kasmadmin123" --user-password "kasmuser123" --no-start

echo "Starting Kasm manually..."
sudo /opt/kasm/bin/start

WSL_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Kasm installed! Access at: https://${WSL_IP}"
echo "Credentials: admin@kasm.local / kasmadmin123"