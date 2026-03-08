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

    // We create the overlay container and append it directly to the document element
    // to ensure it is above everything else, even in fullscreen
    overlayContainer = document.createElement('div');
    overlayContainer.id = OVERLAY_ID;
    overlayContainer.style.cssText = `
      position: fixed;
      top: 40px;
      right: 40px;
      z-index: 2147483647;
      display: flex;
      align-items: center;
      gap: 15px;
      transition: opacity 0.3s ease;
      opacity: 1; /* Default to visible for debugging */
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

    // Append to documentElement for maximum z-index priority
    document.documentElement.appendChild(overlayContainer);

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

  // Handle fullscreen changes by moving the overlay to the fullscreen element
  document.addEventListener('fullscreenchange', () => {
    if (overlayContainer) {
      const target = document.fullscreenElement || document.documentElement;
      if (target && overlayContainer.parentNode !== target) {
        target.appendChild(overlayContainer);
      }
    }
  });

  // Inject early and update iteratively
  initOverlay();

  setInterval(() => {
    initOverlay();
    if (!overlayContainer) return;
    
    // Ensure it's always appended to the right target (fullscreen or document)
    const currentTarget = document.fullscreenElement || document.documentElement;
    if (overlayContainer.parentNode !== currentTarget) {
      currentTarget.appendChild(overlayContainer);
    }

    const video = getVideoNode();
    if (!video) {
        // If no video, make sure button is hidden
        overlayContainer.style.opacity = '0';
        overlayContainer.style.pointerEvents = 'none';
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

        // Often elements have aria-hidden true when UI is inactive
        if (document.querySelector('.controls-inactive, .vjs-user-inactive, .ytp-autohide')) {
          cursorIsNone = true;
        }

        isUiActive = !cursorIsNone;
    }

    if (isUiActive) {
        overlayContainer.style.opacity = '1';
        overlayContainer.style.pointerEvents = 'auto';
    } else {
        overlayContainer.style.opacity = '0';
        overlayContainer.style.pointerEvents = 'none';
        resText.style.display = 'none';
    }
  }, 500);

})();
