FROM ghcr.io/lizardbyte/sunshine:latest-ubuntu-24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

USER root

# 非特権ユーザーの作成とグループ所属
RUN groupadd -f render && \
    groupadd -f input && \
    useradd -m -s /bin/bash sunshine && \
    usermod -aG video,audio,render,input sunshine

# 依存パッケージおよびツール群のインストール
RUN set -x && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    xserver-xorg-core xserver-xorg-video-dummy xserver-xorg-video-nvidia-525 xserver-xorg-input-libinput \
    udev fluxbox pulseaudio wget curl unzip git inotify-tools psmisc \
    x11-utils mesa-utils jq ca-certificates sudo arping nano gnupg binutils xvfb python3 \
    libva2 libva-drm2 libva-x11-2 libvdpau1 libnuma1 fonts-noto-cjk xdotool feh \
    pcmanfm picom nvidia-utils-525 libnvidia-gl-525 || true && \
    dpkg --configure -a || true && \
    which Xorg udevadm fluxbox pulseaudio && \
    echo "Package installation completed - binaries verified" && \
    rm -rf /var/lib/apt/lists/*

# Google Chromeのインストール
RUN mkdir -p /etc/apt/keyrings && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable || true && \
    dpkg --configure -a || true && \
    which google-chrome && \
    rm -rf /var/lib/apt/lists/*

# (Old Enterprise Policy config removed as we no longer use it)

# sudoのパスワードなし実行を許可（起動スクリプト内での権限切り替え用）
RUN echo "sunshine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Xorg設定の配置とXwrapper許可（非rootユーザーでXorg起動可能にする）
COPY xorg.conf /etc/X11/xorg.conf
RUN mkdir -p /etc/X11 && echo "allowed_users = anybody" > /etc/X11/Xwrapper.config

# Picom設定ファイルの配置
COPY picom.conf /etc/picom.conf

# udevルール（inputtinoが作成する仮想入力デバイスの権限設定）
RUN echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess", GROUP="input", MODE="0660"' \
    > /etc/udev/rules.d/60-sunshine.rules



# Chrome拡張機能の配置ディレクトリ作成
RUN mkdir -p /opt/extensions

# Extensions 1: Netflix-1080p (Puyodead1 fork - Enables 1080p and explicitly unblocks debug shortcuts)
RUN wget -q https://github.com/Puyodead1/wv-netflix-extension/archive/refs/heads/master.zip -O netflix-1080p.zip && \
    unzip -q netflix-1080p.zip && \
    mv wv-netflix-extension-master /opt/extensions/netflix-1080p && \
    rm netflix-1080p.zip || true

# Extensions 2: Netflix-Prime-Auto-Skip (広告・イントロスキップ)
RUN git clone https://github.com/Dreamlinerm/Netflix-Prime-Auto-Skip.git /opt/extensions/auto-skip

# Extensions 3: uBlock Origin (Full MV2 version for advanced blocking)
RUN curl -s https://api.github.com/repos/gorhill/uBlock/releases/latest | jq -r '.assets[] | select(.name | endswith("chromium.zip")) | .browser_download_url' > /tmp/ublock_url.txt && \
    wget -q -i /tmp/ublock_url.txt -O uBlock0.chromium.zip && \
    unzip -q uBlock0.chromium.zip -d /opt/extensions/ublock-origin && \
    rm uBlock0.chromium.zip /tmp/ublock_url.txt
# Extensions 4: Video Resolution Monitor (custom extension for UI)
COPY video-resolution-monitor /opt/extensions/video-resolution-monitor
# (CRX packaging step removed as we use --load-extension instead)
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY vram-monitor.sh /usr/local/bin/vram-monitor.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh /usr/local/bin/vram-monitor.sh && \
    chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/vram-monitor.sh

# Desktop shortcut for Chrome
COPY chrome.desktop /opt/chrome.desktop
RUN chmod +x /opt/chrome.desktop

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
