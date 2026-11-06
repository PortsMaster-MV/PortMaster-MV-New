local Profile = require("src.core.game3.profile")

local BattleProfile = {}

-- pokefirered/include/constants/battle_ai.h:37
local FRLG_AI_BITS = {
  CHECK_BAD_MOVE = 0,
  CHECK_VIABILITY = 1,
  TRY_TO_FAINT = 2,
  SETUP_FIRST_TURN = 3,
  RISKY = 4,
  PREFER_STRONGEST_MOVE = 5,
  PREFER_BATON_PASS = 6,
  DOUBLE_BATTLE = 7,
  HP_AWARE = 8,
  UNKNOWN = 9,
  ROAMING = 29,
  SAFARI = 30,
  FIRST_BATTLE = 31,
}

BattleProfile.DEFAULTS = {
  family = "frlg",
  aiVariant = "frlg",
  aiFlagBits = FRLG_AI_BITS,
  kinds = {
    firstBattle = "oak",
    tutorial = "oldman",
    ghost = true,
    pokedude = true,
  },
  firstBattle = nil,
  rules = {
    obedienceFocusPunchExempt = true,
    critExclusions = {},
    noExp = { link = true, trainerTower = true, eReader = true },
    pickup = "flat",
    money = "frlg",
    moneyMessageAlways = false,
    whiteout = "frlg",
    lostText = "frlg",
    legendaryAi = true,
    wildScriptedAi = true,
  },
  strings = {
    caught = "STRINGID_GOTCHAPKMNCAUGHT",
    legendaryIntro = "sText_WildPkmnAppeared2",
    -- pokefirered/src/battle_controller_safari.c:446
    safariPrompt = "gText_WhatWillPlayerThrow",
    -- pokefirered/src/battle_interface.c:1762
    safariBallsLeft = "gText_HighlightRed_Left",
    -- pokefirered/src/pokemon_summary_screen.c:3899
    hmCantForget = "gText_PokeSum_HmMovesCantBeForgotten",
  },
  -- pokefirered/src/battle_anim_special.c:1200
  sounds = { caughtIntro = "MUS_CAUGHT_INTRO", caught = "MUS_CAUGHT" },
  badgeFlags = nil,
  music = nil,
  animCacheFallback = "firered/",
}

local merged = setmetatable({}, { __mode = "k" })

local SHALLOW_MERGE = { rules = true, kinds = true, strings = true, sounds = true }

local function merge(base, over)
  if type(over) ~= "table" then return base end
  local out = {}
  for k, v in pairs(base) do out[k] = v end
  for k, v in pairs(over) do
    if SHALLOW_MERGE[k] and type(v) == "table" and type(base[k]) == "table" then
      local t = {}
      for k2, v2 in pairs(base[k]) do t[k2] = v2 end
      for k2, v2 in pairs(v) do t[k2] = v2 end
      out[k] = t
    else
      out[k] = v
    end
  end
  return out
end

local function row_for(session)
  local ok, row = pcall(Profile.forSession, session)
  if ok and type(row) == "table" then return row end
  return nil
end

function BattleProfile.forRow(row)
  if type(row) ~= "table" then return BattleProfile.DEFAULTS end
  local p = merged[row]
  if p then return p end
  p = merge(BattleProfile.DEFAULTS, row.battle)
  if p.badgeFlags == nil and p.family == "rse" and type(row.badges) == "table" then
    local base = tonumber(row.badges.flagBase)
    if base then
      local flags = {}
      for i = 1, tonumber(row.badges.count) or 8 do flags[i] = base + i - 1 end
      p.badgeFlags = flags
    end
  end
  p.gameId = row.id
  merged[row] = p
  return p
end

function BattleProfile.get(session)
  return BattleProfile.forRow(row_for(session))
end

local hosted = setmetatable({}, { __mode = "k" })

-- pokeemerald/src/battle_controllers.c:397
function BattleProfile.withHostRules(p, hostVersion)
  local byHost = hosted[p]
  if not byHost then
    byHost = {}
    hosted[p] = byHost
  end
  local out = byHost[hostVersion]
  if out then return out end
  local row = Profile.of(hostVersion)
  local h = BattleProfile.forRow(row)
  out = {}
  for k, v in pairs(p) do out[k] = v end
  out.family = row.family or h.family
  out.rules = h.rules
  out.rulesFrom = h.gameId
  byHost[hostVersion] = out
  return out
end

function BattleProfile.of(st)
  local p = BattleProfile.get(type(st) == "table" and st.session or nil)
  local host = type(st) == "table" and st.hostRules or nil
  if type(host) == "string" then return BattleProfile.withHostRules(p, host) end
  return p
end

function BattleProfile.isRse(st)
  return BattleProfile.of(st).family == "rse"
end

function BattleProfile.aiBit(p, name)
  local bit = p.aiFlagBits[name]
  if bit == nil then
    error("battle profile " .. tostring(p.gameId) .. " has no AI script bit " .. tostring(name), 2)
  end
  return 2 ^ bit
end

function BattleProfile.aiFlags(p, names)
  local v = 0
  for _, name in ipairs(names) do v = v + BattleProfile.aiBit(p, name) end
  return v
end

function BattleProfile.rule(st, name)
  return BattleProfile.of(st).rules[name]
end

function BattleProfile.constants(p)
  return require("src.core.game3.constants").of(p.gameId or "firered")
end

function BattleProfile.song(p, name)
  local id = BattleProfile.constants(p):song(name)
  if id == nil then error("battle profile: no song " .. tostring(name), 2) end
  return id
end

function BattleProfile.classNameOf(p, classId)
  classId = tonumber(classId)
  if classId == nil then return nil end
  return BattleProfile.constants(p):name("trainer_classes", classId, "TRAINER_CLASS_")
end

local function music_by_class(list, className, default)
  for _, row in ipairs(list or {}) do
    for _, c in ipairs(row.classes) do
      if c == className then return row.song end
    end
  end
  return default
end

function BattleProfile.battleSong(p, info)
  local m = p.music
  if not m then return nil end
  info = info or {}
  if info.kind and m.kinds and m.kinds[info.kind] then return BattleProfile.song(p, m.kinds[info.kind]) end
  if info.link then return BattleProfile.song(p, m.link or m.trainer) end
  if info.wild then return BattleProfile.song(p, m.wild) end
  local className = BattleProfile.classNameOf(p, info.trainerClass)
  local song = music_by_class(m.byClass, className, m.trainer)
  if className and m.rivalWallyText and className == m.rivalClass and not info.frontier
      and info.trainerName == require("src.core.game3.rom_text").plain(m.rivalWallyText) then
    song = m.trainer
  end
  return BattleProfile.song(p, song)
end

function BattleProfile.victorySong(p, info)
  local m = p.music
  if not m then return nil end
  info = info or {}
  if info.wild then return BattleProfile.song(p, m.victoryWild) end
  local className = BattleProfile.classNameOf(p, info.trainerClass)
  return BattleProfile.song(p, music_by_class(m.victoryByClass, className, m.victoryTrainer))
end

function BattleProfile.reset()
  merged = setmetatable({}, { __mode = "k" })
  hosted = setmetatable({}, { __mode = "k" })
end

return BattleProfile
