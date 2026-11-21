// Copies the shared web page (the one from the Android app) into renderer/ before the build.
// That way there is a single source of truth for the UI.
const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'android', 'assets', 'index.html');
const dstDir = path.join(__dirname, 'renderer');
const dst = path.join(dstDir, 'index.html');

fs.mkdirSync(dstDir, { recursive: true });
fs.copyFileSync(src, dst);
console.log('index.html copied -> renderer/index.html');
// The page loads its fonts from ./fonts, so ship them next to it too.
const fontsSrc = path.join(__dirname, '..', 'android', 'assets', 'fonts');
const fontsDst = path.join(dstDir, 'fonts');
if (fs.existsSync(fontsSrc)) {
  fs.rmSync(fontsDst, { recursive: true, force: true });
  fs.cpSync(fontsSrc, fontsDst, { recursive: true });
  console.log('fonts copied -> renderer/fonts');
}
