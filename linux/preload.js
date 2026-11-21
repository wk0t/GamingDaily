// Bridge exposed to the page, the Electron equivalent of AndroidBridge.
// It only provides what the browser cannot do alone: CORS-free network requests,
// the version, opening links and the disk cache.
// (Text-to-speech and sharing fall back to the renderer's web APIs.)
const { ipcRenderer, shell } = require('electron');

function toBase64Utf8(str) {
  return Buffer.from(str, 'utf8').toString('base64');
}

window.AndroidBridge = {
  // Fetches a URL without CORS restrictions, then calls onFetchDone(id, base64)
  fetchUrl: function (url, id) {
    fetch(url).then(function (r) {
      return r.arrayBuffer().then(function (buf) {
        const bytes = Buffer.from(buf);
        // Simple charset detection: HTTP header, else content prologue, else UTF-8
        let charset = '';
        const ct = (r.headers.get('content-type') || '');
        let m = /charset=([\w-]+)/i.exec(ct);
        if (m) charset = m[1];
        if (!charset) {
          const head = bytes.toString('latin1', 0, Math.min(bytes.length, 4096));
          const mm = /(?:charset|encoding)\s*=\s*["']?([\w-]+)/i.exec(head);
          if (mm) charset = mm[1];
        }
        let text;
        try {
          text = new TextDecoder(charset || 'utf-8').decode(bytes);
        } catch (e) {
          text = bytes.toString('utf8');
        }
        if (window.onFetchDone) window.onFetchDone(id, toBase64Utf8(text));
      });
    }).catch(function () {
      if (window.onFetchDone) window.onFetchDone(id, '');
    });
  },
  appVersion: function () {
    try { return ipcRenderer.sendSync('gmd-version'); } catch (e) { return '1.1.0'; }
  },
  // On Linux, "update" opens the release page to download the new AppImage
  openUrl: function (url) { shell.openExternal(url); },
  saveCache: function (data) {
    try { ipcRenderer.send('gmd-save-cache', data); } catch (e) {}
  },
  loadCache: function () {
    try { return ipcRenderer.sendSync('gmd-load-cache') || ''; } catch (e) { return ''; }
  }
};
