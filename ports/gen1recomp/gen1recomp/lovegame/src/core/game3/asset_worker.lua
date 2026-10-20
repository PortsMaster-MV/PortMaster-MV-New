local input, output = ...
local running, fatal = pcall(function()
  require("love.filesystem")
  require("love.image")
  require("love.data")
  require("love.timer")
  table.insert(package.searchers or package.loaders, 1, function(name)
    local path = name:gsub("%.", "/") .. ".lua"
    if love.filesystem.getInfo(path) then return assert(love.filesystem.load(path)) end
  end)
  local D = require("src.core.game3.asset_decode")
  while true do
    local job = input:demand()
    if job.stop then break end
    local start = love.timer.getTime()
    local ok, data, err
    if job.spec.task then
      local prepare = require("src.core.game3." .. (job.kind == "objects" and "object_prepare" or "field_cell_prepare"))
      ok, data, err = pcall(prepare[job.kind], job.spec.payload,
        function() return job.cancelSignal:getCount() > 0 end)
    else
      ok, data, err = pcall(D[job.kind], D.cache(job.spec, job.cancelSignal), job.root, job.key)
    end
    if not ok then err, data = tostring(data), nil end
    output:push({ id = job.id, data = data, error = err,
      seconds = love.timer.getTime() - start })
  end

end)
if not running then output:push({ fatal = tostring(fatal) }) end
