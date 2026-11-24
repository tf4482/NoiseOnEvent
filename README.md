# NoiseOnEvent

Plays your own sound files on game events: pick a sound per event from a dropdown. For
pings, your sound replaces the game's ping sound.

## Features

- **Critical hit** - your sound when your target takes a critical hit, from anyone; the
  game hides the source of a hit from addons; a spam protection (0-10 seconds, default 1)
  sets the shortest time between two crit sounds.
- **Herb gathered** - your sound when an herb gathering cast succeeds.
- **Ore mined** - your sound when a mining cast succeeds.
- **Pings** - one sound per ping type (attack, warning, assist, on my way, threat, look
  here, spell or item ping); the game's sound for that type is muted while one is set.
- **Own sounds** - any `.mp3` or `.ogg` files in the addon's `Sounds` folder, listed in
  `Sounds/Sounds.lua` by `Sounds/update-sounds.bat`; a missing file gets one warning in
  chat.
- **Remembered** - settings are saved per account, or per character with one checkbox;
  no event plays a sound until you pick one.
- **Settings page** - one dropdown with a play button per event in the game menu under
  Options > AddOns, also opened from the addon compartment menu; choosing a sound plays it
  once.
- **Chat commands** - every event can also be set by slash command.

## Install

1. Download `NoiseOnEvent-vX.Y.Z.zip` from the [releases](https://github.com/tf4482/NoiseOnEvent/releases).
2. Unzip it into `World of Warcraft/<game folder>/Interface/AddOns/`.
3. Copy your sound files into `Interface/AddOns/NoiseOnEvent/Sounds/` and double-click
   `update-sounds.bat` there; it lists every `.mp3` and `.ogg` file in `Sounds.lua`. On
   macOS or Linux, list them by hand:

   ```lua
   ns.sounds = {
     "kaching.mp3",
     "bell.ogg",
   }
   ```

4. Restart the game (new files are only found after a restart), then pick a sound per
   event under Options > AddOns > NoiseOnEvent.

Back up the `Sounds` folder before updating; an update replaces the addon folder.

## Usage

```text
/noise                        show the sound of every event
/noise crit <sound>|off       sound on critical hits on your target
/noise critdelay <seconds>    spam protection for critical hits, 0 to 10
/noise herb <sound>|off       sound when you gather an herb
/noise mining <sound>|off     sound when you mine a deposit
/noise attack <sound>|off     sound for attack pings (off: game sound)
/noise warning <sound>|off    sound for warning pings
/noise assist <sound>|off     sound for assist pings
/noise onmyway <sound>|off    sound for on-my-way pings
/noise threat <sound>|off     sound for threatening alert pings
/noise nonthreat <sound>|off  sound for look-here pings, and all pings in instance combat
/noise action <sound>|off     sound for spell and item pings
/noise test <event>           play the sound chosen for an event, e.g. crit
/noise character on|off       use settings for this character only, or the account's
/noise config                 open the settings page
/noise help                   list all commands
```

`<sound>` is a file name from `Sounds/Sounds.lua`; put names with spaces in quotes.

## Examples

- Kaching on every critical hit: `/noise crit kaching.mp3`.
- Crits in AoE fights get noisy: `/noise critdelay 5` plays at most one crit sound every
  5 seconds.
- Try a sound before playing: pick it in the dropdown and click the play button next to it, or `/noise test mining`.
- Back to the game's attack ping: `/noise attack off` (unmutes it right away).
- A horn only for warnings: `/noise warning horn.ogg`, the other pings keep the game sound.
- Your gathering alt should hear herbs, your main not: on the alt type
  `/noise character on`, then `/noise herb bell.ogg`.
- Check what is set: `/noise`.

## Develop

Check the code with [Luacheck](https://github.com/lunarmodules/luacheck) before each commit
(CI runs it on every push):

```text
luacheck .
```

Release: push an annotated tag `vX.Y.Z`; GitHub Actions packages the addon with the
BigWigs packager and publishes it.

## License

All rights reserved, see [LICENSE](LICENSE).
