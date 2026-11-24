# NoiseOnEvent

Plays your own sound files when you land a critical hit, gather an herb, or when someone
places a ping; the game's ping sounds are muted and replaced by yours.

## Features

- **Critical hit** - plays `crit` when you land a critical hit.
- **Herb gathered** - plays `herb` when an herb gathering cast succeeds.
- **Ping** - mutes all of the game's ping sounds and plays `ping` instead.
- **Own sounds** - each trigger plays `Sounds/<name>.mp3` or `.ogg` from the addon folder;
  a missing file gets one warning in chat.
- **Remembered** - settings are saved per account, or per character with one checkbox;
  all triggers are on by default.
- **Settings page** - all options in the game menu under Options > AddOns, also opened
  from the addon compartment menu.
- **Chat commands** - every option can also be changed by slash command.

## Install

1. Download `NoiseOnEvent-vX.Y.Z.zip` from the [releases](https://github.com/tf4482/NoiseOnEvent/releases).
2. Unzip it into `World of Warcraft/<game folder>/Interface/AddOns/`.
3. Put your sound files into `Interface/AddOns/NoiseOnEvent/Sounds/`:

   | File | Trigger |
   | --- | --- |
   | `crit.mp3` or `crit.ogg` | critical hit |
   | `herb.mp3` or `herb.ogg` | herb gathered |
   | `ping.mp3` or `ping.ogg` | ping |

4. Restart the game; `/reload` does not find newly added files.

Back up the `Sounds` folder before updating; an update may replace the addon folder.

## Usage

```text
/noise                    show the current state
/noise crit on|off        sound on critical hits
/noise herb on|off        sound when you gather an herb
/noise ping on|off        own ping sound instead of the game's
/noise character on|off   use settings for this character only, or the account's
/noise config             open the settings page
/noise help               list all commands
```

## Examples

- Back to the game's ping sounds: `/noise ping off` (unmutes them right away).
- Crits get noisy in dungeons: `/noise crit off`.
- Only your gathering alt should hear herbs: on that alt type `/noise character on`, on
  the account settings `/noise herb off`.
- Check what is active: `/noise`.

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
