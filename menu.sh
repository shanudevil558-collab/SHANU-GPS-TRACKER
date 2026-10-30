#!/data/data/com.termux/files/usr/bin/bash

C='\033[1;36m'
G='\033[1;32m'
P='\033[1;35m'
R='\033[1;31m'
W='\033[1;37m'
X='\033[0m'

cd "$HOME/SHANU-GPS-TRACKER" || exit 1

clear
echo -e "${C}"
echo "╔══════════════════════════════════════╗"
echo "║          SHANU GPS SYSTEM            ║"
echo "╚══════════════════════════════════════╝"
echo -e "${P}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
echo -e "${G} [01]${W} WHATSAPP"
echo -e "${G} [02]${W} YOUTUBE"
echo -e "${G} [03]${W} TIKTOK"
echo -e "${G} [04]${W} INSTAGRAM"
echo -e "${R} [99]${W} EXIT"
echo -e "${P}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

read -rp "Select platform: " choice

case "$choice" in
  1|01) PLATFORM="WhatsApp" ;;
  2|02) PLATFORM="YouTube" ;;
  3|03) PLATFORM="TikTok" ;;
  4|04) PLATFORM="Instagram" ;;
  99) exit 0 ;;
  *) echo "Invalid option"; exit 1 ;;
esac

clear
echo -e "${C}SHANU GPS SYSTEM${X}"
echo -e "${G}Selected demo source: $PLATFORM${X}"
echo
echo "[01] LOCALHOST"
echo "[02] CLOUDFLARE HTTPS"
echo "[99] BACK"

read -rp "Select connection: " connection

case "$connection" in
  1|01) MODE="local" ;;
  2|02) MODE="cloudflare" ;;
  99) exec "$0" ;;
  *) echo "Invalid option"; exit 1 ;;
esac

APP_PID=""
TUNNEL_PID=""

cleanup() {
  [ -n "$TUNNEL_PID" ] && kill "$TUNNEL_PID" 2>/dev/null
  [ -n "$APP_PID" ] && kill "$APP_PID" 2>/dev/null
}

trap cleanup EXIT INT TERM

echo "[+] Starting Flask..."

python app.py > app.log 2>&1 &
APP_PID=$!

READY=0

for i in $(seq 1 20); do
  if curl -fsS http://127.0.0.1:8080/ >/dev/null; then
    READY=1
    break
  fi
  sleep 1
done

if [ "$READY" -ne 1 ]; then
  echo "[!] Flask failed"
  cat app.log
  exit 1
fi

BASE="http://127.0.0.1:8080"

if [ "$MODE" = "cloudflare" ]; then
  echo "[+] Starting Cloudflare..."

  cloudflared tunnel --url "$BASE" > cloudflared.log 2>&1 &
  TUNNEL_PID=$!

  URL=""

  for i in $(seq 1 30); do
    URL=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' cloudflared.log | head -1)
    [ -n "$URL" ] && break
    sleep 1
  done

  if [ -z "$URL" ]; then
    echo "[!] Tunnel failed"
    tail -20 cloudflared.log
    exit 1
  fi
else
  URL="$BASE"
fi

echo
echo -e "${G}========== PUBLIC LINK READY ==========${X}"
echo -e "${C}$URL/?source=$PLATFORM${X}"
echo
echo "SHANU consent page"
echo "Press CTRL+C to stop."

wait "$APP_PID"
