// Pont exposé à la page, équivalent Electron de AndroidBridge.
// On ne fournit QUE ce que le navigateur ne sait pas faire seul : les requêtes
// réseau sans CORS, la version, l'ouverture de liens et le cache disque.
// (La synthèse vocale et le partage retombent sur les API web du renderer.)
const { ipcRenderer, shell } = require('electron');

function toBase64Utf8(str) {
  return Buffer.from(str, 'utf8').toString('base64');
}

window.AndroidBridge = {
  // Récupère une URL sans restriction CORS puis rappelle onFetchDone(id, base64)
  fetchUrl: function (url, id) {
    fetch(url).then(function (r) {
      return r.arrayBuffer().then(function (buf) {
        const bytes = Buffer.from(buf);
        // Détection simple du charset : en-tête HTTP, sinon prologue du contenu, sinon UTF-8
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
    try { return ipcRenderer.sendSync('gmd-version'); } catch (e) { return '1.0.0'; }
  },
  // Sur Linux, « mettre à jour » ouvre la page de release pour télécharger la nouvelle AppImage
  openUrl: function (url) { shell.openExternal(url); },
  saveCache: function (data) {
    try { ipcRenderer.send('gmd-save-cache', data); } catch (e) {}
  },
  loadCache: function () {
    try { return ipcRenderer.sendSync('gmd-load-cache') || ''; } catch (e) { return ''; }
  }
};
