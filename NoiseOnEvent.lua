-- NoiseOnEvent: plays player-chosen sound files on critical hits, gathering, and pings

local ADDON, ns = ...

-- folder with the sound files supplied by the player
local FOLDER = "Interface\\AddOns\\" .. ADDON .. "\\sounds\\"
-- sound files listed by the player in sounds/Sounds.lua
local SOUNDS = ns.sounds or {}
-- shortest time between two sounds of one event, in seconds
local MIN_DELAY = 0.3
-- base spells whose localized names identify gathering casts
local HERB_SPELL, MINING_SPELL = 2366, 2575
-- events: setting key and chat command, label, description, optional spam protection
-- setting, and for pings the game sound to mute
local EVENTS = {
  { key = "crit", label = "Critical hit", help = "your target takes a critical hit", delay = "critDelay" },
  { key = "herb", label = "Herb gathered", help = "you gather an herb" },
  { key = "mining", label = "Ore mined", help = "you mine a deposit" },
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

-- events by setting key
local byKey = {}
for _, event in ipairs(EVENTS) do
  byKey[event.key] = event
end

-- play the sound chosen for an event, at most once per spam protection time; warn once
-- when its file is missing
local function Play(key)
  local sound = ns.db ~= nil and ns.Get(key) or ""
  local event = byKey[key]
  local delay = math.max(MIN_DELAY, event.delay and ns.Get(event.delay) or 0)
  if sound == "" or GetTime() - (lastPlayed[key] or 0) < delay then
    return
  end
  lastPlayed[key] = GetTime()
  if not PlaySoundFile(FOLDER .. sound, "Master") and not warned[sound] then
    warned[sound] = true
    ns.Warn("Sound file missing: " .. ns.Color("value", "sounds/" .. sound)
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

-- play button and test command: the chosen sound, or the game's ping sound when none is set
local function Test(event)
  local sound = ns.Get(event.key)
  if sound ~= "" then
    PlaySoundFile(FOLDER .. sound, "Master")
  elseif event.mute then
    PlaySoundFile(event.mute, "Master")
  else
    ns.Warn(event.label .. ": no sound chosen")
  end
end

-- current sound of every event
local function Status()
  for _, event in ipairs(EVENTS) do
    local sound = ns.Get(event.key)
    ns.Status(event.label, sound == "" and ns.Color("muted", SoundName(event, sound)) or sound)
  end
  ns.Status("Critical hit spam protection", ns.Get("critDelay") .. " s")
  ns.Status("per character", ns.OnOff(ns.char.perCharacter))
  if #SOUNDS == 0 then
    ns.Warn("No sounds listed: add your files to " .. ns.Color("value", "sounds/Sounds.lua"))
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

-- own cast finished: herb gathering or mining
function events.UNIT_SPELLCAST_SUCCEEDED(_, _, spellID)
  if not spellID or Secret(spellID) then
    return
  end
  local name = C_Spell.GetSpellName(spellID)
  if not name then
    return
  end
  if name == C_Spell.GetSpellName(HERB_SPELL) then
    Play("herb")
  elseif name == C_Spell.GetSpellName(MINING_SPELL) then
    Play("mining")
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

-- saved state: no sound for any event by default, one second crit spam protection
local defaults = { critDelay = 1 }
for _, event in ipairs(EVENTS) do
  defaults[event.key] = ""
end

-- layout of this addon's settings page, for play buttons the Settings component lacks
local function Layout()
  local title = C_AddOns.GetAddOnMetadata(ADDON, "Title") or ADDON
  for _, category in ipairs(SettingsPanel:GetAllCategories()) do
    if category:GetName() == title then
      return SettingsPanel:GetLayout(category)
    end
  end
end

-- play the sound of the event a row frame shows now, if it is one of ours
local function PlayRow(frame)
  if frame.noiseOnEventEvent then
    Test(frame.noiseOnEventEvent)
  end
end

-- small play button to the right of a dropdown row and a clickable event name, set up once
-- per pooled row frame
local function ShowPlayButton(frame, event)
  frame.noiseOnEventEvent = event
  local button = frame.noiseOnEventPlay
  if not button then
    -- the name area plays the sound on click; other rows using this frame stay silent
    frame.Tooltip:HookScript("OnMouseUp", function() PlayRow(frame) end)
    button = CreateFrame("Button", nil, frame)
    button:SetSize(26, 26)
    button:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    button:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    button:SetPoint("LEFT", frame.Control, "RIGHT", 8, 0)
    -- tooltip naming the action
    button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText("Play")
      GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnClick", function() PlayRow(frame) end)
    frame.noiseOnEventPlay = button
  end
  button:Show()
end

-- add the play button and clickable name to the dropdown just added; undo both when the
-- row frame is reused
local function AddPlayButton(layout, event)
  local initializers = layout:GetInitializers()
  local initializer = initializers[#initializers]
  local initFrame, resetter = initializer.InitFrame, initializer.Resetter
  function initializer:InitFrame(frame)
    initFrame(self, frame)
    ShowPlayButton(frame, event)
  end
  function initializer:Resetter(frame)
    frame.noiseOnEventEvent = nil
    if frame.noiseOnEventPlay then
      frame.noiseOnEventPlay:Hide()
    end
    resetter(self, frame)
  end
end

-- settings page: per event a sound dropdown with play button, and crit spam protection;
-- ping mutes applied once loaded
ns.Store("NoiseOnEventDB", defaults, function()
  ns.Settings()
  local layout = Layout()
  for _, event in ipairs(EVENTS) do
    local choices = { { "", SoundName(event, "") } }
    for _, sound in ipairs(SOUNDS) do
      table.insert(choices, { sound, sound })
    end
    local onChange = event.mute and function() UpdateMute(event) end or nil
    ns.Dropdown(event.key, event.label, choices, "Sound to play when " .. event.help, onChange)
    if layout then
      AddPlayButton(layout, event)
    end
    if event.delay then
      ns.Slider(event.delay, "Spam protection (seconds)", 0, 10, 0.5,
        "Shortest time between two sounds for " .. event.label:lower())
    end
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
  name = "critdelay",
  help = "spam protection: shortest time between two critical hit sounds",
  args = { { name = "seconds", type = "number", min = 0, max = 10 } },
  run = function(args)
    ns.Set("critDelay", args.seconds)
    ns.Status("Critical hit spam protection", ns.Get("critDelay") .. " s")
  end,
})
-- event keys for the test command
local keys = {}
for _, event in ipairs(EVENTS) do
  table.insert(keys, event.key)
end
ns.Command({
  name = "test",
  help = "play the sound chosen for an event",
  args = { { name = "event", choices = keys } },
  run = function(args) Test(byKey[args.event]) end,
})
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
