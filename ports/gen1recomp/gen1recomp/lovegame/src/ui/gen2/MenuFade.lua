-- ../pokecrystal/home/map.asm:1910-1917 FadeToMenu
-- ../pokecrystal/home/map.asm:1919-1940 CloseSubmenu / FinishExitMenu

local Chrome = require("src.ui.gen2.Chrome")
local GameVersion = require("src.core.GameVersion")

local MenuFade = {}
MenuFade.__index = MenuFade
MenuFade.isOpaque = false
MenuFade.BG_WORLD_DIM = 0

-- ../pokecrystal/engine/tilesets/timeofday_pals.asm:122-127, :277-287
local OUT_STEPS = 4
local STEP_FRAMES = 2
local OUT_FRAMES = OUT_STEPS * STEP_FRAMES
-- ../pokecrystal/engine/tilesets/timeofday_pals.asm:115-120, :289-299
local IN_STEPS = 3
local IN_RAMP_FRAMES = IN_STEPS * STEP_FRAMES

-- ../pokecrystal/engine/gfx/load_font.asm:67-89
-- ../pokecrystal/engine/gfx/dma_transfer.asm:483, :548
local PARTY_FONT_FRAMES = 3
-- ../pokecrystal/engine/menus/start_menu.asm:503-518
local PARTY_WHITE = 4 + PARTY_FONT_FRAMES + 4
-- ../pokecrystal/engine/gfx/mon_icons.asm:287-297
local PARTY_ICON_FRAMES = 3
-- ../pokecrystal/engine/items/pack.asm:1330-1365, :1439-1444
local PACK_RELOAD_FRAMES = 2
local PACK_WHITE = 4 + 4 + PACK_RELOAD_FRAMES + 2 + 4
-- ../pokecrystal/engine/pokegear/pokegear.asm:73-111, :291-301
local GEAR_RELOAD_FRAMES = 5
local GEAR_WHITE = 4 + 4 + GEAR_RELOAD_FRAMES + 7
-- ../pokecrystal/engine/pokegear/pokegear.asm:53-63
local GEAR_EXIT_WHITE = 4
-- ../pokecrystal/engine/menus/trainer_card.asm:41-72
local CARD_RELOAD_FRAMES = 2
local CARD_WHITE = 4 + 4 + CARD_RELOAD_FRAMES + 4
-- ../pokecrystal/engine/pokedex/pokedex.asm:44, :78-81, :216-252, :2422-2450, :2566-2573
local DEX_RELOAD_FRAMES = 6
local DEX_WHITE = 4 + 4 + DEX_RELOAD_FRAMES + 1 + 8 + 4
-- ../pokecrystal/engine/menus/options_menu.asm:19-51
local OPTION_WHITE = 4 + 4

MenuFade.OUT_FRAMES = OUT_FRAMES
MenuFade.OUT_WHITE_FRAMES = STEP_FRAMES
MenuFade.IN_RAMP_FRAMES = IN_RAMP_FRAMES
MenuFade.PARTY_FONT_FRAMES = PARTY_FONT_FRAMES
MenuFade.PARTY_WHITE = PARTY_WHITE
MenuFade.PARTY_ICON_FRAMES = PARTY_ICON_FRAMES
MenuFade.PACK_RELOAD_FRAMES = PACK_RELOAD_FRAMES
MenuFade.PACK_WHITE = PACK_WHITE
MenuFade.GEAR_RELOAD_FRAMES = GEAR_RELOAD_FRAMES
MenuFade.GEAR_WHITE = GEAR_WHITE
MenuFade.GEAR_EXIT_WHITE = GEAR_EXIT_WHITE
MenuFade.CARD_RELOAD_FRAMES = CARD_RELOAD_FRAMES
MenuFade.CARD_WHITE = CARD_WHITE
MenuFade.DEX_RELOAD_FRAMES = DEX_RELOAD_FRAMES
MenuFade.DEX_WHITE = DEX_WHITE
MenuFade.OPTION_WHITE = OPTION_WHITE

-- ../pokecrystal/engine/menus/start_menu.asm:444-518
local OPEN_WHITE = {
  pokemon = function(partySize)
    local extra = GameVersion.engine() == "gs" and 3 or 0
    return PARTY_WHITE + extra + PARTY_ICON_FRAMES * (partySize or 0)
  end,
  pack = function() return PACK_WHITE end,
  pokegear = function() return GEAR_WHITE end,
  status = function() return CARD_WHITE end,
  pokedex = function() return DEX_WHITE end,
  option = function() return OPTION_WHITE end,
}

function MenuFade.openWhite(id, partySize)
  local page = OPEN_WHITE[id]
  return page and page(partySize) or nil
end

function MenuFade.exitWhite()
  return require("src.world.gen2.World").MENU_EXIT_WHITE_FRAMES
end

function MenuFade.closeWhite(id)
  if not OPEN_WHITE[id] then return nil end
  local white = MenuFade.exitWhite()
  if id == "pokegear" then white = white + GEAR_EXIT_WHITE end
  return white
end

function MenuFade.framesOut(white) return OUT_FRAMES + white end
function MenuFade.framesIn(white) return white + IN_RAMP_FRAMES end

function MenuFade.new(game, opts)
  opts = opts or {}
  local kind = opts.kind or "out"
  local white = opts.white or 0
  local self = setmetatable({
    game = game,
    kind = kind,
    white = white,
    onDone = opts.onDone,
    frame = 1,
  }, MenuFade)
  self.total = (kind == "out") and MenuFade.framesOut(white)
    or MenuFade.framesIn(white)
  return self
end

function MenuFade:level()
  local f = self.frame
  if self.kind == "out" then
    if f >= OUT_FRAMES then return 1 end
    return math.ceil(f / STEP_FRAMES) / OUT_STEPS
  end
  if f <= self.white then return 1 end
  local k = math.ceil((f - self.white) / STEP_FRAMES)
  return math.max(0, (OUT_STEPS - k) / OUT_STEPS)
end

function MenuFade:update()
  self.frame = self.frame + 1
  if self.frame <= self.total then return end
  local done = self.onDone
  self.onDone = nil
  local stack = self.game and self.game.stack
  if stack and stack:top() == self then stack:pop() end
  if done then done() end
end

function MenuFade:bgMode() return "world" end

function MenuFade:drawsWidescreen() return true end

local function sheet(w, h, a)
  local G = love.graphics
  G.setColor(1, 1, 1, a)
  G.rectangle("fill", 0, 0, w, h)
  G.setColor(1, 1, 1, 1)
end

function MenuFade:drawWidescreen(w, h)
  local G = love.graphics
  local stack = self.game and self.game.stack
  if stack and stack.states then
    local world = self.game.world
    local scale = (world and world.fitScale) and world:fitScale()
      or Chrome.fitScale(w, h)
    local ox, oy = Chrome.fitOrigin(w, h, scale)
    G.push()
    G.translate(ox, oy)
    G.scale(scale, scale)
    for i = stack:visibleBase(), #stack.states do
      local state = stack.states[i]
      if state ~= self and state.draw and stack:renderVisible(state) then
        state:draw()
      end
    end
    G.pop()
  end
  sheet(w, h, self:level())
end

function MenuFade:draw()
  sheet(Chrome.SCREEN_W * 8, Chrome.SCREEN_H * 8, self:level())
end

return MenuFade
