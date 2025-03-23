Switching to your Mac is a great move—macOS provides a more straightforward environment for running Docker and Kasm Workspaces compared to WSL2’s quirks. Let’s start fresh and set up Kasm Workspaces on your Mac with a clean, reproducible process. We’ll use Docker (via Docker Desktop) and a simple script, keeping everything portable and committable to a Git repo.

---

### Goal
Install Kasm Workspaces (Community Edition, v1.16.1) on your Mac, running it locally via Docker, and access it in your browser.

---

### Prerequisites
1. **macOS**: Any recent version (e.g., Ventura, Sonoma) should work.
2. **Docker Desktop**:
   - Install it from [docker.com](https://www.docker.com/products/docker-desktop/) if not already present.
   - Launch Docker Desktop and ensure it’s running (check the menu bar icon).
3. **Terminal**: Use Terminal or iTerm2.
4. **Resources**: Allocate at least 4GB RAM and 2 CPUs to Docker (Preferences > Resources in Docker Desktop).

---

### Directory Structure
```bash
mkdir kasm-mac-example
cd kasm-mac-example
mkdir scripts
touch scripts/install_kasm_mac.sh
chmod +x scripts/install_kasm_mac.sh
git init
echo "*.tar.gz" >> .gitignore
```

---

### Step 1: Installation Script
Here’s a script tailored for macOS. It downloads Kasm, installs it, and starts it with Docker.

#### `scripts/install_kasm_mac.sh`
```bash
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

# Download Kasm release
echo "Downloading Kasm v${KASM_VERSION}..."
cd /tmp
curl -O --retry 3 https://kasm-static-content.s3.amazonaws.com/kasm_release_${KASM_VERSION}.tar.gz
tar -xzf kasm_release_${KASM_VERSION}.tar.gz

# Install Kasm
echo "Installing Kasm Workspaces..."
cd kasm_release
bash install.sh --install-profile noninteractive --admin-password "kasmadmin123" --user-password "kasmuser123"

# Get local IP (optional, localhost works on Mac)
LOCAL_IP=$(ifconfig en0 | grep -oP 'inet \K\d+(\.\d+){3}' || echo "localhost")

echo "Kasm installed!"
echo "Access it at: https://${LOCAL_IP}"
echo "Credentials: admin@kasm.local / kasmadmin123"
echo "If SSL errors occur, use http:// temporarily or configure a certificate."
```

---

### Step 2: Run the Setup
1. **Ensure Docker Desktop is Running**:
   - Open Docker Desktop and wait for the “Docker is running” status.

2. **Execute the Script**:
   ```bash
   ./scripts/install_kasm_mac.sh
   ```
   - No `sudo` needed—Docker Desktop on macOS handles permissions via the user’s Docker socket.

3. **What to Expect**:
   - The script checks Docker, downloads the Kasm tarball, extracts it, and runs the installer.
   - The installer pulls Docker images (e.g., `kasmweb/core-ubuntu-focal`) and starts services.
   - It binds to `0.0.0.0:443` by default, accessible via `localhost`.

---

### Step 3: Access Kasm
- **URL**: Open `https://localhost` in your browser (Safari, Chrome, etc.).
  - You’ll likely see an SSL warning (self-signed cert). Accept it or use `http://localhost` temporarily.
- **Login**: Use `admin@kasm.local` with password `kasmadmin123`.
- **Test**: Create a workspace (e.g., Ubuntu Desktop) and launch it.

---

### Step 4: Commit to Git
```bash
git add .
git commit -m "Kasm Workspaces setup for macOS"
# git remote add origin <your-repo-url>
# git push -u origin main
```

---

### Troubleshooting
1. **Docker Not Running**:
   - Ensure Docker Desktop is open. Restart it if needed.
2. **Port Conflict**:
   - If 443 is in use, edit `/opt/kasm/current/conf/app/app.conf` post-install to change `port` (e.g., `8443`), then:
     ```bash
     /opt/kasm/bin/stop
     /opt/kasm/bin/start
     ```
     Access via `https://localhost:8443`.
3. **Download Issues**:
   - If the tarball fails, redownload manually and rerun `bash install.sh ...` from `/tmp/kasm_release/`.
4. **Logs**:
   - Check `/opt/kasm/current/log/` or `/tmp/kasm_install_*.log` for errors.

---

### Why This Should Work Better
- **No WSL2 Quirks**: macOS with Docker Desktop avoids systemd and networking issues.
- **Simpler Docker**: Docker Desktop provides a stable, user-friendly Docker environment.
- **Local Access**: Binding to `localhost` is seamless on Mac.

---

### Next Steps
Run the script and let me know the output! If it succeeds, you’ll have Kasm running smoothly. If any hiccups occur (e.g., port issues, Docker errors), share the details, and I’ll tweak it further. You’re starting fresh on a solid foundation now!