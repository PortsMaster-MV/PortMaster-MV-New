local R = require("src.core.game3.rse.init")
local Size = require("src.core.game3.rs.size_records")
local M = { BY_NAME = {} }

local function constants()
  return require("src.core.game3.constants").of(R.session().version)
end
local function text(ctx, adapters, index, value)
  if adapters and adapters.setStringVar then adapters.setStringVar(index, value) end
  if ctx then ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[index] = value end
end
local function info(speciesName, varName)
  return function(ctx, adapters)
    local species, record = constants():require("species", speciesName), R.var(varName)
    text(ctx, adapters, 1, require("src.core.game3.pokemon").name(species))
    text(ctx, adapters, 2, record == 0x8100 and R.text("gOtherText_Marco")
      or tostring(R.session().name or R.session().playerName or ""))
    text(ctx, adapters, 3, Size.format(Size.size(species, record)))
    return false
  end
end
local function compare(speciesName, varName)
  return function(ctx, adapters)
    local species = constants():require("species", speciesName)
    local result, record, size = Size.compare(R.session(), species, R.var(varName), R.specialVar(ctx, 0x800D))
    if size then text(ctx, adapters, 2, Size.format(size)) end
    if result == 3 then R.setVar(varName, record) end
    R.setSpecialVar(ctx, 0x800D, result)
    return false, result
  end
end

M.BY_NAME.GetShroomishSizeRecordInfo = info("SPECIES_SHROOMISH", "VAR_SHROOMISH_SIZE_RECORD")
M.BY_NAME.CompareShroomishSize = compare("SPECIES_SHROOMISH", "VAR_SHROOMISH_SIZE_RECORD")
M.BY_NAME.GetBarboachSizeRecordInfo = info("SPECIES_BARBOACH", "VAR_BARBOACH_SIZE_RECORD")
M.BY_NAME.CompareBarboachSize = compare("SPECIES_BARBOACH", "VAR_BARBOACH_SIZE_RECORD")

return M
