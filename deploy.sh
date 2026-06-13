#!/bin/bash
# CupCash Deploy Script — Run this on VPS (37.60.252.51)
# ssh root@37.60.252.51 'bash -s' < deploy.sh

set -e

echo "🏆 CupCash Deploy Starting..."

# 1. Install dependencies
pip3 install flask requests 2>/dev/null

# 2. Create project
mkdir -p /root/cupcash/{static/{css,js},templates,data}
cd /root/cupcash

# 3. Kill old process
pkill -f "python3 server.py" 2>/dev/null || true
sleep 1

# 4. Start server
nohup python3 server.py > /tmp/cupcash.log 2>&1 &
sleep 3

# 5. Test
echo "--- Testing ---"
curl -s http://localhost:5500/api/stats | python3 -m json.tool
curl -s http://localhost:5500/api/matches | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'Matches: {len(d[\"matches\"])}')"

echo ""
echo "✅ CupCash deployed on port 5500!"
echo "📊 Stats: http://localhost:5500/api/stats"
echo "⚽ Matches: http://localhost:5500/api/matches"
echo "🌐 App: http://localhost:5500/"
