#!/bin/bash

# --- CONFIGURATION ---
# Change this to your OPNsense IP
PROXY_URL="http://IP_GATEWAY_DMZ:3128"
NO_PROXY="localhost,127.0.0.1,localaddress,.kantor.id"

echo "--- Starting Proxy Configuration ---"
echo ""

# 1. Setup /etc/environment
echo "---"
echo "1. Setup /etc/environment"
echo "---"
if ! grep -q "http_proxy" /etc/environment; then
    echo "Add environment proxy /etc/environment"
    sudo bash -c "cat >> /etc/environment" <<EOF
http_proxy="$PROXY_URL"
https_proxy="$PROXY_URL"
no_proxy="$NO_PROXY"
EOF
else
    echo "already setup /etc/environment"
fi

# 2. Setup APT (Package Manager)
echo ""
echo "---"
echo "2. Setup APT Package Manager"
echo "---"
if [ ! -f "/etc/apt/apt.conf.d/99proxy" ]; then
    echo "Creating /etc/apt/apt.conf.d/99proxy"
    sudo bash -c "cat > /etc/apt/apt.conf.d/99proxy" <<EOF
Acquire::http::Proxy "$PROXY_URL";
Acquire::https::Proxy "$PROXY_URL";
EOF
else
    echo "already setup /etc/apt/apt.conf.d/99proxy"
fi

# 3. Setup Docker (Only if installed)
echo ""
echo "---"
echo "3. Setup Docker if installed"
echo "---"
if command -v docker &> /dev/null; then
    echo "Docker detected! Configuring Docker Proxy..."
    sudo mkdir -p /etc/systemd/system/docker.service.d
    
    sudo bash -c "cat > /etc/systemd/system/docker.service.d/http-proxy.conf" <<EOF
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
Environment="NO_PROXY=$NO_PROXY"
EOF

    sudo systemctl daemon-reload
    sudo systemctl restart docker
    echo "Docker proxy configured and service restarted."
else
    echo "Docker not found, skipping."
fi

echo "Done! Please restart your terminal or run 'source /etc/environment'"
echo ""
echo "--- Configuration Complete ---"