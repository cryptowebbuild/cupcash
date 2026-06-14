#!/bin/bash
# CupCash v3.0 — One-Click Deploy from GitHub
# Run on VPS: curl -s https://raw.githubusercontent.com/cryptowebbuild/cupcash/main/deploy_cupcash.sh | bash

set -e
echo "🏆 CupCash v3.0 Deploy..."
pip3 install flask requests 2>/dev/null
mkdir -p /root/cupcash/{static/{css,js,img},templates,data}
cd /root/cupcash
pkill -f "python3 server.py" 2>/dev/null || true
sleep 1

# Download latest files
curl -s https://raw.githubusercontent.com/cryptowebbuild/cupcash/main/server.py > server.py
curl -s https://raw.githubusercontent.com/cryptowebbuild/cupcash/main/templates/index.html > templates/index.html
chmod +x server.py

# Start
nohup python3 server.py > /tmp/cupcash.log 2>&1 &
sleep 3

# Test
echo "--- Testing ---"
curl -s http://localhost:5500/api/stats | head -100
echo ""
echo "✅ CupCash v3.0 deployed!"
echo "🌐 http://$(curl -s ifconfig.me):5500/"
