-- NoiseOnEvent: plays player-chosen sound files on game events, replacing the game's sound
-- where it has one

local ADDON, ns = ...

-- folder with the sound files supplied by the player
local FOLDER = "Interface\\AddOns\\" .. ADDON .. "\\sounds\\"
-- sound files listed by the player in sounds/Sounds.lua
local SOUNDS = ns.sounds or {}
-- setting value that silences an event with a game sound; "" keeps the game sound
local OFF = "off"
-- shortest time between two sounds of one event, in seconds
local MIN_DELAY = 0.3
-- base spells whose localized names identify profession casts
local SPELLS = { herb = 2366, mining = 2575, skinning = 8613, disenchant = 13262 }
-- game sound files: ready check (also dungeon finder and PvP), PvP queue, invite, whisper,
-- level up, achievement, quest turned in
local READY, PVP, INVITE, WHISPER = 567478, 568011, 567451, 567421
local LEVEL, ACHIEVEMENT, QUEST = 569593, 569143, 567439

-- events in page order: setting key and chat command, label, description; optional
-- settings slider shown below (setting key, label, min, max, step), game sound files to
-- mute, and group of events shown without spacing
local EVENTS = {
  { key = "crit", label = "Critical hit", help = "your target takes a critical hit",
    slider = { "critDelay", "Spam protection (seconds)", 0, 10, 0.5 } },
  { key = "crittaken", label = "Critical hit taken", help = "you take a critical hit" },
  { key = "avoid", label = "Dodge, parry, block", help = "you dodge, parry, or block an attack" },
  { key = "combatstart", label = "Combat start", help = "you enter combat" },
  { key = "combatend", label = "Combat end", help = "you leave combat" },
  { key = "targetdied", label = "Target died", help = "your target dies" },
  { key = "death", label = "You died", help = "you die" },
  { key = "bosspull", label = "Boss pulled", help = "a boss encounter starts" },
  { key = "bosskill", label = "Boss defeated", help = "a boss encounter ends in victory" },
  { key = "herb", label = "Herb gathered", help = "you gather an herb" },
  { key = "mining", label = "Ore mined", help = "you mine a deposit" },
  { key = "skinning", label = "Skinned", help = "you skin a creature" },
  { key = "fishing", label = "Fish caught", help = "you loot a fishing catch" },
  { key = "disenchant", label = "Disenchanted", help = "you disenchant an item" },
  { key = "loot", label = "Rare loot", help = "you loot an item of rare quality or better" },
  { key = "money", label = "Money received", help = "your money increases" },
  { key = "auction", label = "Auction sold", help = "an auction of yours sells" },
  { key = "readycheck", label = "Ready check", help = "a ready check starts", mute = { READY } },
  { key = "lfg", label = "Dungeon finder ready", help = "the dungeon or raid finder finds a group",
    mute = { READY } },
  { key = "pvp", label = "PvP queue ready", help = "a battleground or arena is ready",
    mute = { READY, PVP } },
  { key = "invite", label = "Group invite", help = "you are invited to a group", mute = { INVITE } },
  { key = "whisper", label = "Whisper", help = "you receive a whisper", mute = { WHISPER } },
  { key = "levelup", label = "Level up", help = "you reach a new level", mute = { LEVEL } },
  { key = "achievement", label = "Achievement", help = "you earn an achievement", mute = { ACHIEVEMENT } },
  { key = "quest", label = "Quest turned in", help = "you turn in a quest", mute = { QUEST } },
  { key = "mail", label = "New mail", help = "new mail arrives" },
  { key = "durability", label = "Gear damaged", help = "average durability drops below the threshold",
    slider = { "durabilityLimit", "Durability threshold (%)", 5, 100, 5 } },
  { key = "bagsfull", label = "Bags full", help = "your bags are full" },
  { key = "rare", label = "Rare or treasure nearby", help = "a rare or treasure appears on the minimap" },
  { key = "attack", label = "Ping: Attack", help = "an attack ping is placed", mute = { 5350036 },
    group = "ping" },
  { key = "warning", label = "Ping: Warning", help = "a warning ping is placed", mute = { 5342387 },
    group = "ping" },
  { key = "assist", label = "Ping: Assist", help = "an assist ping is placed", mute = { 5339006 },
    group = "ping" },
  { key = "onmyway", label = "Ping: On my way", help = "an on-my-way ping is placed", mute = { 5340605 },
    group = "ping" },
  { key = "threat", label = "Ping: Threat", help = "a threatening alert ping is placed",
    mute = { 5340601 }, group = "ping" },
  { key = "nonthreat", label = "Ping: Look here", help = "a look-here ping is placed",
    mute = { 5339002 }, group = "ping" },
  { key = "action", label = "Ping: Spell or item", help = "a spell or item ping is placed",
    mute = { 7903953 }, group = "ping" },
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
  local delay = MIN_DELAY
  if event.key == "crit" then
    delay = math.max(MIN_DELAY, ns.Get("critDelay"))
  end
  if sound == "" or sound == OFF or GetTime() - (lastPlayed[key] or 0) < delay then
    return
  end
  lastPlayed[key] = GetTime()
  if not PlaySoundFile(FOLDER .. sound, "Master") and not warned[sound] then
    warned[sound] = true
    ns.Warn("Sound file missing: " .. ns.Color("value", "sounds/" .. sound)
      .. " (restart the game after adding files)")
  end
end

-- game sound files muted by this addon now
local muted = {}

-- mute each game sound file while an event using it has an own sound or off; files shared
-- by several events stay muted while any of them replaces it
local function UpdateMutes()
  local wanted = {}
  for _, event in ipairs(EVENTS) do
    for _, file in ipairs(event.mute or {}) do
      wanted[file] = wanted[file] or ns.Get(event.key) ~= ""
    end
  end
  for file, mute in pairs(wanted) do
    if mute and not muted[file] then
      MuteSoundFile(file)
    elseif not mute and muted[file] then
      UnmuteSoundFile(file)
    end
    muted[file] = mute
  end
end

-- display name of a setting value
local function SoundName(event, sound)
  if sound ~= "" then
    return sound
  end
  return event.mute and "game sound" or OFF
end

-- whether a setting value plays no own sound file
local function NoFile(sound)
  return sound == "" or sound == OFF
end

-- play button and test command: the chosen sound, or the game sound when none is set
local function Test(event)
  local sound = ns.Get(event.key)
  if not NoFile(sound) then
    PlaySoundFile(FOLDER .. sound, "Master")
  elseif sound == "" and event.mute and not muted[event.mute[1]] then
    PlaySoundFile(event.mute[1], "Master")
  elseif sound == "" and event.mute then
    ns.Warn(event.label .. ": game sound muted, another event sharing it has its own sound")
  else
    ns.Warn(event.label .. ": sound is off")
  end
end

-- events with a chosen sound or off; all others keep their default
local function Status()
  local count = 0
  for _, event in ipairs(EVENTS) do
    local sound = ns.Get(event.key)
    if sound ~= "" then
      ns.Status(event.label, NoFile(sound) and ns.Color("muted", sound) or sound)
      count = count + 1
    end
  end
  ns.Detail(ns.Color("muted", (count == 0 and "All" or "All other") .. " events: off or game sound"))
  ns.Status("Critical hit spam protection", ns.Get("critDelay") .. " s")
  ns.Status("Durability threshold", ns.Get("durabilityLimit") .. " %")
  ns.Status("per character", ns.OnOff(ns.char.perCharacter))
  if #SOUNDS == 0 then
    ns.Warn("No sounds listed: add your files to " .. ns.Color("value", "sounds/Sounds.lua"))
  end
end

-- state for events that fire on changes: money, target death, mail, durability, PvP queue,
-- vignettes already announced
local lastMoney, targetDead, hadMail, gearLow = 0, false, false, false
local pvpStatus, seenVignettes = {}, {}

-- average durability of equipped items in percent, or nil without durable items
local function Durability()
  local current, maximum = 0, 0
  for slot = 1, 19 do
    local value, max = GetInventoryItemDurability(slot)
    if value and max and max > 0 then
      current, maximum = current + value, maximum + max
    end
  end
  return maximum > 0 and current / maximum * 100 or nil
end

-- event handlers by event name
local events = {}

-- world ready: starting values for events that compare against the previous state
function events.PLAYER_LOGIN()
  lastMoney = GetMoney()
  hadMail = HasNewMail()
end

-- hit on target or player: critical hits, and dodge, parry, or block of the player
function events.UNIT_COMBAT(unit, action, flagText)
  if unit == "target" and action == "WOUND" and flagText == "CRITICAL" then
    Play("crit")
  elseif unit == "player" and action == "WOUND" and flagText == "CRITICAL" then
    Play("crittaken")
  elseif unit == "player" and (action == "DODGE" or action == "PARRY" or action == "BLOCK") then
    Play("avoid")
  end
end

-- combat start
function events.PLAYER_REGEN_DISABLED()
  Play("combatstart")
end

-- combat end
function events.PLAYER_REGEN_ENABLED()
  Play("combatend")
end

-- new target: remember whether it is already dead
function events.PLAYER_TARGET_CHANGED()
  targetDead = UnitIsDead("target") == true
end

-- target health changed: play once when it dies
function events.UNIT_HEALTH()
  local dead = UnitIsDead("target")
  if Secret(dead) then
    return
  end
  if dead and not targetDead then
    Play("targetdied")
  end
  targetDead = dead == true
end

-- own death
function events.PLAYER_DEAD()
  Play("death")
end

-- boss encounter starts
function events.ENCOUNTER_START()
  Play("bosspull")
end

-- boss encounter ends; success 1 is a victory
function events.ENCOUNTER_END(_, _, _, _, success)
  if success == 1 then
    Play("bosskill")
  end
end

-- own cast finished: herb gathering, mining, skinning, or disenchanting
function events.UNIT_SPELLCAST_SUCCEEDED(_, _, spellID)
  if not spellID or Secret(spellID) then
    return
  end
  local name = C_Spell.GetSpellName(spellID)
  if not name then
    return
  end
  for key, base in pairs(SPELLS) do
    if name == C_Spell.GetSpellName(base) then
      return Play(key)
    end
  end
end

-- loot window opened: fishing catch
function events.LOOT_OPENED()
  if IsFishingLoot() then
    Play("fishing")
  end
end

-- loot message: own item of rare quality or better
function events.CHAT_MSG_LOOT(text, ...)
  local guid = select(11, ...)
  if Secret(text) or Secret(guid) or guid ~= UnitGUID("player") then
    return
  end
  local link = text:match("|Hitem:.-|h.-|h")
  local quality = link and C_Item.GetItemQualityByID(link)
  if quality and quality >= Enum.ItemQuality.Rare then
    Play("loot")
  end
end

-- money changed: play when it grows
function events.PLAYER_MONEY()
  local money = GetMoney()
  if money > lastMoney then
    Play("money")
  end
  lastMoney = money
end

-- auction house notice while the auction house is closed: auction sold
function events.AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION(notification)
  if notification == Enum.AuctionHouseNotification.AuctionSold then
    Play("auction")
  end
end

-- same notice while the auction house is open
events.AUCTION_HOUSE_SHOW_NOTIFICATION = events.AUCTION_HOUSE_SHOW_FORMATTED_NOTIFICATION

-- ready check started
function events.READY_CHECK()
  Play("readycheck")
end

-- dungeon or raid finder found a group
function events.LFG_PROPOSAL_SHOW()
  Play("lfg")
end

-- battleground or arena queue changed: play once when it becomes ready to enter
function events.UPDATE_BATTLEFIELD_STATUS(index)
  local status = GetBattlefieldStatus(index)
  if status == "confirm" and pvpStatus[index] ~= "confirm" then
    Play("pvp")
  end
  pvpStatus[index] = status
end

-- group invite received
function events.PARTY_INVITE_REQUEST()
  Play("invite")
end

-- whisper received, in game or through Battle.net
function events.CHAT_MSG_WHISPER()
  Play("whisper")
end

events.CHAT_MSG_BN_WHISPER = events.CHAT_MSG_WHISPER

-- new level reached
function events.PLAYER_LEVEL_UP()
  Play("levelup")
end

-- achievement earned
function events.ACHIEVEMENT_EARNED()
  Play("achievement")
end

-- quest turned in
function events.QUEST_TURNED_IN()
  Play("quest")
end

-- mail state changed: play once when new mail arrives
function events.UPDATE_PENDING_MAIL()
  local hasMail = HasNewMail()
  if hasMail and not hadMail then
    Play("mail")
  end
  hadMail = hasMail
end

-- durability changed: play once when the average drops below the threshold
function events.UPDATE_INVENTORY_DURABILITY()
  local average = Durability()
  local low = average ~= nil and ns.db ~= nil and average < ns.Get("durabilityLimit")
  if low and not gearLow then
    Play("durability")
  end
  gearLow = low
end

-- error message: bags full
function events.UI_ERROR_MESSAGE(_, message)
  if not Secret(message) and (message == ERR_INV_FULL or message == ERR_BAG_FULL) then
    Play("bagsfull")
  end
end

-- minimap marker appeared: rare or treasure, once per marker
function events.VIGNETTE_MINIMAP_UPDATED(guid, onMinimap)
  if not onMinimap or Secret(guid) or seenVignettes[guid] then
    return
  end
  seenVignettes[guid] = true
  local info = C_VignetteInfo.GetVignetteInfo(guid)
  local atlas = info and info.atlasName or ""
  if atlas:find("VignetteKill") or atlas:find("VignetteLoot") then
    Play("rare")
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

-- unit events and the units they are limited to
local UNIT_EVENTS = {
  UNIT_COMBAT = { "target", "player" }, UNIT_HEALTH = { "target" }, UNIT_SPELLCAST_SUCCEEDED = { "player" },
}

-- one frame dispatching all events above
local frame = CreateFrame("Frame")
for event in pairs(events) do
  if UNIT_EVENTS[event] then
    frame:RegisterUnitEvent(event, unpack(UNIT_EVENTS[event]))
  else
    frame:RegisterEvent(event)
  end
end
frame:SetScript("OnEvent", function(_, event, ...)
  events[event](...)
end)

-- saved state: no sound for any event by default, one second crit spam protection,
-- durability warning below 20 percent
local defaults = { critDelay = 1, durabilityLimit = 20 }
for _, event in ipairs(EVENTS) do
  defaults[event.key] = ""
end

-- layout of this addon's settings page, for controls the Settings component lacks
local function Layout()
  local title = C_AddOns.GetAddOnMetadata(ADDON, "Title") or ADDON
  for _, category in ipairs(SettingsPanel:GetAllCategories()) do
    if category:GetName() == title then
      return SettingsPanel:GetLayout(category)
    end
  end
end

-- empty row of a few pixels between groups of events
local function AddSpacer(layout)
  local spacer = CreateSettingsListSectionHeaderInitializer("")
  spacer.GetExtent = function() return 12 end
  layout:AddInitializer(spacer)
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

-- settings page: per event a sound dropdown with play button and its slider, a small gap
-- between events except within a group; game sound mutes applied once loaded
ns.Store("NoiseOnEventDB", defaults, function()
  ns.Settings()
  local layout = Layout()
  local previous
  for _, event in ipairs(EVENTS) do
    if layout and previous and not (event.group and event.group == previous.group) then
      AddSpacer(layout)
    end
    previous = event
    local choices = { { "", SoundName(event, "") } }
    if event.mute then
      table.insert(choices, { OFF, OFF })
    end
    for _, sound in ipairs(SOUNDS) do
      table.insert(choices, { sound, sound })
    end
    local onChange = event.mute and UpdateMutes or nil
    ns.Dropdown(event.key, event.label, choices, "Sound to play when " .. event.help, onChange)
    if layout then
      AddPlayButton(layout, event)
    end
    if event.slider then
      local key, label, min, max, step = unpack(event.slider)
      ns.Slider(key, label, min, max, step, label .. " for " .. event.label:lower())
    end
  end
  UpdateMutes()
end)

-- setting value for a chat argument, ignoring case: a listed sound file, off, or game for
-- events with a game sound
local function FindSound(event, word)
  word = word:lower()
  if word == OFF then
    return event.mute and OFF or ""
  elseif word == "game" and event.mute then
    return ""
  end
  for _, sound in ipairs(SOUNDS) do
    if sound:lower() == word then
      return sound
    end
  end
end

-- one chat command per event, choosing a listed sound or off
for _, event in ipairs(EVENTS) do
  ns.Command({
    name = event.key,
    help = "sound file, off" .. (event.mute and ", or game" or "") .. " when " .. event.help,
    args = { { name = "sound" } },
    run = function(args)
      local sound = FindSound(event, args.sound)
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
ns.Command({
  name = "durabilitylimit",
  help = "average durability in percent below which the gear damaged sound plays",
  args = { { name = "percent", type = "number", min = 5, max = 100 } },
  run = function(args)
    ns.Set("durabilityLimit", args.percent)
    ns.Status("Durability threshold", ns.Get("durabilityLimit") .. " %")
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
