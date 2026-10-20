local C = require("src.core.game3.constants").of("ruby")
local Capabilities = require("src.core.game3.capabilities")

local Rs = {}

function Rs.new(game, label, prefix)
  return {
    id = game, label = label, family = "rse", generation = 3, engine = "game3",
    optionsBlock = game,
    map = {
      prefixes = { prefix }, enginePrefix = prefix, legacyPrefixes = {},
      kindsFromMapType = true, strictConnections = true,
      -- pokeruby/src/overworld.c:574
      scriptConnections = true, scriptStepEvents = false,
      -- pokeruby/src/field_fadetransition.c:195
      onFrameAfterWarpExit = true,
      fieldModules = {},
      -- pokeruby/src/overworld.c:496
      escapeWarp = { delta = 1 },
      semantics = {
        vars = {
          happinessSteps = "VAR_HAPPINESS_STEP_COUNTER",
          poisonSteps = "VAR_POISON_STEP_COUNTER",
          repelSteps = "VAR_REPEL_STEP_COUNT",
        },
        flags = { flashActive = "FLAG_SYS_USE_FLASH" },
      },
      -- pokeruby/src/event_data.c:35
      tempFieldEventFlags = {
        "FLAG_SYS_ENC_UP_ITEM", "FLAG_SYS_ENC_DOWN_ITEM", "FLAG_SYS_USE_STRENGTH",
        "FLAG_SYS_CTRL_OBJ_DELETE",
      },
      -- pokeruby/src/new_game.c:137
      newGameStart = {
        map = prefix .. "INSIDE_OF_TRUCK", group = "MAP_INSIDE_OF_TRUCK",
        x = 2, y = 2, facing = "down",
      },
    },
    -- pokeruby/include/constants/species.h:418
    species = { num = 412, egg = 412 },
    badges = {
      count = 8, flagBase = C:require("flags", "FLAG_BADGE01_GET"),
      names = { "STONE", "KNUCKLE", "DYNAMO", "HEAT", "BALANCE", "FEATHER", "MIND", "RAIN" },
    },
    capabilities = Capabilities.compose(Capabilities.RSE, {
      mysteryGift = false, unionRoom = false, mirageTower = false,
      trainersEyes = true, matchCall = false, battleFrontier = false,
      battleTents = false, battlePyramid = false, pyramidBag = false,
      frontierPass = false, apprentice = false, trainerHill = false,
      lilycoveLady = false, rayquazaScene = false,
    }),
    -- pokeruby/src/clock.c:27
    clock = require("src.core.game3.profiles.rs.clock"),
    dex = {
      regional = "hoenn", regionalPack = "pokemon/hoenn.lua",
      orderPack = "pokemon/regional_dex.lua", nationalMax = 386,
      -- pokeruby/src/event_data.c:70
      national = {
        flag = "FLAG_SYS_NATIONAL_DEX", var = "VAR_NATIONAL_DEX",
        value = 0x302, magic = 0xDA, requireAll = true,
      },
      registerGate = false, evolutionGate = false,
    },
    bag = require("src.core.game3.profiles.rs.bag"),
    field = require("src.core.game3.profiles.rs.field"),
    heal = require("src.core.game3.profiles.rs.heal"),
    weather = require("src.core.game3.profiles.rs.weather"),
    encounters = require("src.core.game3.profiles.rs.encounters"),
    font = require("src.core.game3.profiles.rs.font"),
    boot = require("src.core.game3.profiles.rs.boot"),
    ui = require("src.core.game3.profiles.rs.ui"),
    battle = require("src.core.game3.profiles.rs.battle").new(game),
    battleTower = require("src.core.game3.profiles.rs.battle_tower"),
    daycare = require("src.core.game3.rs.daycare"),
    audio = require("src.core.game3.profiles.rs.audio").new(game),
    save = require("src.core.game3.profiles.rs.save"),
    saveRules = require("src.core.game3.profiles.rs.saveRules"),
    mail = {
      exportEmpty = true,
      newRecord = function(session, record)
        return require("src.core.game3.profiles.rs.mail_write").newRecord(session, record)
      end,
    },
    tv = require("src.core.game3.profiles.rs.tv"),
    oldMan = require("src.core.game3.profiles.rs.old_man_runtime"),
    secretBase = require("src.core.game3.rs.secret_base_policy"),
    nativeModules = require("src.core.game3.profiles.rs.nativeModules"),
    coreSpecials = require("src.core.game3.profiles.rs.coreSpecials"),
  }
end

return Rs
