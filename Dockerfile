FROM ghcr.io/lizardbyte/sunshine:latest

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

USER root

# 非特権ユーザーの作成とグループ所属
RUN groupadd -f render && \
    useradd -m -s /bin/bash sunshine && \
    usermod -aG video,audio,render sunshine

# 依存パッケージおよびツール群のインストール
RUN apt-get update && apt-get install -y \
    xvfb fluxbox pulseaudio wget curl unzip git inotify-tools psmisc \
    x11-utils jq ca-certificates sudo arping nano gnupg binutils \
    libva2 libva-drm2 libva-x11-2 libvdpau1 libnuma1 \
    && rm -rf /var/lib/apt/lists/*

# Google Chromeのインストール
RUN mkdir -p /etc/apt/keyrings && \
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && apt-get install -y google-chrome-stable && \
    rm -rf /var/lib/apt/lists/*

# sudoのパスワードなし実行を許可（起動スクリプト内での権限切り替え用）
RUN echo "sunshine ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Widevine L3 DRMモジュールの抽出と配置（公式debから展開）
RUN wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    ar x google-chrome-stable_current_amd64.deb && \
    tar -xf data.tar.xz && \
    mkdir -p /opt/google/chrome/WidevineCdm && \
    cp -r opt/google/chrome/WidevineCdm/* /opt/google/chrome/WidevineCdm/ || true && \
    rm -rf google-chrome-stable_current_amd64.deb data.tar.xz control.tar.xz debian-binary opt etc

# Chrome拡張機能の配置ディレクトリ作成
RUN mkdir -p /opt/extensions

# Extensions 1: Netflix-1080p (truedread版)
RUN wget -q https://github.com/truedread/netflix-1080p/archive/refs/tags/v1.22.zip -O netflix-1080p.zip && \
    unzip -q netflix-1080p.zip && \
    mv netflix-1080p-1.22 /opt/extensions/netflix-1080p && \
    rm netflix-1080p.zip

# Extensions 2: Netflix-Prime-Auto-Skip (広告・イントロスキップ)
RUN git clone https://github.com/Dreamlinerm/Netflix-Prime-Auto-Skip.git /opt/extensions/auto-skip

# Extensions 3: uBlock Origin Lite (YouTube等向け広告ブロック MV3)
RUN curl -s https://api.github.com/repos/uBlockOrigin/uBOL-home/releases/latest | jq -r '.assets[] | select(.name | endswith("chromium.zip")) | .browser_download_url' | xargs wget -q -O uBOLite.chromium.zip && \
    unzip -q uBOLite.chromium.zip -d /opt/extensions/ublock-lite && \
    rm uBOLite.chromium.zip

# スクリプトのコピーと権限付与
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY vram-monitor.sh /usr/local/bin/vram-monitor.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh /usr/local/bin/vram-monitor.sh && \
    chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/vram-monitor.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
