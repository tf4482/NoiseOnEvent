-- NoiseOnEvent: plays player-supplied sound files on critical hits, herb gathering, and pings

local ADDON, ns = ...

-- folder with the sound files supplied by the player
local FOLDER = "Interface\\AddOns\\" .. ADDON .. "\\Sounds\\"
-- base spell whose localized name identifies herb gathering casts
local HERB_SPELL = 2366
-- game sound files of all ping types, muted while the ping trigger is on
local PING_FILES = { 5339002, 5339006, 5340601, 5340605, 5342387, 5350036, 7903953 }
-- combat log damage events and the position of their critical flag
local CRIT_FLAG = { SWING_DAMAGE = 18, RANGE_DAMAGE = 21, SPELL_DAMAGE = 21, SPELL_PERIODIC_DAMAGE = 21 }
-- triggers: setting key (also the sound file name), label, and description
local TRIGGERS = {
  { key = "crit", label = "Critical hit", help = "you land a critical hit" },
  { key = "herb", label = "Herb gathered", help = "you gather an herb" },
  { key = "ping", label = "Ping", help = "a ping is placed, instead of the game's ping sounds" },
}

-- whether a value is hidden from addons (12.x secret values)
local function Secret(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

-- time of the last sound per trigger, and triggers already warned about a missing file
local lastPlayed, warned = {}, {}

-- play the trigger's sound file when its setting is on; warn once when the file is missing
local function Play(key)
  if ns.db == nil or not ns.Get(key) or GetTime() - (lastPlayed[key] or 0) < 0.3 then
    return
  end
  lastPlayed[key] = GetTime()
  if PlaySoundFile(FOLDER .. key .. ".mp3", "Master") or PlaySoundFile(FOLDER .. key .. ".ogg", "Master") then
    return
  end
  if not warned[key] then
    warned[key] = true
    ns.Warn("Sound file missing: " .. ns.Color("value", "Sounds/" .. key .. ".mp3")
      .. " or " .. ns.Color("value", ".ogg") .. " (restart the game after adding files)")
  end
end

-- mute or unmute the game's ping sounds to match the ping setting
local function UpdatePingMute()
  local mute = ns.Get("ping") and MuteSoundFile or UnmuteSoundFile
  for _, id in ipairs(PING_FILES) do
    mute(id)
  end
end

-- current state of every trigger
local function Status()
  for _, trigger in ipairs(TRIGGERS) do
    ns.Status(trigger.label, ns.OnOff(ns.Get(trigger.key)))
  end
  ns.Status("per character", ns.OnOff(ns.char.perCharacter))
end

-- own GUID, to find the player's hits in the combat log
local playerGUID

-- combat log entry: own critical damage
local function OnCombatLog(_, subevent, _, sourceGUID, ...)
  local flag = CRIT_FLAG[subevent]
  if flag and sourceGUID == playerGUID and select(flag - 4, ...) then
    Play("crit")
  end
end

-- event handlers by event name
local events = {}

-- world ready: own GUID known
function events.PLAYER_LOGIN()
  playerGUID = UnitGUID("player")
end

-- combat log, where addons may still read it
function events.COMBAT_LOG_EVENT_UNFILTERED()
  OnCombatLog(CombatLogGetCurrentEventInfo())
end

-- target took a critical hit from any source; fallback when the combat log is restricted
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

-- ping placed by anyone in the group, announced through chat
function events.CHAT_MSG_PING()
  Play("ping")
end

-- one frame dispatching all events above
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("CHAT_MSG_PING")
frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
-- combat log where allowed, otherwise critical hits on the target
local ok, registered = pcall(frame.RegisterEvent, frame, "COMBAT_LOG_EVENT_UNFILTERED")
if not ok or registered == false then
  frame:RegisterUnitEvent("UNIT_COMBAT", "target")
end
frame:SetScript("OnEvent", function(_, event, ...)
  events[event](...)
end)

-- saved state; settings page and ping mute once loaded
ns.Store("NoiseOnEventDB", { crit = true, herb = true, ping = true }, function()
  ns.Settings()
  for _, trigger in ipairs(TRIGGERS) do
    local onChange = trigger.key == "ping" and UpdatePingMute or nil
    ns.Checkbox(trigger.key, trigger.label, "Play Sounds/" .. trigger.key .. " when " .. trigger.help, onChange)
  end
  UpdatePingMute()
end)

-- one on|off chat command per trigger
for _, trigger in ipairs(TRIGGERS) do
  ns.Command({
    name = trigger.key,
    help = "play a sound when " .. trigger.help,
    args = { { name = "state", choices = { "on", "off" } } },
    run = function(args)
      ns.Set(trigger.key, args.state == "on")
      ns.Status(trigger.label, ns.OnOff(ns.Get(trigger.key)))
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
