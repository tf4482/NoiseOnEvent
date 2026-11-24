-- NoiseOnEvent: plays player-chosen sound files on critical hits, herb gathering, and pings

local ADDON, ns = ...

-- folder with the sound files supplied by the player
local FOLDER = "Interface\\AddOns\\" .. ADDON .. "\\Sounds\\"
-- sound files listed by the player in Sounds/Sounds.lua
local SOUNDS = ns.sounds or {}
-- base spell whose localized name identifies herb gathering casts
local HERB_SPELL = 2366
-- events: setting key and chat command, label, description, and for pings the game sound to mute
local EVENTS = {
  { key = "crit", label = "Critical hit", help = "your target takes a critical hit" },
  { key = "herb", label = "Herb gathered", help = "you gather an herb" },
  { key = "attack", label = "Ping: Attack", help = "an attack ping is placed", mute = 5350036 },
  { key = "warning", label = "Ping: Warning", help = "a warning ping is placed", mute = 5342387 },
  { key = "assist", label = "Ping: Assist", help = "an assist ping is placed", mute = 5339006 },
  { key = "onmyway", label = "Ping: On my way", help = "an on-my-way ping is placed", mute = 5340605 },
  { key = "threat", label = "Ping: Threat", help = "a threatening alert ping is placed", mute = 5340601 },
  { key = "nonthreat", label = "Ping: Look here", help = "a look-here ping is placed", mute = 5339002 },
  { key = "action", label = "Ping: Spell or item", help = "a spell or item ping is placed", mute = 7903953 },
}
-- ping events by the icon name in the chat message; pings without icon are spell or item pings
local PING_ICONS = {
  attack = "attack", warning = "warning", assist = "assist", onmyway = "onmyway",
  threat = "threat", nonthreat = "nonthreat",
}

-- whether a value is hidden from addons (12.x secret values)
local function Secret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- time of the last sound per event, and files already warned about as missing
local lastPlayed, warned = {}, {}

-- play the sound chosen for an event; warn once when its file is missing
local function Play(key)
  local sound = ns.db ~= nil and ns.Get(key) or ""
  if sound == "" or GetTime() - (lastPlayed[key] or 0) < 0.3 then
    return
  end
  lastPlayed[key] = GetTime()
  if not PlaySoundFile(FOLDER .. sound, "Master") and not warned[sound] then
    warned[sound] = true
    ns.Warn("Sound file missing: " .. ns.Color("value", "Sounds/" .. sound)
      .. " (restart the game after adding files)")
  end
end

-- mute the game's ping sound while an own sound replaces it
local function UpdateMute(event)
  if ns.Get(event.key) == "" then
    UnmuteSoundFile(event.mute)
  else
    MuteSoundFile(event.mute)
  end
end

-- display name of a setting value
local function SoundName(event, sound)
  if sound ~= "" then
    return sound
  end
  return event.mute and "game sound" or "off"
end

-- current sound of every event
local function Status()
  for _, event in ipairs(EVENTS) do
    local sound = ns.Get(event.key)
    ns.Status(event.label, sound == "" and ns.Color("muted", SoundName(event, sound)) or sound)
  end
  ns.Status("per character", ns.OnOff(ns.char.perCharacter))
  if #SOUNDS == 0 then
    ns.Warn("No sounds listed: add your files to " .. ns.Color("value", "Sounds/Sounds.lua"))
  end
end

-- event handlers by event name
local events = {}

-- target took a critical hit from any source; the combat log is closed to addons
function events.UNIT_COMBAT(_, action, flagText)
  if action == "WOUND" and flagText == "CRITICAL" then
    Play("crit")
  end
end

-- own cast finished: herb gathering
function events.UNIT_SPELLCAST_SUCCEEDED(_, _, spellID)
  if not spellID or Secret(spellID) then
    return
  end
  local name = C_Spell.GetSpellName(spellID)
  if name and name == C_Spell.GetSpellName(HERB_SPELL) then
    Play("herb")
  end
end

-- ping placed by anyone in the group, announced through chat; type from the message icon,
-- hidden during instance combat lockdown
function events.CHAT_MSG_PING(text)
  if Secret(text) then
    Play("nonthreat")
  else
    Play(PING_ICONS[text:match("ping_chat_(%a+)")] or "action")
  end
end

-- one frame dispatching all events above
local frame = CreateFrame("Frame")
frame:RegisterEvent("CHAT_MSG_PING")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
frame:RegisterUnitEvent("UNIT_COMBAT", "target")
frame:SetScript("OnEvent", function(_, event, ...)
  events[event](...)
end)

-- saved state: no sound for any event by default
local defaults = {}
for _, event in ipairs(EVENTS) do
  defaults[event.key] = ""
end

-- settings page with one sound dropdown per event, and the ping mutes, once loaded
ns.Store("NoiseOnEventDB", defaults, function()
  ns.Settings()
  for _, event in ipairs(EVENTS) do
    local choices = { { "", SoundName(event, "") } }
    for _, sound in ipairs(SOUNDS) do
      table.insert(choices, { sound, sound })
    end
    local onChange = event.mute and function() UpdateMute(event) end or nil
    ns.Dropdown(event.key, event.label, choices, "Sound to play when " .. event.help, onChange)
    if event.mute then
      UpdateMute(event)
    end
  end
end)

-- listed sound file matching a chat argument, ignoring case; "" for off
local function FindSound(word)
  if word:lower() == "off" then
    return ""
  end
  for _, sound in ipairs(SOUNDS) do
    if sound:lower() == word:lower() then
      return sound
    end
  end
end

-- one chat command per event, choosing a listed sound or off
for _, event in ipairs(EVENTS) do
  ns.Command({
    name = event.key,
    help = "sound file (or off) when " .. event.help,
    args = { { name = "sound" } },
    run = function(args)
      local sound = FindSound(args.sound)
      if not sound then
        return ns.Error("Unknown sound - listed: " .. ns.Color("value", table.concat(SOUNDS, ", ")))
      end
      ns.Set(event.key, sound)
      ns.Status(event.label, SoundName(event, sound))
    end,
  })
end
ns.Command({
  name = "character",
  help = "use settings for this character only, or the account's",
  args = { { name = "state", choices = { "on", "off" } } },
  run = function(args)
    ns.Set("perCharacter", args.state == "on")
    Status()
  end,
})
ns.Command({ name = "config", help = "open the settings page", run = ns.OpenSettings })
ns.Slash("/noise", Status)
