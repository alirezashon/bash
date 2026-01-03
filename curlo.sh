#!/usr/bin/env bash
# Nikigram Admin – Local Networking Lab

set -uo pipefail

show_section() {
  echo -e "\n=== $1 ==="
}

show_section "1) curl + User-Agent (-A)"
curl -A "Nikigram-Agent/1.0" http://localhost:3000

show_section "2) HTTP headers"
curl -i http://localhost:3000

show_section "3) WebSocket (curl handshake)"
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: SGVsbG8=" \
  http://localhost:3000

show_section "4) WebSocket real (websocat)"
echo "salam ws" | websocat ws://localhost:3001

show_section "5) TCP via nc"
echo "salam tcp" | nc localhost 9000

show_section "6) TCP via Bash /dev/tcp"
exec 3<>/dev/tcp/127.0.0.1/9000
echo "salam bash tcp" >&3
cat <&3
exec 3>&-

show_section "7) Fake browser"
curl -A "Mozilla/5.0 Chrome/120" http://localhost:3000