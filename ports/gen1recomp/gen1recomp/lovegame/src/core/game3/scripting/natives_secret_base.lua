local Std = require("src.core.game3.scripting.stdscripts")
local Rse = require("src.core.game3.rse.init")
local SB = require("src.core.game3.rse.secret_base")
local Decor = require("src.core.game3.rse.decoration")

local N = {}

local VAR_0x8004, VAR_0x8005, VAR_0x8006, VAR_0x8007 = 0x8004, 0x8005, 0x8006, 0x8007
local VAR_RESULT = 0x800D

local function get(ctx, id) return Rse.specialVar(ctx, id) end
local function set(ctx, id, v) Rse.setSpecialVar(ctx, id, v) end

local function setStr(ctx, adapters, i, text)
  if adapters and adapters.setStringVar then pcall(adapters.setStringVar, i, text) end
  if ctx and ctx.stringVars then ctx.stringVars[i] = text end
end

local function frontBehavior()
  local x, y = SB.frontOfPlayer()
  return require("src.core.game3.collision").behavior(x, y)
end

local function waitWarp(ctx, start)
  local done = false
  start(function() done = true end)
  if ctx then ctx.stateWait = function() return done end end
  return false
end

local function ui()
  return require("src.ui.game3.rse.decoration")
end

N.BY_NAME = {
  -- pokeemerald/src/secret_base.c:296
  GetSecretBaseTypeInFrontOfPlayer = function(ctx)
    set(ctx, VAR_0x8007, SB.typeAt(frontBehavior()))
    return false
  end,
  -- pokeemerald/src/secret_base.c:258
  CheckPlayerHasSecretBase = function(ctx)
    set(ctx, VAR_RESULT, SB.playerHasBase() and 1 or 0)
    return false
  end,
  -- pokeemerald/src/secret_base.c:365
  SetPlayerSecretBase = function()
    SB.setPlayerBase()
    return false
  end,
  -- pokeemerald/src/secret_base.c:446
  EnterSecretBase = function(ctx)
    return waitWarp(ctx, function(done) SB.enter(nil, done) end)
  end,
  -- pokeemerald/src/secret_base.c:504
  EnterNewlyCreatedSecretBase = function(ctx)
    return waitWarp(ctx, function(done) SB.enterNewlyCreated(nil, done) end)
  end,
  -- pokeemerald/src/secret_base.c:552
  InitSecretBaseDecorationSprites = function(ctx)
    local n = SB.initDecorationSprites(get(ctx, VAR_0x8004))
    set(ctx, VAR_0x8004, n)
    return false
  end,
  -- pokeemerald/src/secret_base.c:654
  SetSecretBaseOwnerGfxId = function()
    Rse.setVar("VAR_OBJ_GFX_ID_F", SB.ownerGfxId())
    return false
  end,
  -- pokeemerald/src/secret_base.c:1804
  InitSecretBaseVars = function()
    SB.initVars()
    return false
  end,
  -- pokeemerald/src/secret_base.c:720
  IsCurSecretBaseOwnedByAnotherPlayer = function(ctx)
    set(ctx, VAR_RESULT, SB.ownedByAnotherPlayer() and 1 or 0)
    return false
  end,
  -- pokeemerald/src/secret_base.c:810
  ClearAndLeaveSecretBase = function(ctx)
    return waitWarp(ctx, function(done) SB.clearAndLeave(nil, done) end)
  end,
  -- pokeemerald/src/secret_base.c:818
  MoveOutOfSecretBase = function(ctx)
    return waitWarp(ctx, function(done) SB.moveOut(nil, done) end)
  end,
  -- pokeemerald/src/secret_base.c:856
  MoveOutOfSecretBaseFromOutside = function()
    SB.moveOutFromOutside()
    return false
  end,
  -- pokeemerald/src/field_specials.c:1274
  GetSecretBaseNearbyMapName = function(ctx, adapters)
    local ok, Mapsec = pcall(require, "src.ui.game3.rse.mapsec")
    local name = ok and Mapsec.name(Rse.var("VAR_SECRET_BASE_MAP")) or ""
    setStr(ctx, adapters, 1, name)
    return false
  end,
  -- pokeemerald/src/secret_base.c:740
  CopyCurSecretBaseOwnerName_StrVar1 = function(ctx, adapters)
    setStr(ctx, adapters, 1, SB.ownerName())
    return false
  end,
  -- pokeemerald/src/secret_base.c:880
  GetCurSecretBaseRegistrationValidity = function(ctx)
    set(ctx, VAR_RESULT, SB.registrationValidity())
    return false
  end,
  -- pokeemerald/src/secret_base.c:890
  ToggleCurSecretBaseRegistry = function()
    SB.toggleRegistry()
    return false
  end,
  -- pokeemerald/src/secret_base.c:896
  ShowSecretBaseDecorationMenu = function()
    ui().open({ isPlayerRoom = false })
    return false
  end,
  -- pokeemerald/src/secret_base.c:901
  ShowSecretBaseRegistryMenu = function()
    ui().openRegistry({})
    return false
  end,
  -- pokeemerald/src/fldeff_misc.c:835
  DoSecretBasePCTurnOffEffect = function()
    require("src.core.game3.fldeff_misc").pcTurnOff(Rse.var("VAR_CURRENT_SECRET_BASE") ~= 0)
    return false
  end,
  -- pokeemerald/src/secret_base.c:1175
  GetSecretBaseOwnerAndState = function(ctx)
    local t, battled = SB.ownerAndState()
    set(ctx, VAR_0x8004, t)
    set(ctx, VAR_RESULT, battled)
    return false
  end,
  -- pokeemerald/src/secret_base.c:1170
  SetBattledOwnerFromResult = function(ctx)
    SB.setBattledOwner(get(ctx, VAR_RESULT))
    return false
  end,
  -- pokeemerald/src/secret_base.c:1163
  PrepSecretBaseBattleFlags = function()
    SB.prepBattleFlags()
    return false
  end,
  DeclinedSecretBaseBattle = function() SB.declinedBattle() return false end,
  WonSecretBaseBattle = function() SB.wonBattle() return false end,
  LostSecretBaseBattle = function() SB.lostBattle() return false end,
  DrewSecretBaseBattle = function() SB.drewBattle() return false end,
  -- pokeemerald/src/secret_base.c:1833
  CheckInteractedWithFriendsDollDecor = function()
    SB.markHigh(SB.HIGH.USED_DOLL)
    return false
  end,
  -- pokeemerald/src/secret_base.c:1839
  CheckInteractedWithFriendsCushionDecor = function()
    SB.markLow(SB.LOW.USED_CUSHION)
    return false
  end,
  CheckInteractedWithFriendsPosterDecor = function() SB.checkPoster() return false end,
  CheckInteractedWithFriendsFurnitureBottom = function() SB.checkFurnitureBottom() return false end,
  CheckInteractedWithFriendsFurnitureMiddle = function() SB.checkFurnitureMiddle() return false end,
  CheckInteractedWithFriendsFurnitureTop = function() SB.checkFurnitureTop() return false end,
  CheckInteractedWithFriendsSandOrnament = function() SB.checkSandOrnament() return false end,
  -- pokeemerald/src/fldeff_misc.c:1119
  InteractWithShieldOrTVDecoration = function(ctx, adapters)
    local result, count, metal = SB.shieldOrTv()
    if result then set(ctx, VAR_RESULT, result) end
    if count then setStr(ctx, adapters, 1, count) end
    if metal then
      local ok, s = pcall(Rse.text, metal)
      setStr(ctx, adapters, 2, ok and s or "")
    end
    return false
  end,
  -- pokeemerald/src/decoration.c:1282
  SetDecoration = function(ctx)
    local p = ui().pendingSprite
    if p then
      local lid = SB.setDecoration(p.decor, p.x, p.y)
      if lid then
        set(ctx, VAR_0x8005, lid)
        set(ctx, VAR_0x8006, p.x)
        set(ctx, VAR_0x8007, p.y)
      end
    end
    return false
  end,
  -- pokeemerald/src/decoration.c:2191
  PutAwayDecorationIteration = function(ctx)
    local r = ui().putAwayIteration(get(ctx, VAR_0x8004))
    set(ctx, VAR_0x8005, r.flagId or 0)
    set(ctx, VAR_RESULT, r.done and 1 or 0)
    if r.localId then set(ctx, VAR_0x8006, r.localId) end
    return false
  end,
}

for name, fn in pairs(N.BY_NAME) do
  N.BY_NAME[name] = function(ctx, adapters)
    if not Rse.session() then return false end
    return fn(ctx, adapters)
  end
end

Std.legacyHandlers(N)

return N
