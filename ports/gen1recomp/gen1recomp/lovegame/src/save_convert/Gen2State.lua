local Gen2Syms = require("src.save_convert.Gen2Syms")

local Gen2State = {}

Gen2State.MODULES = {
  "src.save_convert.gen2_state.core",
  "src.save_convert.gen2_state.daycare_wild",
  "src.save_convert.gen2_state.clock_phone",
  "src.save_convert.gen2_state.progress",
}

local loaded

local function modules()
  if loaded then return loaded end
  loaded = {}
  for _, path in ipairs(Gen2State.MODULES) do
    local ok, mod = pcall(require, path)
    if ok and type(mod) == "table" then
      loaded[#loaded + 1] = mod
    elseif not ok and not tostring(mod):find("module '" .. path .. "' not found", 1, true) then
      error(mod, 0)
    end
  end
  return loaded
end

function Gen2State.symsFor(gameVersion)
  if gameVersion == "crystal" then return Gen2Syms.crystal end
  return Gen2Syms.goldSilver
end

function Gen2State.decode(ctx, decoded)
  for _, mod in ipairs(modules()) do
    if mod.decode then mod.decode(ctx, decoded) end
  end
end

function Gen2State.encode(ctx, save)
  for _, mod in ipairs(modules()) do
    if mod.encode then mod.encode(ctx, save) end
  end
end

function Gen2State.modules()
  return modules()
end

return Gen2State
