# NoiseOnEvent

Plays your own sound files on game events: pick a sound per event from a dropdown. Where
the game has its own sound for an event, yours replaces it, or you switch it off.

## Features

- **Combat** - critical hit on your target (from anyone; the game hides the source of a
  hit from addons) with a spam protection of 0-10 seconds (default 1), critical hit taken,
  dodge/parry/block, combat start and end, target died, you died, boss pulled, boss
  defeated.
- **Gathering and loot** - herb gathered, ore mined, skinned, fish caught, disenchanted,
  rare or better item looted, money received, auction sold.
- **Group and social** - ready check, dungeon finder ready, PvP queue ready, group invite,
  whisper; each can keep the game sound, use yours, or be off. Ready check, dungeon finder,
  and PvP queue share one game sound: replacing it for one also silences it for the others.
- **Progress** - level up, achievement, quest turned in (game sound, yours, or off), new
  mail, gear damaged below an average durability threshold (5-100 %, default 20), bags
  full, rare or treasure on the minimap.
- **Pings** - one sound per ping type (attack, warning, assist, on my way, threat, look
  here, spell or item ping), the game sound, or off.
- **Own sounds** - any `.mp3` or `.ogg` files in the addon's `sounds` folder, listed in
  `sounds/Sounds.lua` by `sounds/update-sounds.bat`; a missing file gets one warning in
  chat.
- **Remembered** - settings are saved per account, or per character with one checkbox;
  no event plays a sound until you pick one.
- **Settings page** - one dropdown with a play button per event in the game menu under
  Options > AddOns, also opened from the addon compartment menu; clicking an event's name
  plays its sound too; small gaps keep events apart, pings and sliders stay with their
  event.
- **Chat commands** - every event can also be set by slash command.

## Install

1. Download `NoiseOnEvent-vX.Y.Z.zip` from the [releases](https://github.com/tf4482/NoiseOnEvent/releases).
2. Unzip it into `World of Warcraft/<game folder>/Interface/AddOns/`.
3. Copy your sound files into `Interface/AddOns/NoiseOnEvent/sounds/` and double-click
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

Back up the `sounds` folder before updating; an update replaces the addon folder.

## Usage

```text
/noise                            show all events with a chosen sound
/noise <event> <sound>|off        sound for an event, or off
/noise <event> game               game sound again (events with a game sound)
/noise critdelay <seconds>        spam protection for critical hits, 0 to 10
/noise durabilitylimit <percent>  durability threshold for gear damaged, 5 to 100
/noise test <event>               play the sound chosen for an event
/noise character on|off           use settings for this character only, or the account's
/noise config                     open the settings page
/noise help                       list all commands
```

`<sound>` is a file name from `sounds/Sounds.lua`; put names with spaces in quotes.
`<event>` is one of:

| Group | Events |
| --- | --- |
| Combat | `crit`, `crittaken`, `avoid`, `combatstart`, `combatend`, `targetdied`, `death`, `bosspull`, `bosskill` |
| Gathering and loot | `herb`, `mining`, `skinning`, `fishing`, `disenchant`, `loot`, `money`, `auction` |
| Group and social | `readycheck`, `lfg`, `pvp`, `invite`, `whisper` |
| Progress | `levelup`, `achievement`, `quest`, `mail`, `durability`, `bagsfull`, `rare` |
| Pings | `attack`, `warning`, `assist`, `onmyway`, `threat`, `nonthreat` (also all pings in instance combat), `action` |

## Examples

- Kaching on every critical hit: `/noise crit kaching.mp3`.
- Crits in AoE fights get noisy: `/noise critdelay 5` plays at most one crit sound every
  5 seconds.
- Try a sound before playing: pick it in the dropdown and click the play button next to
  it, or type `/noise test mining`.
- Never miss a dungeon pop: `/noise lfg horn.ogg`.
- Quiet whispers while streaming: `/noise whisper off`.
- Repair reminder at half durability: `/noise durabilitylimit 50`, then
  `/noise durability bell.ogg`.
- Back to the game's attack ping: `/noise attack game` (unmutes it right away).
- Silence spell and item pings completely: `/noise action off`.
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
