local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local M = {SUB = "rse/move_relearner", FILES = {"hearts.png", "arrows_horizontal.png", "arrows_vertical.png"}, packVersion = 1}
M.REQUIRED = K.required(M.SUB, M.FILES)
local function window(c, name)
  local out, off = {}, c:off(name)
  for i, key in ipairs({"bg", "charbase", "screenbase", "priority", "palette", "foregroundColor",
    "backgroundColor", "shadowColor", "fontNum", "textMode", "spacing", "left", "top", "width", "height"}) do out[key] = c:u8(off + i - 1) end
  return out
end
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local gfx, pal = c:raw("gMoveTutorMenuArrows_Gfx"), c:pal("gMoveTutorMenuArrows_Pal", 16)
  assert(#gfx == 12 * 32, "native move tutor twelve tiles")
  -- move_tutor_menu.c:129
  local hearts = c:strip("hearts", gfx, 8, 8, 4, pal, 4, 8)
  hearts.names = {appealEmpty = 0, appealFull = 1, jamEmpty = 2, jamFull = 3}
  local horizontal = c:strip("arrows_horizontal", gfx, 16, 8, 2, pal, 4, 0)
  local vertical = c:strip("arrows_vertical", gfx, 8, 16, 2, pal, 4, 4)
  horizontal.templates = c:readTemplate("gSpriteTemplate_8402D90")
  vertical.templates = c:readTemplate("gSpriteTemplate_8402DC0")
  hearts.template = c:readTemplate("gSpriteTemplate_8402E08")
  local man = {screen = "move_relearner", packVersion = M.packVersion, hearts = hearts,
    arrows = {horizontal = horizontal, vertical = vertical}, palette = K.palList(pal, 0, 16),
    windows = {frames = window(c, "gMoveTutorMenuFramesWindowTemplate"), text = window(c, "gMenuTextWindowTemplate")},
    frames = {}, headers = {}, infoCoords = {}, strings = {}, textBytes = {}}
  local fo = c:off("gMoveTutorMenuWindowFrameDimensions")
  assert(c.S.size("gMoveTutorMenuWindowFrameDimensions") == 16, "native four frame rectangles")
  for i = 0, 3 do man.frames[i + 1] = {c:u8(fo + i * 4), c:u8(fo + i * 4 + 1), c:u8(fo + i * 4 + 2), c:u8(fo + i * 4 + 3)} end
  local ho = c:off("gMoveTutorMoveInfoHeaders")
  assert(c.S.size("gMoveTutorMoveInfoHeaders") == 64, "native two four-row8-byte header tables")
  for page = 0, 1 do
    local rows = {}
    for i = 0, 3 do
      local off = ho + (page * 4 + i) * 8
      local ptr = c:ptr(off)
      if ptr then rows[#rows + 1] = {text = A.text(c, ptr), x = c:u8(off + 4), y = c:u8(off + 5), index = c:u8(off + 6), alignWidth = 64, alignMode = 2} end
    end
    man.headers[page == 0 and "battle" or "contest"] = rows
  end
  local io = c:off("move_tutor_menu.o:sMoveInfoTextCoords")
  assert(c.S.size("move_tutor_menu.o:sMoveInfoTextCoords") == 21, "native seven three-byte info coordinates")
  for i = 0, 6 do man.infoCoords[i + 1] = {c:u8(io + i * 3), c:u8(io + i * 3 + 1), c:u8(io + i * 3 + 2)} end
  for _, symbol in ipairs({"gOtherText_TeachWhichMove", "gOtherText_TeachSpecificMove", "gOtherText_GiveUpTeachingMove",
    "gOtherText_Exit", "gOtherText_ThreeDashes2", "gOtherText_PokeLearnedMove", "gOtherText_DeleteOlderMove",
    "gOtherText_WhichMoveToForget", "gOtherText_StopLearningMove", "gOtherText_ForgotMove123", "gOtherText_ForgotOrDidNotLearnMove"}) do
    local bytes, off = {}, c:off(symbol)
    for i = 0, 1023 do local b = c:u8(off + i); bytes[#bytes + 1] = b; if b == 255 then break end end
    assert(bytes[#bytes] == 255, "native move tutor text termination")
    man.strings[symbol], man.textBytes[symbol] = A.text(c, off), bytes
  end
  man.geometry = {list = {88, 8, 16, 3}, listAlign = {39, 114, 144}, description = {88, 72, 144, 32},
    prompt = {24, 120, 192, 32}, horizontalArrows = {{8, 16}, {72, 16}}, verticalArrows = {{160, 4}, {160, 60}},
    hearts = {x = 28, appealY = 52, jamY = 92, columns = 4, rows = 2, spacing = 8},
    battleCoordIds = {0, 1, 2, 3}, contestCoordIds = {4, 5, 6}}
  return A.finish(c, man)
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local base = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  if not cache:read(base .. "manifest.lua"):find("packVersion = " .. M.packVersion, 1, true) then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(base .. file) then return false end end
  return true
end
return M
