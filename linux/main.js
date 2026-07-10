// Processus principal Electron : fenêtre + services natifs (version, cache disque).
// La fenêtre charge renderer/index.html (la même interface que l'app Android).
const { app, BrowserWindow, ipcMain } = require('electron');
const path = require('path');
const fs = require('fs');

function createWindow() {
  const win = new BrowserWindow({
    width: 1180,
    height: 840,
    minWidth: 380,
    backgroundColor: '#0d0a16',
    autoHideMenuBar: true,
    title: 'Gaming Daily',
    icon: path.join(__dirname, 'build', 'icon.png'),
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: false,
      nodeIntegration: false,
      sandbox: false,
      // Les flux RSS et le service de traduction n'envoient pas d'en-têtes CORS ;
      // comme sur Android (pont natif), on autorise ces requêtes cross-origin.
      webSecurity: false
    }
  });
  win.setMenuBarVisibility(false);
  win.loadFile(path.join(__dirname, 'renderer', 'index.html'));
}

app.whenReady().then(createWindow);

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});

// Version de l'appli (pour la vérification des mises à jour)
ipcMain.on('gmd-version', (e) => { e.returnValue = app.getVersion(); });

// Cache hors-ligne des articles (comme AndroidBridge.saveCache/loadCache)
const cacheFile = () => path.join(app.getPath('userData'), 'cache.json');
ipcMain.on('gmd-save-cache', (e, data) => {
  try { fs.writeFileSync(cacheFile(), data, 'utf8'); } catch (err) {}
});
ipcMain.on('gmd-load-cache', (e) => {
  try { e.returnValue = fs.readFileSync(cacheFile(), 'utf8'); } catch (err) { e.returnValue = ''; }
});
