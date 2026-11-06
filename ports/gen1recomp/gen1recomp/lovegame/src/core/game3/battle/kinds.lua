local BattleProfile = require("src.core.game3.battle.profile")

local Kinds = {}

local BOOLEAN_KINDS = {
  "wild", "double", "link", "multi", "safari", "roamer", "legendary", "wildScripted",
  "trainerTower", "eReader", "battleTower", "secretBase", "pokedude", "ghostBattle",
  "oldManTutorial", "unionRoom", "spectate",
}

local EXTRA_KINDS = {
  "twoOpponents", "partner", "recordedLink", "frontier", "trainerHill", "kyogreGroudon", "regi",
  "groudon", "kyogre", "rayquaza", "dome", "palace", "arena", "factory", "pike", "pyramid",
}

function Kinds.fromOpts(opts, st, p)
  opts = opts or {}
  p = p or BattleProfile.of(st)
  local k = {}
  for _, name in ipairs(BOOLEAN_KINDS) do
    if st and st[name] then k[name] = true end
  end
  for _, name in ipairs(EXTRA_KINDS) do
    if opts[name] then k[name] = true end
  end
  k.trainer = not (st and st.wild) or nil
  if st and st.firstBattle then
    k.firstBattle = p.kinds.firstBattle
  elseif opts.firstBattleKind ~= nil then
    if opts.firstBattleKind ~= p.kinds.firstBattle then
      error("battle kinds: " .. tostring(p.gameId) .. " has no first battle kind " .. tostring(opts.firstBattleKind), 2)
    end
    k.firstBattle = opts.firstBattleKind
  end
  if opts.tutorialKind ~= nil then
    if opts.tutorialKind ~= p.kinds.tutorial then
      error("battle kinds: " .. tostring(p.gameId) .. " has no tutorial kind " .. tostring(opts.tutorialKind), 2)
    end
    k.tutorial = opts.tutorialKind
  elseif st and st.oldManTutorial then
    k.tutorial = p.kinds.tutorial
  end
  return k
end

function Kinds.has(st, name)
  local k = st and st.kinds
  return k ~= nil and k[name] ~= nil and k[name] ~= false
end

function Kinds.isBirchFirstBattle(st)
  return st ~= nil and st.kinds ~= nil and st.kinds.firstBattle == "birch"
end

function Kinds.isWallyTutorial(st)
  return st ~= nil and st.kinds ~= nil and st.kinds.tutorial == "wally"
end

function Kinds.noCrit(st)
  local ex = BattleProfile.of(st).rules.critExclusions
  if not ex or not st or not st.kinds then return false end
  if ex.firstBattle and st.kinds.firstBattle then return true end
  if ex.wallyTutorial and st.kinds.tutorial == "wally" then return true end
  return false
end

function Kinds.noExp(st)
  if not st then return false end
  local rule = BattleProfile.of(st).rules.noExp or {}
  for name in pairs(rule) do
    if st[name] or (st.kinds and st.kinds[name]) then return true end
  end
  return false
end

-- pokeemerald/src/battle_controllers.c:112
function Kinds.controllerOf(st, id)
  if not st or id == nil then return nil end
  local k = st.kinds or {}
  if id % 2 == 1 then
    return st.link and "link" or "ai"
  end
  if st.multi and st.linkOwn ~= nil and id ~= st.linkOwn then return "link" end
  if id == 2 and k.partner then return "aiPartner" end
  if k.tutorial == "wally" then return "tutorial" end
  if st.pokedude then return "pokedude" end
  if st.oldManTutorial then return "tutorial" end
  return "player"
end

return Kinds
