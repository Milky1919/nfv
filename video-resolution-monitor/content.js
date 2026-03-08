(function () {
    const OVERLAY_ID = 'nfv-video-res-overlay';
    let overlayContainer = null;
    let resText = null;
    let resButton = null;

    function getVideoNode() {
        const vids = document.getElementsByTagName('video');
        for (const v of vids) {
            if (v.videoWidth > 0) return v;
        }
        return vids.length ? vids[0] : null;
    }

    function initOverlay() {
        if (document.getElementById(OVERLAY_ID)) return;

        overlayContainer = document.createElement('div');
        overlayContainer.id = OVERLAY_ID;
        overlayContainer.style.cssText = `
      position: absolute;
      top: 40px;
      right: 40px;
      z-index: 2147483647;
      display: flex;
      align-items: center;
      gap: 15px;
      transition: opacity 0.3s ease;
      opacity: 0;
      pointer-events: none;
    `;

        resText = document.createElement('div');
        resText.style.cssText = `
      background: rgba(0, 0, 0, 0.85);
      color: #fff;
      padding: 10px 16px;
      border-radius: 8px;
      font-family: Arial, sans-serif;
      font-size: 22px;
      font-weight: bold;
      border: 1px solid rgba(255,255,255,0.3);
      box-shadow: 0 4px 6px rgba(0,0,0,0.5);
      display: none;
      pointer-events: none;
    `;

        resButton = document.createElement('button');
        resButton.textContent = 'ℹ️';
        resButton.style.cssText = `
      background: rgba(0, 0, 0, 0.6);
      border: 2px solid rgba(255, 255, 255, 0.6);
      border-radius: 50%;
      color: white;
      font-size: 24px;
      width: 50px;
      height: 50px;
      cursor: pointer;
      pointer-events: auto;
      display: flex;
      justify-content: center;
      align-items: center;
      box-shadow: 0 4px 6px rgba(0,0,0,0.5);
      transition: transform 0.1s;
    `;

        resButton.onmousedown = () => resButton.style.transform = 'scale(0.9)';
        resButton.onmouseup = () => resButton.style.transform = 'scale(1)';
        resButton.onmouseleave = () => resButton.style.transform = 'scale(1)';

        overlayContainer.appendChild(resText);
        overlayContainer.appendChild(resButton);

        const target = document.fullscreenElement || document.body;
        if (target) {
            target.appendChild(overlayContainer);
        }

        resButton.addEventListener('click', (e) => {
            e.stopPropagation();
            e.preventDefault();
            const video = getVideoNode();
            if (video && video.videoWidth > 0) {
                resText.textContent = \`📺 \${video.videoWidth} x \${video.videoHeight}p\`;
      } else {
        resText.textContent = \`📺 Loading...\`;
      }
      resText.style.display = 'block';
      
      setTimeout(() => {
        resText.style.display = 'none';
      }, 4000);
    }, true);
  }

  // Handle fullscreen changes
  document.addEventListener('fullscreenchange', () => {
    if (overlayContainer) {
      const target = document.fullscreenElement || document.body;
      if (target && overlayContainer.parentNode !== target) {
        target.appendChild(overlayContainer);
      }
    }
  });

  // Main logic
  setInterval(() => {
    initOverlay();
    if (!overlayContainer) return;
    
    const video = getVideoNode();
    if (!video) {
        overlayContainer.style.opacity = '0';
        resButton.style.pointerEvents = 'none';
        return;
    }

    let isUiActive = false;
    let cursorIsNone = false;
    
    if (video.paused) {
        isUiActive = true;
    } else {
        let el = video;
        while(el && el !== document) {
            const style = window.getComputedStyle(el);
            if (style.cursor === 'none') {
                cursorIsNone = true;
                break;
            }
            if (el.className && typeof el.className === 'string' && el.className.includes('inactive')) {
                cursorIsNone = true;
                break;
            }
            el = el.parentNode;
        }

        if (document.body.className && typeof document.body.className === 'string' && 
            (document.body.className.includes('inactive') || document.body.className.includes('hide-cursor'))) {
            cursorIsNone = true;
        }

        isUiActive = !cursorIsNone;
    }

    if (isUiActive) {
        overlayContainer.style.opacity = '1';
        resButton.style.pointerEvents = 'auto';
    } else {
        overlayContainer.style.opacity = '0';
        resButton.style.pointerEvents = 'none';
        resText.style.display = 'none';
    }
  }, 500);

})();
