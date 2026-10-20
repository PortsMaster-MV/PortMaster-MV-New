local RequireGuard = {}

local searcher

local function chain()
  if not package then return nil end
  return package.loaders or package.searchers
end

function RequireGuard.capture()
  if searcher then return false end
  local loaders = chain()
  if not loaders then return false end
  if not (love and love.filesystem) then return false end
  if type(loaders[2]) ~= "function" then return false end
  searcher = loaders[2]
  return true
end

function RequireGuard.captured()
  return searcher ~= nil
end

function RequireGuard.present()
  local loaders = chain()
  if not searcher or not loaders then return true end
  for i = 1, #loaders do
    if loaders[i] == searcher then return true end
  end
  return false
end

function RequireGuard.repair()
  if RequireGuard.present() then return false end
  local loaders = chain()
  if not loaders then return false end
  table.insert(loaders, math.min(2, #loaders + 1), searcher)
  return true
end

return RequireGuard
