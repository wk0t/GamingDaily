# Journal des modifications

Le format s'inspire de [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et le projet suit le [versionnage sémantique](https://semver.org/lang/fr/).

## [1.0.0] — 2026-07-10

### Ajouté
- Première version publique du magazine quotidien 100 % jeu vidéo.
- Quatre plateformes à partir de la même logique de lecture : Windows (`.exe`), Android (`.apk`), Linux (`.AppImage`, app Electron) et iOS (`.ipa` non signé, app WKWebView pour le sideload).
- Build automatique des versions Linux et iOS via GitHub Actions (runners Ubuntu et macOS), déposées sur la release.
- 29 sources RSS (13 francophones, 16 anglophones) : actu, consoles, PC, modding/rétro et homebrew.
- Traduction automatique des articles anglais vers le français.
- Lecture intégrée sans publicité (contenu extrait et nettoyé), avec image de couverture.
- Catégories : Actu · Consoles · PC · Modding & Rétro · Esport.
- Recherche, favoris hors-ligne, articles lus/non-lus, sujets suivis et regroupement des doublons.
- « Hype du jour » (détection des grosses annonces), digest des infos à retenir, temps de lecture.
- Glossaire gaming au toucher, quiz du jour, résumé express (TL;DR), mode podcast et synthèse vocale.
- Archives des 7 derniers jours, thème clair/sombre, réglages (taille du texte, sources, regroupement).
- **Mise à jour automatique** : l'application compare sa version au dernier tag publié sur GitHub et propose la mise à jour quand une nouvelle version sort.

[1.0.0]: https://github.com/wk0t/GamingDaily/releases/tag/v1.0.0
