-- pokeruby/src/secret_base.c:486
local R = require("src.core.game3.rse.init")
local SB = require("src.core.game3.rse.secret_base")
local M = {}
M.FILE = "data/generated/gba/rse/secret_base_battle/manifest.lua"

local function metadata()
  local source = assert(require("src.core.game3.dataset").cache():read(M.FILE), M.FILE .. " is not in the cache")
  local data = assert(load(source, "@" .. M.FILE, "t", {}))()
  return assert(data.decorations, "native RS room-decoration metadata is missing")
end

function M.init(ctx, session, grid)
  session = session or assert(R.session(), "native RS room-decoration session missing")
  local items
  if SB.curMapIsSecretBase(session) then
    items = SB.base(session, R.var("VAR_CURRENT_SECRET_BASE", session)).decorations
  else
    items = require("src.core.game3.rse.decoration").context(session, true).items
  end
  local occupied = false
  for _, decor in ipairs(items) do if decor ~= 0 then occupied = true; break end end
  if not occupied then return R.specialVar(ctx, 0x8004), {} end
  return SB.initDecorationSprites(R.specialVar(ctx, 0x8004), session, grid, {
    nativeRS = true, flagFirst = 0xAE, decorations = metadata(),
    onPosition = function(x, y)
      R.setSpecialVar(ctx, 0x8006, x); R.setSpecialVar(ctx, 0x8007, y)
    end,
    onSpawn = function(localId, counter)
      R.setSpecialVar(ctx, 0x800D, localId); R.setSpecialVar(ctx, 0x8004, counter)
    end,
  })
end

return M
