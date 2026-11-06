local Gen2Layout = require("src.save_convert.Gen2Layout")
local Gen2Syms = require("src.save_convert.Gen2Syms")

local function sceneSpan(L)
  local lo, hi = math.huge, 0
  for _, off in pairs(L.sceneVars) do
    if off < lo then lo = off end
    if off > hi then hi = off end
  end
  return lo, hi + 1 - lo
end

local gsLo, gsLen = sceneSpan(Gen2Layout.goldSilver)
local cLo, cLen = sceneSpan(Gen2Layout.crystal)

local gs, cr = Gen2Syms.goldSilver, Gen2Syms.crystal
local FILLER = "unnamed padding between named WRAM runs, the engine has no field there"

local rows = {
  { both = { "wPlayerID", "wRedsName" }, mode = "modeled", keys = { "player.id", "player.name", "mom.name", "rival.name" } },
  { both = { "wRedsName", "wSavedAtLeastOnce" }, mode = "static", why = "RED and GREEN are literals NewGame writes",
    scan = { "redsName", "greensName" } },
  { both = { "wGameTimeHours", len = 5 }, mode = "modeled", keys = { "playTime" } },
  { both = { "wGameTimeFrames", plus = 1, len = 2 }, mode = "static", why = "padding after the frame counter",
    scan = { "gameTimePad" } },
  { both = { "wObjectFollow_Leader", "wObjectStructs" }, mode = "static",
    why = "follow leader and movement queue, the engine has no follower", scan = { "followMovementQueue", "objectFollow" } },
  { both = { "wObjectStructs", len = 13 * 0x28 }, mode = "modeled", keys = { "position.x", "position.y", "position.facing", "position.map", "mapObjectMasks" } },
  { both = { "wCmdQueue", "wMapObjects" }, mode = "static", why = "script command queue, cleared on every map setup",
    scan = { "cmdQueue" } },
  { both = { "wMapObjects", "wObjectMasks" }, mode = "modeled", keys = { "position.map", "position.x", "position.y", "mapObjectMasks" } },
  { both = { "wObjectMasks", "wVariableSprites" }, mode = "modeled", keys = { "position.map", "mapObjectMasks" } },
  { both = { "wVariableSprites", len = 16 }, mode = "modeled", keys = { "variableSprites" } },
  { gs = { "wUnusedReanchorBGMapFlags", "wStatusFlags" }, crystal = { "wMapNameSignFlags", "wStatusFlags" }, mode = "static",
    why = "time of day palette and sign flags, recomputed from the clock and the map on load; Crystal wSecretID has no engine counterpart",
    scan = { "secretId", "timeOfDayPal", "mapNameSign" } },
  { both = { "wStatusFlags", "wMoney" }, mode = "modeled", keys = { "engineFlags" } },
  { both = { "wMoney", "wMomsMoney" }, mode = "modeled", keys = { "player.money" } },
  { both = { "wMomsMoney", "wCoins" }, mode = "modeled", keys = { "mom.savedMoney", "mom.active", "mom.savingMoney" } },
  { both = { "wCoins", "wBadges" }, mode = "modeled", keys = { "player.coins" } },
  { both = { "wBadges", "wTMsHMs" }, mode = "modeled", keys = { "player.badges", "player.kantoBadges" } },
  { both = { "wTMsHMs", "wNumItems" }, mode = "modeled", keys = { "inventory" } },
  { both = { "wNumItems", "wNumPCItems" }, mode = "modeled", keys = { "inventory", "bagOrder", "cartBag" } },
  { both = { "wNumPCItems", "wPokegearFlags" }, mode = "modeled", keys = { "pcItems", "pcOrder", "cartBag" } },
  { both = { "wPokegearFlags", "wRadioTuningKnob" }, mode = "modeled", keys = { "engineFlags" } },
  { both = { "wPlayerState", len = 1 }, mode = "modeled", keys = { "playerState" } },
  { gs = { abs = gsLo, len = gsLen }, crystal = { abs = cLo, len = cLen }, mode = "modeled", keys = { "mapScenes" } },
  { gs = { abs = gsLo + gsLen, len = gs.wEventFlags - (gsLo + gsLen) }, mode = "static", why = FILLER, scan = { "scenePadding" } },
  { crystal = { abs = cLo + cLen, len = cr.wJackFightCount - (cLo + cLen) }, mode = "static", why = FILLER, scan = { "scenePadding" } },
  { crystal = { "wJackFightCount", len = 28 }, mode = "modeled", keys = { "scriptMem" } },
  { crystal = { abs = cr.wJackFightCount + 28, len = cr.wEventFlags - (cr.wJackFightCount + 28) }, mode = "static", why = FILLER,
    scan = { "scenePadding" } },
  { both = { "wEventFlags", len = 256 }, mode = "modeled", keys = { "events" } },
  { gs = { "wUnusedLinkCommunicationByte", "wCurBox" }, mode = "static",
    why = "link scratch, game timer pause and joypad lock are session state", scan = { "gameTimerPaused", "joypadDisable" } },
  { both = { "wCurBox", len = 3 }, mode = "modeled", keys = { "currentBox" } },
  { both = { "wBoxNames", len = 14 * 9 }, mode = "modeled", keys = { "boxNames" } },
  { gs = { "wBoxNames", plus = 14 * 9, len = 2 }, mode = "static", why = FILLER, scan = { "boxNamePadding" } },
  { both = { "wCurMapSceneScriptPointer", "wDecoBed" }, mode = "static",
    why = "map header pointers, MapSetupScript_Continue rebuilds them from the ROM", scan = { "curMapSceneScript" } },
  { both = { "wWhichMomItem", "wMomItemTriggerBalance" }, mode = "modeled", keys = { "mom.whichItem" } },
  { both = { "wMomItemTriggerBalance", len = 3 }, mode = "modeled", keys = { "mom.triggerBalance" } },
  { both = { "wVisitedSpawns", "wDigWarpNumber" }, mode = "modeled", keys = { "engineFlags" } },
  { both = { "wMapGroup", "wScreenSave" }, mode = "modeled", keys = { "position.map", "position.x", "position.y" } },
  { both = { "wScreenSave", "wPartyCount" }, mode = "modeled", keys = { "position.map", "position.x", "position.y" } },
  { both = { "wPartyCount", "wPokedexCaught" }, mode = "modeled", keys = { "party" } },
  { both = { "wPokedexCaught", "wPokedexSeen" }, mode = "modeled", keys = { "pokedex.caught" } },
  { both = { "wPokedexSeen", "wUnownDex" }, mode = "modeled", keys = { "pokedex.seen" } },
  { both = { "wUnownDex", "wUnlockedUnowns" }, mode = "modeled", keys = { "unownDex" } },
  { both = { "wUnlockedUnowns", len = 1 }, mode = "modeled", keys = { "engineFlags" } },
  { both = { "wFirstUnownSeen", len = 1 }, mode = "modeled", keys = { "firstUnownSeen" } },
  { gs = { abs = gs.wOTPartyData, len = Gen2Layout.goldSilver.sGameDataEnd - gs.wOTPartyData }, mode = "static",
    why = "WRAM union of link opponent data and pokedex pointers, never saved meaningfully and never written by the engine",
    scan = { "otPartyData", "pokedexShowPointer", "dudeNumItems" } },
}

return { coverage = rows }
