// Copie la page web partagée (celle de l'app Android) dans renderer/ avant le build.
// Ainsi il n'y a qu'une seule source de vérité pour l'interface.
const fs = require('fs');
const path = require('path');

const src = path.join(__dirname, '..', 'android', 'assets', 'index.html');
const dstDir = path.join(__dirname, 'renderer');
const dst = path.join(dstDir, 'index.html');

fs.mkdirSync(dstDir, { recursive: true });
fs.copyFileSync(src, dst);
console.log('index.html copié -> renderer/index.html');
