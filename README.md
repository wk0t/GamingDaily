# Gaming Daily

Un magazine quotidien 100 % jeu vidéo : actu, consoles, PC, modding et rétro, esport. Sur Windows, Android, Linux et iPhone.

L'appli va chercher les articles chez 29 médias (français et anglais) via leurs flux RSS publics, enlève les pubs, traduit l'anglais en français et affiche chaque article en entier, directement dans l'appli. Pas de compte, pas de pub, pas de serveur.

![Gaming Daily, thème sombre](docs/screenshot.png)

Thème clair : [docs/screenshot-light.png](docs/screenshot-light.png). Les captures utilisent des articles d'exemple.

## Fonctionnalités

- Lecture intégrée : l'article complet est extrait de sa page d'origine et remis en forme, avec un lien vers la source.
- Traduction automatique des sources anglophones.
- Cinq rubriques : Actu, Consoles, PC, Modding et rétro, Esport.
- Recherche, favoris disponibles hors ligne, articles lus grisés, temps de lecture estimé.
- Sujets suivis : les articles concernés remontent en haut et sont surlignés.
- Regroupement des doublons entre médias.
- Hype du jour : repère les grosses annonces (Nintendo Direct, State of Play, rachats, reports, leaks).
- Résumé en quelques lignes en tête d'article, glossaire au toucher, quiz du jour.
- Mode podcast et lecture à voix haute.
- Archives des 7 derniers jours, thème clair et sombre.
- Mise à jour signalée par une bannière quand une nouvelle version sort.

## Installer

Tous les fichiers sont dans la [dernière release](https://github.com/wk0t/GamingDaily/releases/latest).

**Windows.** Lance `GamingDaily.exe` : le magazine du jour s'ouvre dans le navigateur. SmartScreen peut prévenir parce que l'exécutable n'est pas signé (Informations complémentaires, puis Exécuter quand même). Pour l'ouvrir chaque matin à 8 h, lance `Activer_ouverture_auto.ps1`.

**Android.** Télécharge `GamingDaily.apk`, ouvre-le et autorise l'installation depuis cette source. Android 7.0 ou plus récent.

**Linux.** Télécharge `GamingDaily-x86_64.AppImage`, puis :

```bash
chmod +x GamingDaily-x86_64.AppImage
./GamingDaily-x86_64.AppImage
```

**iPhone.** Le `.ipa` est fourni non signé et n'a pas été testé sur un appareil réel. Il faut le signer avec ton Apple ID via [AltStore](https://altstore.io) ou [Sideloadly](https://sideloadly.io). Avec un compte gratuit, l'appli expire au bout de 7 jours.

## Mises à jour

Au démarrage, l'appli compare sa version au dernier tag des Releases GitHub de ce dépôt. Si une version plus récente existe, une bannière apparaît :

- Android : l'APK est téléchargé puis l'installeur se lance.
- Windows, Linux, iPhone : la bannière ouvre la page de la release.

Rien n'est téléchargé sans action de ta part sur Windows, Linux et iPhone.

## Compiler soi-même

| Cible | Outils |
|---|---|
| Windows | PowerShell 5.1 et .NET Framework, déjà présents dans Windows |
| Android | JDK 17, Android SDK build-tools 34, plateforme android-34 |
| Linux | Node 20 et electron-builder |
| iPhone | macOS, Xcode 16, XcodeGen |

```powershell
# Windows : embarque le moteur PowerShell dans un lanceur .exe
./build_exe.ps1

# Android : aapt, javac, d8, zipalign, apksigner, sans Gradle
cd android
./build_apk.ps1
```

```bash
# Linux
cd linux && npm install && npm run dist

# iPhone (macOS)
cd ios && cp ../android/assets/index.html GamingDaily/index.html && xcodegen generate
```

Linux et iPhone sont aussi construits par GitHub Actions (`.github/workflows/build.yml`).

Au premier build Android, une clé `android/gamingdaily.jks` est générée. Garde-la : Android refuse une mise à jour signée avec une autre clé. Elle est exclue du dépôt par `.gitignore`.

## Structure

```
GamingDaily.ps1     moteur PC : récupère les flux, extrait, traduit, génère la page
build_exe.ps1       construit GamingDaily.exe
android/            interface web (assets/index.html) et pont natif Java
linux/              application Electron qui réutilise la même interface
ios/                application WKWebView qui réutilise la même interface
docs/               captures d'écran
```

L'interface est un seul fichier, `android/assets/index.html`, réutilisé sur Android, Linux et iPhone. Chaque plateforme fournit un pont natif pour ce que le navigateur ne peut pas faire seul : requêtes sans restriction CORS, synthèse vocale, partage, mise à jour.

## Vie privée

Pas de serveur, pas de compte, pas de statistiques. Favoris, historique et réglages restent sur ton appareil. Les seules connexions sortantes sont les flux RSS des médias, le service de traduction gratuit de Google pour les articles anglais, et l'API des Releases de ce dépôt.

## Sources

jeuxvideo.com, Gamekult, ActuGaming, Gameblog, JVFrance, IndieMag, NoFrag, PlayStation Blog, Xbox Wire, Nintendo-Town, XboxSquad, Gamergen, Frandroid Gaming, IGN, GameSpot, Eurogamer, Kotaku, Polygon, VGC, Destructoid, Insider Gaming, PC Gamer, Rock Paper Shotgun, Push Square, Nintendo Life, Pure Xbox, Wololo, Time Extension, RetroRGB.

Chaque article garde un lien vers sa source. Les textes, images et marques appartiennent à leurs ayants droit. Projet personnel, non affilié à ces médias.

## Licence

[MIT](LICENSE). Le contenu des articles n'est pas couvert par cette licence.
