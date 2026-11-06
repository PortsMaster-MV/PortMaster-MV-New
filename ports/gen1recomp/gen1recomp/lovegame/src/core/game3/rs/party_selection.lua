local R = require("src.core.game3.rse.init")
local M = { CANCEL = 255, NPC_TRADE = 3, DAYCARE = 6 }

function M.normalize(slot)
  slot = tonumber(slot)
  if slot and slot == math.floor(slot) and slot >= 0 and slot < 6 then return slot end
  return M.CANCEL
end

function M.commit(ctx, slot, opts)
  slot = M.normalize(slot)
  R.setSpecialVar(ctx, 0x8004, slot)
  if opts and opts.onSelect then
    local sess = R.session()
    opts.onSelect(slot, slot < 6 and sess and sess.party and sess.party[slot + 1] or nil)
  end
  return slot
end

function M.choose(ctx, adapters, opts)
  opts = opts or {}
  local N = require("src.core.game3.scripting.natives")
  local host = adapters
  if adapters and adapters.chooseParty then
    host = {}; for key, value in pairs(adapters) do host[key] = value end
    host.chooseParty = function(request, done)
      request.menuType, request.cancelValue = opts.menuType or M.NPC_TRADE, M.CANCEL
      request.nativePartyLayout = 0
      adapters.chooseParty(request, function(slot) done(M.normalize(slot)) end)
    end
  end
  local settled = false
  local function settle()
    if settled then return end
    settled = true
    M.commit(ctx, R.specialVar(ctx, 0x8004), opts)
  end
  local yielded = N.choosePartyMon(ctx, host, opts.menuType or M.NPC_TRADE)
  if not yielded then settle(); return false end
  local poll = assert(ctx.nativePoll)
  ctx.nativePoll = function()
    if not poll() then return false end
    settle()
    return true
  end
  return true
end

return M
