#!/bin/bash

# Exit on error
set -e

# Check if running as root (sudo needed for most steps)
if [ "$EUID" -ne 0 ]; then
  echo "Please run with sudo (e.g., sudo ./install_kasm_wsl2.sh)"
  exit 1
fi

# Update and install prerequisites
echo "Updating system and installing prerequisites..."
apt-get update -y
apt-get install -y curl ca-certificates gnupg lsb-release

# # Install Docker if not already present
# if ! command -v docker &> /dev/null; then
#   echo "Installing Docker..."
#   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
#   echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
#   apt-get update -y
#   apt-get install -y docker-ce docker-ce-cli containerd.io
# fi

# # Start Docker service
# service docker start || systemctl start docker

# # Verify Docker is running
# if ! docker info &> /dev/null; then
#   echo "Docker failed to start. Check WSL2 configuration."
#   exit 1
# fi

# Set Kasm version
KASM_VERSION="1.16.1.98d6fa"  # Latest as of now; check kasmweb.com for updates

# Download and install Kasm Workspaces
echo "Downloading Kasm Workspaces v${KASM_VERSION}..."
cd /tmp
curl -O https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz
tar -xf kasm_release_${KASM_VERSION}.tar.gz

echo "Installing Kasm Workspaces..."
bash kasm_release/install.sh --accept-warning --non-interactive

# Configure Kasm to bind to all interfaces (needed for WSL2 networking)
sed -i 's/127.0.0.1:443/0.0.0.0:443/' /opt/kasm/current/conf/app/app.conf || true

# Restart Kasm services
echo "Restarting Kasm services..."
/opt/kasm/bin/stop
/opt/kasm/bin/start

# Get WSL2 IP address
WSL_IP=$(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')

echo "Kasm Workspaces installed!"
echo "Access it from Windows at: https://${WSL_IP}"
echo "Default credentials: admin@kasm.local / [check terminal output or reset via CLI]"
echo "Note: Ignore 'localhost' references; use the IP above in your Windows browser."
echo "If you see SSL errors, use http:// temporarily or set up a proper cert."