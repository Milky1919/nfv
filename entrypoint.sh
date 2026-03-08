#!/bin/bash
set -e

echo "[Init] System starting..."

# 1. パーミッションの自動リカバリとボリューム準備
mkdir -p /home/sunshine/.config/sunshine || true
mkdir -p /home/sunshine/.config/google-chrome || true
chown -R sunshine:sunshine /home/sunshine/.config || true
chown -R sunshine:sunshine /home/sunshine || true
echo "[Init] Permissions configured for sunshine user."

# 2. udevd起動（inputtinoが作成する仮想入力デバイスの検出に必須）
echo "[Init] Starting udevd..."
/lib/systemd/systemd-udevd --daemon || true
sleep 1
udevadm control --reload-rules || true
udevadm trigger || true
echo "[Init] udevd started."

# 3. /dev/uinput の権限開放（Sunshineの仮想入力デバイス作成に必要）
chmod 666 /dev/uinput || true

# 4. Xorg + dummyドライバー（inputtinoの仮想入力デバイスを認識可能）
echo "[Init] Cleaning up old Xorg locks..."
rm -f /tmp/.X99-lock
rm -rf /tmp/.X11-unix

echo "[Init] Starting Xorg with dummy driver..."
Xorg :99 -config /etc/X11/xorg.conf -ac -noreset -novtswitch -sharevts -keeptty +extension RANDR +extension GLX &
export DISPLAY=:99

echo "[Wait] Waiting for Xorg socket..."
timeout 5 bash -c 'while [ ! -S /tmp/.X11-unix/X99 ]; do sleep 0.1; done' || { echo "Xorg socket timeout"; exit 1; }

# 5. Fluxbox (ウィンドウマネージャー)
echo "[Init] Starting Fluxbox..."
mkdir -p /home/sunshine/.fluxbox

# Fluxbox keybindings
echo "F9 :Exec xdotool key ctrl+alt+shift+d" > /home/sunshine/.fluxbox/keys

# Fluxbox menu for right-click
cat > /home/sunshine/.fluxbox/menu << 'MENU_EOF'
[begin] (Fluxbox)
  [exec] (Google Chrome) {google-chrome --load-extension=/opt/extensions/ublock-origin,/opt/extensions/netflix-1080p,/opt/extensions/auto-skip,/opt/extensions/video-resolution-monitor --window-position=0,0 --window-size=1920,1080 --start-maximized --no-first-run --no-default-browser-check --disable-default-apps --password-store=basic --use-mock-keychain --force-device-scale-factor=1.0 --disable-features=OverlayScrollbar --disable-infobars --disable-gpu-vsync --enable-features=VaapiVideoDecoder --no-sandbox --disable-gpu-sandbox}
  [separator]
  [restart] (Restart)
  [exit] (Exit)
[end]
MENU_EOF

echo "session.screen0.rootCommand: " > /home/sunshine/.fluxbox/init
chown -R sunshine:sunshine /home/sunshine/.fluxbox

# Create Desktop directory and copy Chrome shortcut
mkdir -p /home/sunshine/Desktop
cp /opt/chrome.desktop /home/sunshine/Desktop/chrome.desktop
chown -R sunshine:sunshine /home/sunshine/Desktop
chmod +x /home/sunshine/Desktop/chrome.desktop

# Start Fluxbox
sudo -u sunshine bash -c 'DISPLAY=:99 fluxbox &'

# Start PCManFM in desktop mode to show desktop icons
sudo -u sunshine bash -c 'DISPLAY=:99 pcmanfm --desktop &'

echo "[Wait] Waiting for Fluxbox..."
timeout 3 bash -c 'while ! xdpyinfo -display :99 >/dev/null 2>&1; do sleep 0.1; done' || { echo "Fluxbox timeout"; exit 1; }

# Start Picom Compositor (to prevent screen tearing)
echo "[Init] Starting Picom compositor in background..."
sudo -u sunshine bash -c 'DISPLAY=:99 picom --backend xrender > /tmp/picom.log 2>&1 &' || true

# 6. PulseAudio (仮想オーディオとダミーシンク)
echo "[Init] Starting PulseAudio..."
sudo -u sunshine pulseaudio --start --exit-idle-time=-1
sudo -u sunshine pactl load-module module-null-sink sink_name=DummySink sink_properties=device.description=DummySink
sudo -u sunshine pactl set-default-sink DummySink

echo "[Wait] Waiting for PulseAudio daemon..."
timeout 3 bash -c 'while ! sudo -u sunshine pactl info >/dev/null 2>&1; do sleep 0.1; done' || { echo "PulseAudio timeout"; exit 1; }

# 7. VRAM監視スクリプトのバックグラウンド実行
echo "[Init] Starting VRAM Monitor..."
/usr/local/bin/vram-monitor.sh &

# 8. Sunshineの設定ファイル生成（初回のみ）
SUNSHINE_CONF="/home/sunshine/.config/sunshine/sunshine.conf"
if [ ! -f "$SUNSHINE_CONF" ]; then
  echo "[Init] Creating default sunshine.conf..."
  cat > "$SUNSHINE_CONF" << 'EOF'
origin_web_ui_allowed = wan
EOF
  chown sunshine:sunshine "$SUNSHINE_CONF"
fi

# 9. Sunshine起動（DISPLAY設定はXorgの:99を使用）
echo "[Init] Starting Sunshine Streaming Server..."
sudo -u sunshine bash -c 'DISPLAY=:99 sunshine &'

# Sunshineの初期化待機（API疎通確認やログ待機は暫定でSleep）
sleep 5

# 10. Google Chrome (Xvfbを使用した非Headlessモードによる標準的な拡張機能読み込み)
echo "[Init] Starting Google Chrome directly with --load-extension via Xvfb..."
# 環境変数読み込み
START_URL=${CHROME_START_URL:-"https://www.netflix.com/browse"}

# 必要な全拡張機能のパスをカンマ区切りで作成
EXTENSIONS="/opt/extensions/ublock-origin,/opt/extensions/netflix-1080p,/opt/extensions/auto-skip,/opt/extensions/video-resolution-monitor"

# Chrome起動（既存のXorg :99に直接接続。Sunshineが同じ:99を配信しているため必須）
sudo -u sunshine bash -c "
export DISPLAY=:99
export LIBVA_DRIVER_NAME=nvidia
export VDPAU_DRIVER=nvidia
google-chrome \
  '${START_URL}' \
  --load-extension='${EXTENSIONS}' \
  --window-position=0,0 \
  --window-size=1920,1080 \
  --start-maximized \
  --no-first-run \
  --no-default-browser-check \
  --disable-default-apps \
  --password-store=basic \
  --use-mock-keychain \
  --force-device-scale-factor=1.0 \
  --disable-features=OverlayScrollbar \
  --disable-infobars \
  --disable-gpu-vsync \
  --enable-features=VaapiVideoDecoder \
  --no-sandbox \
  --disable-gpu-sandbox \
  --enable-logging \
  --v=1 &
"
echo "[Init] Chrome started."

echo "[Init] All services verified and dispatched."

# プロセスをホールド（コンテナ終了回避）
wait -n
