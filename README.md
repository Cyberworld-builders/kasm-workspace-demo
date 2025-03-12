# kasm-workspace-demo
Experimenting with Kasm Workspace Streaming Platform


> Yes, you can absolutely test Kasm Workspaces on-premise using Windows 11 with WSL2 and an Ubuntu VM! WSL2 provides a lightweight Linux environment that supports Docker, which is perfect for running Kasm. I’ll walk you through setting it up entirely within your Ubuntu WSL2 instance, keeping it simple and portable. We’ll skip Terraform since this is local, and focus on scripting within WSL2.

---

### Prerequisites
1. **Windows 11 with WSL2 Installed**:
   - Ensure WSL2 is set up (`wsl --install` if not already done).
   - Install Ubuntu (e.g., Ubuntu 22.04) via `wsl --install -d Ubuntu-22.04` or from the Microsoft Store.
2. **Ubuntu Running in WSL2**:
   - Open a terminal and run `wsl -d Ubuntu-22.04` (or your distro name).
3. **Sufficient Resources**:
   - WSL2 defaults to half your system’s RAM and CPU cores. For Kasm, aim for at least 4GB RAM and 2 vCPUs. Adjust in `C:\Users\<YourUser>\.wslconfig` if needed:
     ```
     [wsl2]
     memory=4GB
     processors=2
     ```
   - Restart WSL after changes: `wsl --shutdown`.

---

### Directory Structure (in WSL2)
From your Ubuntu terminal:
```bash
mkdir kasm-wsl2-example
cd kasm-wsl2-example
mkdir scripts
touch scripts/install_kasm_wsl2.sh
chmod +x scripts/install_kasm_wsl2.sh
```

---

### Step 1: Installation Script for WSL2
Here’s a tailored script to set up Kasm Workspaces in your WSL2 Ubuntu instance. It installs Docker, configures it, and deploys Kasm.

#### `scripts/install_kasm_wsl2.sh`
```bash
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

# Install Docker if not already present
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io
fi

# Start Docker service
service docker start || systemctl start docker

# Verify Docker is running
if ! docker info &> /dev/null; then
  echo "Docker failed to start. Check WSL2 configuration."
  exit 1
fi

# Set Kasm version
KASM_VERSION="1.15.0.06f00e"  # Latest as of now; check kasmweb.com for updates

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
```

> **Note:** *Make sure you make the script executable.*

```sh
sudo chmod +x scripts/install_kasm_wsl2.sh
```

---

### Step 2: Run the Setup
1. **Open Ubuntu in WSL2**:
   ```powershell
   wsl -d Ubuntu-22.04
   ```
2. **Navigate to Directory**:
   ```bash
   cd ~/kasm-wsl2-example
   ```
3. **Execute the Script**:
   ```bash
   sudo ./scripts/install_kasm_wsl2.sh
   ```
   - This installs Docker, downloads Kasm, and configures it. It may take a few minutes.

---

### Step 3: Access Kasm from Windows
- **Find the IP**: The script outputs your WSL2 IP (e.g., `172.XX.XX.XX`). Note this down.
- **Open a Browser**: On Windows, use Chrome/Edge/Firefox and go to `https://<WSL_IP>`.
  - You’ll likely get an SSL warning (self-signed cert). Accept it or use `http://<WSL_IP>` temporarily.
- **Login**: Use `admin@kasm.local` and the password shown in the terminal (or reset it via `/opt/kasm/bin/utils/reset_admin_password`).

---

### Step 4: Test a Workspace
- After logging in, create a new workspace (e.g., Ubuntu Desktop).
- Launch it from the Kasm UI. It’ll open in a new browser tab within your WSL2 instance.

---

### Troubleshooting
1. **Docker Not Starting**:
   - Ensure WSL2 integration is enabled: In Docker Desktop (if installed), go to Settings > Resources > WSL Integration, and enable it for your Ubuntu distro.
   - Or rely solely on the script’s Docker install (skip Docker Desktop).
2. **Port Conflict**:
   - If 443 is in use, edit `/opt/kasm/current/conf/app/app.conf` to change the port (e.g., `0.0.0.0:8443`), then restart Kasm (`/opt/kasm/bin/stop && /opt/kasm/bin/start`).
3. **Networking**:
   - WSL2 IPs change on reboot. Rerun `ip addr show eth0` to get the new IP, or set up port forwarding (below).

---

### Optional: Port Forwarding (Static Access)
To avoid IP changes:
1. **In Windows PowerShell (Admin)**:
   ```powershell
   netsh interface portproxy add v4tov4 listenport=443 listenaddress=0.0.0.0 connectport=443 connectaddress=<WSL_IP>
   ```
2. **Access**: Use `https://localhost` from Windows instead of the WSL IP.
3. **Automate**: Add a script to update this on WSL restart (WSL IPs are dynamic).

---

### Step 5: Commit to Git
```bash
git init
echo "*.tar.gz" >> .gitignore
git add .
git commit -m "Kasm Workspaces setup for WSL2 on Windows 11"
# Push to your repo if desired
```

---

### Notes
- **Performance**: WSL2 should handle Kasm well with 4GB RAM and 2 vCPUs. For heavier workloads, increase resources in `.wslconfig`.
- **Persistence**: WSL2 persists data unless you reset the distro. Configs are in `/opt/kasm/`.
- **Portability**: This script works on any Ubuntu 20.04/22.04 system (WSL2 or not), making it reusable.

You’re now running Kasm Workspaces on-prem within WSL2! Let me know if you hit any snags or want to tweak it further.