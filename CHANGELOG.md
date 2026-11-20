# Changelog

The format is inspired by [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and the project follows [semantic versioning](https://semver.org/).

## [1.1.0]

### Changed
- The whole app is now in English: UI, notifications, widget, code comments and docs.
- Non-English (French) stories are translated to English on the fly instead of the other way around; text-to-speech and dates use English (en-US).
- UI redesign: editorial "morning wire" layout (masthead with double rule, serif headlines, per-category colors), embedded fonts (Newsreader / Instrument Sans / JetBrains Mono), no gradients, no emojis.
- The PC script (`GamingDaily.ps1`) now embeds the shared `android/assets/index.html` directly, so Windows, Android, Linux and iOS always render the exact same UI.
- Autostart scripts renamed to `enable-autostart.ps1` / `disable-autostart.ps1`.

## [1.0.0] — 2026-07-10

### Added
- First public version of the daily 100% video-game magazine.
- Four platforms from the same reading engine: Windows (`.exe`), Android (`.apk`), Linux (`.AppImage`, Electron app) and iOS (unsigned `.ipa`, WKWebView app for sideloading).
- Automatic builds of the Linux and iOS versions via GitHub Actions (Ubuntu and macOS runners), attached to the release.
- 29 RSS sources (13 French-speaking, 16 English-speaking): news, consoles, PC, modding/retro and homebrew.
- Automatic translation of English articles to French.
- Ad-free built-in reading (content extracted and cleaned), with cover image.
- Categories: News · Consoles · PC · Modding & Retro · Esports.
- Search, offline favorites, read/unread stories, tracked topics and duplicate clustering.
- "Hype of the day" (detection of big announcements), digest of the stories to remember, reading time.
- Gaming glossary on tap, quiz of the day, express summary (TL;DR), podcast mode and text-to-speech.
- Archives of the last 7 days, light/dark theme, settings (text size, sources, clustering).
- **Automatic update**: the app compares its version to the latest tag published on GitHub and offers the update when a new version is out.

[1.0.0]: https://github.com/wk0t/GamingDaily/releases/tag/v1.0.0
