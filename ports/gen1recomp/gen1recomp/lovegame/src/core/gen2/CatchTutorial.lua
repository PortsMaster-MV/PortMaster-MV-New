-- The DUDE's catching demonstration (engine/events/catch_tutorial.asm).
--
-- `catchtutorial BATTLETYPE_TUTORIAL` on Route 29 is a REAL battle, not a
-- cutscene: CatchTutorial swaps the player's name for the DUDE's, hands him a
-- pack of his own, arms an auto-input stream and then farcalls StartBattle.
-- Everything the DUDE does inside that battle is the auto-input ring
-- (src/core/gen2/AutoInput.lua) answering the prompts, which is why the demo
-- reads as somebody playing rather than as a scripted animation.
--
-- What BATTLETYPE_TUTORIAL changes inside the battle itself, all of it from
-- engine/battle/core.asm and engine/items/item_effects.asm:
--
--   * no mon is sent out (`jp z, .tutorial_debug` straight to BattleMenu), so
--     the player's box keeps a trainer back-pic for the whole battle and there
--     is no player HUD;
--   * GetTrainerBackpic swaps ChrisBackpic for DudeBackpic;
--   * BattleMenu skips UpdateBattleHuds and EmptyBattleTextbox, so whatever
--     the textbox already said stays under the menu;
--   * BattleMenu_Pack takes `.tutorial`: TutorialPack shows the DUDE's pack,
--     its answer is thrown away (`wPackUsedItem` = FALSE) and POKE_BALL is
--     used regardless;
--   * PokeBallEffect jumps to `.catch_without_fail`, and its tail returns
--     early for a tutorial battle, so nothing is added to the party, nothing
--     is written to the Pokedex and no ball is taken out of the bag.
--
-- The port keeps all of that here and in src/ui/gen2/BattleState.lua's
-- `tutorial` arm rather than in a Gen 1-shaped fork.

local AutoInput = require("src.core.gen2.AutoInput")

local CatchTutorial = {}

-- CatchTutorial.Dude: `db "DUDE@"`.
CatchTutorial.DUDE_NAME = "DUDE"

-- wBattleType (constants/battle_constants.asm), the value Route 29's three
-- `catchtutorial` commands carry.
CatchTutorial.BATTLETYPE_TUTORIAL = 3

-- .LoadDudeData, as a flat id -> count bag of the shape PackMenu reads.
--
-- The POKE_BALL count really is 5: the routine writes the ball's own item id
-- into the quantity byte as well,
--
--   ld a, POKE_BALL
--   ld [hli], a  ; the item
--   ld [hli], a  ; its quantity
--
-- and POKE_BALL is 5 in constants/item_constants.asm.  It is invisible on the
-- cart only because the DUDE never gets to a second throw.  Reproduced rather
-- than tidied to 1, the same way src/battle/gen2/Catching.lua reproduces the
-- catch-rate bugs: a "fixed" pack shows the player a screen the game never
-- draws.
CatchTutorial.PACK = { POTION = 1, POKE_BALL = 5 }

-- The ball the demo always throws, whatever TutorialPack came back with.
CatchTutorial.BALL = "POKE_BALL"

-- The four re-arm points, by the stream name in AutoInput.STREAMS:
--   PROMPT  home/joypad.asm .wait_input, every text box that waits for A
--   MENU    engine/battle/core.asm BattleMenu, which picks ITEM
--   PACK    engine/items/pack.asm TutorialPack, which crosses to the BALL
--           pocket and picks the POKE BALL
-- and CatchTutorial's own stream, which is armed around StartBattle and does
-- nothing but hold the player's hands off the controller.
CatchTutorial.PROMPT_STREAM = "DUDE_A"
CatchTutorial.MENU_STREAM = "DUDE_DOWN_A"
CatchTutorial.PACK_STREAM = "DUDE_RIGHT_A"
CatchTutorial.BATTLE_STREAM = "CATCH_TUTORIAL"

-- Arm one of the streams above on the ring, if there is one.  Every re-arm in
-- the ASM is guarded by `ld a, [wInputType] / or a / jr z, .skip`: the DUDE
-- only answers while an auto-input stream is already running, so a player who
-- somehow reaches these prompts by hand is never pushed around by them.
--
-- `skipIdle` drops the leading blank pairs of a stream a MENU consumes; see
-- AutoInput:skipIdle for why the two kinds of stream are paced differently.
function CatchTutorial.rearm(ring, stream, input, skipIdle)
  if not (ring and ring.isActive and ring:isActive()) then return false end
  if not AutoInput.STREAMS[stream] then return false end
  if not ring:start(stream, input) then return false end
  if skipIdle then ring:skipIdle() end
  return true
end

-- The pack TutorialPack draws: wDudeNumItems / wDudeNumBalls are their own
-- buffers, so this is a save-shaped shim rather than a swap of the real bag.
-- The DUDE's name rides along because the PACK's own text addresses the
-- trainer whose bag it is.
function CatchTutorial.dudeSave()
  local inventory = {}
  for id, count in pairs(CatchTutorial.PACK) do inventory[id] = count end
  return {
    player = { name = CatchTutorial.DUDE_NAME },
    inventory = inventory,
  }
end

-- The bracket CatchTutorial puts around StartBattle, in the ASM's order:
-- back the player's name up into wMomsName, copy DUDE over it, then force the
-- text delay to TEXT_DELAY_MED so the demo reads at one speed whatever the
-- player set.  Returns the state CatchTutorial.finish needs to undo it.
function CatchTutorial.begin(save, options)
  local player = save and save.player
  local state = {
    name = player and player.name,
    textSpeed = options and options.textSpeed,
  }
  if player then
    -- `ld hl, wPlayerName / ld de, wMomsName / call CopyBytes`.  This is not
    -- scratch space: wMomsName is where InitializeNPCNames put "MOM", and the
    -- tutorial overwrites it and never puts it back, so from here on the <MOM>
    -- character prints the player's name.  A real, observable cart quirk, kept
    -- for the same reason the catch-rate bugs are kept.
    save.mom = save.mom or {}
    save.mom.name = player.name
    player.name = CatchTutorial.DUDE_NAME
  end
  if options then
    -- `and ~TEXT_DELAY_MASK / add TEXT_DELAY_MED`: only the delay field is
    -- touched, every other option bit survives.
    options.textSpeed = "MID"
  end
  return state
end

-- The tail of .DudeTutorial: `pop af / ld [wOptions], a`, then the player's
-- name is copied back out of wMomsName.  Mom's name is NOT restored, because
-- the cart has nowhere left to restore it from.
function CatchTutorial.finish(save, options, state)
  state = state or {}
  local player = save and save.player
  if player and state.name then player.name = state.name end
  if options and state.textSpeed then options.textSpeed = state.textSpeed end
end

return CatchTutorial
