# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Own sounds are listed in game with `/noise add <file>`, `/noise remove <file>` and
  `/noise sounds`; the list is saved and survives addon updates.
- `sounds/update-sounds.bat` is no longer shipped (CurseForge rejects `.bat` files); an
  optional `sounds/Sounds.lua` written by your own script is still merged into the list.

### Fixed

- Skip events the client does not know instead of failing to load; ignore secret combat
  values in hit sounds.

## [0.1.0] - 2026-11-24

### Added

- Sound per event chosen from a dropdown: combat (critical hit, critical hit taken,
  dodge/parry/block, combat start and end, target died, you died, boss pulled and defeated),
  gathering and loot (herb, ore, skinning, fishing, disenchanting, rare loot, money, auction
  sold), group (ready check, dungeon finder, PvP queue, invite, whisper), progress (level up,
  achievement, quest turned in, new mail, gear damaged, bags full, rare or treasure nearby),
  and each ping type.
- Durability threshold for the gear damaged sound, 5 to 100 percent.
- Game sound, own sound, or off for every event the game has a sound for.
- Small gaps between events on the settings page; pings and sliders stay with their event.
- Spam protection for critical hit sounds, 0 to 10 seconds.
- Play button next to each sound dropdown, clickable event names, and `/noise test`.
- Own `.mp3` and `.ogg` files from the `sounds` folder, listed in `sounds/Sounds.lua`.
- `sounds/update-sounds.bat` writes all sound files of the folder into `Sounds.lua`.
- Settings page, addon compartment entry, and `/noise` chat commands per event.
- Account or per-character settings.
