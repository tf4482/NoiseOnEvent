# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Sound per event chosen from a dropdown: critical hit, herb gathered, ore mined, and each
  ping type.
- Spam protection for critical hit sounds, 0 to 10 seconds.
- Play button next to each sound dropdown, clickable event names, and `/noise test`.
- Own `.mp3` and `.ogg` files from the `sounds` folder, listed in `sounds/Sounds.lua`.
- `sounds/update-sounds.bat` writes all sound files of the folder into `Sounds.lua`.
- Game ping sound of a type muted while an own sound or off is set for it.
- Settings page, addon compartment entry, and `/noise` chat commands per event.
- Account or per-character settings.
