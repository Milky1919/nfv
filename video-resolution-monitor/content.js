(function () {
  console.log("[VideoRes] Script loaded heavily on " + window.location.href);
  const OVERLAY_ID = 'nfv-video-res-overlay';
  let hostDiv = null;
  let shadowRoot = null;
  let uiContainer = null;
  let resText = null;
  let resBtn = null;
  let hideTimer = null;

  function getVideo() {
    const vids = document.getElementsByTagName('video');
    for (const v of vids) {
      if (v.videoWidth > 0) return v;
    }
    return vids.length ? vids[0] : null;
  }

  function mountOverlay() {
    if (!hostDiv) {
      hostDiv = document.createElement('div');
      hostDiv.id = OVERLAY_ID;
      hostDiv.style.cssText = `
        position: fixed; top: 0; left: 0; width: 100%; height: 100%;
        pointer-events: none; z-index: 2147483647;
      `;
      shadowRoot = hostDiv.attachShadow({ mode: 'open' });

      uiContainer = document.createElement('div');
      uiContainer.style.cssText = `
        position: absolute; top: 40px; right: 40px;
        display: flex; align-items: center; gap: 15px;
        transition: opacity 0.3s ease; opacity: 0;
        pointer-events: auto;
      `;

      resText = document.createElement('div');
      resText.style.cssText = `
        background: rgba(0,0,0,0.85); color: #fff; padding: 10px 16px;
        border-radius: 8px; font-family: sans-serif; font-size: 22px; font-weight: bold;
        border: 1px solid rgba(255,255,255,0.3); display: none;
        pointer-events: none; white-space: nowrap; box-shadow: 0 4px 6px rgba(0,0,0,0.5);
      `;

      resBtn = document.createElement('button');
      resBtn.textContent = 'ℹ️';
      resBtn.style.cssText = `
        background: rgba(0,0,0,0.6); border: 2px solid rgba(255,255,255,0.6);
        border-radius: 50%; color: white; font-size: 24px;
        width: 50px; height: 50px; cursor: pointer; pointer-events: auto;
        display: flex; justify-content: center; align-items: center;
        box-shadow: 0 4px 6px rgba(0,0,0,0.5); transition: transform 0.1s;
      `;
      resBtn.onmousedown = () => resBtn.style.transform = 'scale(0.9)';
      resBtn.onmouseup = () => resBtn.style.transform = 'scale(1)';
      resBtn.onmouseleave = () => resBtn.style.transform = 'scale(1)';

      resBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        e.preventDefault();
        const v = getVideo();
        if (v && v.videoWidth > 0) {
          resText.textContent = \`📺 \${v.videoWidth} x \${v.videoHeight}p\`;
        } else {
          resText.textContent = \`📺 Loading...\`;
        }
        resText.style.display = 'block';
        setTimeout(() => { resText.style.display = 'none'; }, 4000);
      });

      uiContainer.appendChild(resText);
      uiContainer.appendChild(resBtn);
      shadowRoot.appendChild(uiContainer);
    }

    const target = document.fullscreenElement || document.documentElement;
    if (target && hostDiv.parentNode !== target) {
      target.appendChild(hostDiv);
    }
  }

  function wakeUpUi() {
    if (!uiContainer) return;
    const v = getVideo();
    if (!v) return;

    uiContainer.style.opacity = '1';
    uiContainer.style.pointerEvents = 'auto';
    clearTimeout(hideTimer);
    hideTimer = setTimeout(() => {
      uiContainer.style.opacity = '0';
      uiContainer.style.pointerEvents = 'none';
      if(resText) resText.style.display = 'none';
    }, 3500);
  }

  setInterval(() => {
    const v = getVideo();
    if (v) mountOverlay();
  }, 1000);

  window.addEventListener('mousemove', wakeUpUi, true);
  window.addEventListener('mousedown', wakeUpUi, true);
  window.addEventListener('keydown', wakeUpUi, true);
  document.addEventListener('fullscreenchange', () => { mountOverlay(); wakeUpUi(); }, true);

})();
