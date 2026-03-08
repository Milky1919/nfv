(function () {
    const OVERLAY_ID = 'nfv-video-res-overlay';
    let hideTimeout = null;

    function createOverlay() {
        let overlay = document.getElementById(OVERLAY_ID);
        if (!overlay) {
            overlay = document.createElement('div');
            overlay.id = OVERLAY_ID;
            overlay.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 6px 12px;
        background: rgba(0, 0, 0, 0.7);
        color: white;
        font-family: sans-serif;
        font-size: 16px;
        font-weight: bold;
        border-radius: 4px;
        z-index: 2147483647;
        pointer-events: none;
        transition: opacity 0.3s ease;
        opacity: 0;
        text-shadow: 1px 1px 2px #000;
        border: 1px solid rgba(255, 255, 255, 0.2);
      `;
            document.body.appendChild(overlay);
        }
        return overlay;
    }

    function getVideoNode() {
        const vids = document.getElementsByTagName('video');
        for (const v of vids) {
            if (!v.paused && v.videoWidth > 0) return v;
        }
        return vids.length ? vids[0] : null;
    }

    function showOverlay() {
        const video = getVideoNode();
        if (!video) return;

        const overlay = createOverlay();
        const w = video.videoWidth;
        const h = video.videoHeight;

        if (w > 0 && h > 0) {
            overlay.textContent = `📺 ${w}x${h}p`;
        } else {
            overlay.textContent = `📺 Loading...`;
        }

        overlay.style.opacity = '1';

        clearTimeout(hideTimeout);
        // Standard video UIs typically fade out after ~3 seconds of inactivity
        hideTimeout = setTimeout(() => {
            overlay.style.opacity = '0';
        }, 3000);
    }

    // Bind to common interactions that trigger standard video UI to appear
    document.addEventListener('click', showOverlay);
    document.addEventListener('mousemove', showOverlay);
    document.addEventListener('keydown', showOverlay);

    // Periodically update the resolution while the overlay is visible
    setInterval(() => {
        const overlay = document.getElementById(OVERLAY_ID);
        if (overlay && overlay.style.opacity === '1') {
            const video = getVideoNode();
            if (video && video.videoWidth > 0) {
                overlay.textContent = `📺 ${video.videoWidth}x${video.videoHeight}p`;
            }
        }
    }, 1000);
})();
