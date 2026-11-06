local Shared = require("src.ui.game3.rse.credits")
local Scenery = require("src.ui.game3.rs.credits_scenery")
local M = {}
local function options(opts)
  local out = {}; for k,v in pairs(opts or {}) do out[k]=v end
  out.scenery, out.assetLayout = Scenery, "rs"
  return out
end
function M.new(opts) return Shared.new(options(opts)) end
function M.start(opts) return Shared.start(options(opts)) end
M.finish, M.isOpen = Shared.finish, Shared.isOpen
function M.reset() return Shared.reset() end
M.handleInput, M.update, M.draw = Shared.handleInput, Shared.update, Shared.draw
return setmetatable(M,{__index=Shared})
