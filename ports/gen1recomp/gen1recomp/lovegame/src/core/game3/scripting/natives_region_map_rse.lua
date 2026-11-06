local Std = require("src.core.game3.scripting.stdscripts")

local RegionMapNatives = {}

local function session()
  local rt = package.loaded["src.core.game3.runtime"]
  return rt and rt.getSession and rt.getSession() or nil
end

local function frameType(sess)
  local ok, Options = pcall(require, "src.core.game3.options")
  if not ok or not (Options and Options.block) then return 0 end
  local okB, block = pcall(Options.block, sess and sess.options)
  return okB and type(block) == "table" and tonumber(block.frameType) or 0
end
RegionMapNatives.frameType = frameType

RegionMapNatives.BY_NAME = {
  -- pokeemerald/src/field_specials.c:973
  FieldShowRegionMap = function(ctx, adapters)
    local Natives = require("src.core.game3.scripting.natives")
    local sess = session()
    return Natives.yieldHost(ctx, adapters, function(done)
      local Fade = require("src.ui.game3.fade")
      Fade.clear()
      require("src.ui.game3.rse.region_map").show({
        session = sess,
        mode = "wall",
        frameType = frameType(sess),
        onClose = function()
          -- pokeemerald/src/field_specials.c:970
          Fade.clear()
          Fade.begin(Fade.MODE.FROM_BLACK, 1)
          done()
        end,
      })
    end)
  end,
}
Std.legacyHandlers(RegionMapNatives)

return RegionMapNatives
