#!/bin/bash
set -e

echo "[Init] System starting..."

# 1. パーミッションの自動リカバリとボリューム準備
mkdir -p /home/sunshine/.config/sunshine || true
mkdir -p /home/sunshine/.config/google-chrome || true
chown -R sunshine:sunshine /home/sunshine || true
echo "[Init] Permissions configured for sunshine user."

# 2. Xorg (headless, dummy driver - uinput入力イベントを受け取れる)
echo "[Init] Starting Xorg (headless dummy)..."
Xorg :99 -config /etc/X11/xorg.conf -nolisten tcp -noreset -ac &
export DISPLAY=:99

echo "[Wait] Waiting for Xorg socket..."
timeout 10 bash -c 'while [ ! -S /tmp/.X11-unix/X99 ]; do sleep 0.1; done' || { echo "Xorg socket timeout"; exit 1; }

# 3. Fluxbox (ウィンドウマネージャー)
echo "[Init] Starting Fluxbox..."
sudo -u sunshine bash -c 'DISPLAY=:99 fluxbox &'

echo "[Wait] Waiting for Fluxbox..."
timeout 3 bash -c 'while ! xdpyinfo -display :99 >/dev/null 2>&1; do sleep 0.1; done' || { echo "Fluxbox timeout"; exit 1; }

# 4. PulseAudio (仮想オーディオとダミーシンク)
echo "[Init] Starting PulseAudio..."
sudo -u sunshine pulseaudio --start --exit-idle-time=-1
sudo -u sunshine pactl load-module module-null-sink sink_name=DummySink sink_properties=device.description=DummySink

echo "[Wait] Waiting for PulseAudio daemon..."
timeout 3 bash -c 'while ! sudo -u sunshine pactl info >/dev/null 2>&1; do sleep 0.1; done' || { echo "PulseAudio timeout"; exit 1; }

# 5. VRAM監視スクリプトのバックグラウンド実行
echo "[Init] Starting VRAM Monitor..."
/usr/local/bin/vram-monitor.sh &

# 6. /dev/uinput の権限開放（Sunshineの仮想入力デバイス作成に必要）
chmod 666 /dev/uinput || true

# 7. Sunshineの設定ファイル生成（初回のみ）
SUNSHINE_CONF="/home/sunshine/.config/sunshine/sunshine.conf"
if [ ! -f "$SUNSHINE_CONF" ]; then
  echo "[Init] Creating default sunshine.conf..."
  cat > "$SUNSHINE_CONF" << 'EOF'
origin_web_ui_allowed = wan
EOF
  chown sunshine:sunshine "$SUNSHINE_CONF"
fi

# 7. Sunshine起動
echo "[Init] Starting Sunshine Streaming Server..."
sudo -u sunshine bash -c 'DISPLAY=:99 PULSE_SERVER=unix:/tmp/pulseaudio.socket sunshine &'

# Sunshineの初期化待機（API疎通確認やログ待機は暫定でSleep）
sleep 5

# 7. Google Chrome (キオスクモード)
echo "[Init] Starting Google Chrome with Extensions and UserAgent..."
# 環境変数読み込み
START_URL=${CHROME_START_URL:-"https://www.netflix.com/browse"}
EXTENSIONS="/opt/extensions/ublock-lite,/opt/extensions/netflix-1080p,/opt/extensions/auto-skip"
CHROME_OS_UA="Mozilla/5.0 (X11; CrOS x86_64 15509.89.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

sudo -u sunshine bash -c "
export DISPLAY=:99
export LIBVA_DRIVER_NAME=nvidia
export VDPAU_DRIVER=nvidia
google-chrome \
  --user-agent='${CHROME_OS_UA}' \
  --kiosk '${START_URL}' \
  --force-device-scale-factor=1.0 \
  --disable-features=OverlayScrollbar \
  --disable-infobars \
  --no-first-run \
  --disable-gpu-vsync \
  --enable-features=VaapiVideoDecoder \
  --load-extension='${EXTENSIONS}' &
"

echo "[Init] All services verified and dispatched."

# プロセスをホールド（コンテナ終了回避）
wait -n
