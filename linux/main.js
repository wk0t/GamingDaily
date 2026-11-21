// Main Electron process: window + native services (version, disk cache).
// The window loads renderer/index.html (the same UI as the Android app).
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
      // RSS feeds and the translation service send no CORS headers;
      // as on Android (native bridge), allow these cross-origin requests.
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

// App version (for the update check)
ipcMain.on('gmd-version', (e) => { e.returnValue = app.getVersion(); });

// Offline article cache (same as AndroidBridge.saveCache/loadCache)
const cacheFile = () => path.join(app.getPath('userData'), 'cache.json');
ipcMain.on('gmd-save-cache', (e, data) => {
  try { fs.writeFileSync(cacheFile(), data, 'utf8'); } catch (err) {}
});
ipcMain.on('gmd-load-cache', (e) => {
  try { e.returnValue = fs.readFileSync(cacheFile(), 'utf8'); } catch (err) { e.returnValue = ''; }
});
