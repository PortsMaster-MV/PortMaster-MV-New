local A = require("src.import.gba.rs.assets")
local K = require("src.import.gba.rse.boot_gfx")
local Bake = require("src.import.gba.bg_bake")
local IR = require("src.core.game3.scripting.text_ir")
local M = { SUB = "credits_rse", FILES = { "the_end.rgba", "the_end_blank.rgba", "grass.rgba", "brendan_credits.png", "may_credits.png", "ampersand.4bpp" } }
M.REQUIRED = K.required(M.SUB, M.FILES)
local function bytes(s) local a = {}; for i = 1, #s do a[i] = s:byte(i) end; a._len = #s; return a end
local function map(entries)
  local a = {}; for i = 0, 1023 do local n = entries[i] or 1; a[i * 2 + 1], a[i * 2 + 2] = n % 256, math.floor(n / 256) end
  a._len = 2048; return a
end
local function opaque(s, color)
  local r, g, b = Bake.bgr555ToRgb8(color); local bg, out = string.char(r, g, b, 255), {}
  for i = 1, #s, 4 do out[#out + 1] = s:byte(i + 3) == 0 and bg or s:sub(i, i + 3) end
  return table.concat(out)
end
function M.run(rom, cache, opts)
  local c = require("src.import.gba.rs.scoped_symbols").bind(A.context(rom, cache, opts, M.SUB))
  local O = "credits.o:"
  local tableOff = c:off(O .. "gCreditsEntryPointerTable")
  assert(c.S.size(O .. "gCreditsEntryPointerTable") == 52 * 5 * 4, "RS English credits52 pages/five rows")
  local pages = {}
  for page = 0, 51 do
    local rows = {}
    for row = 0, 4 do
      local entry = assert(c:ptr(tableOff + (page * 5 + row) * 4), "RS credits entry pointer")
      local text = assert(c:ptr(entry + 4), "RS credits text pointer")
      local raw = {}; for i = 0, 1023 do local b = c:u8(text + i); raw[#raw + 1] = b; if b == 255 then break end end
      assert(raw[#raw] == 255, "RS credits unterminated text")
      local title = raw[1] == 0xFC and raw[2] == 3 and raw[3] == 9
      rows[#rows + 1] = { isTitle = title, text = IR.toPlain(IR.decode(raw, { dialect = "rs" }), {}), raw = raw,
        nativeX = c:u8(entry), palette = title and 9 or 8 }
    end
    pages[#pages + 1] = rows
  end
  local palette = K.palList(c:pal(O .. "gUnknown_0840B7BC", 32), 0, 32)
  local copy = Bake.loadPalBanks(bytes(c:raw("gIntroCopyright_Pal", 32)), 1)
  local gfx = bytes(c:lz("gCreditsCopyrightEnd_Gfx")); local entries = {}
  for _, letter in ipairs({ {"T",3}, {"H",7}, {"E",11}, {"E",16}, {"N",20}, {"D",24} }) do
    local off = c:off(O .. "sTheEnd_LetterMap_" .. letter[1])
    assert(c.S.size(O .. "sTheEnd_LetterMap_" .. letter[1]) == 15, "RS credits letter shape")
    for y = 0, 4 do for x = 0, 2 do
      local v = c:u8(off + y * 3 + x)
      entries[(7 + y) * 32 + letter[2] + x] = v == 255 and 1 or v % 64 + 80 + math.floor(v / 128) % 2 * 2048 + math.floor(v / 64) % 2 * 1024
    end end
  end
  c:write("the_end.rgba", opaque(Bake.bakeRegionRgba(gfx, copy, map(entries), 240, 160, {alpha0=true}), copy[0][0]))
  c:write("the_end_blank.rgba", opaque(Bake.bakeRegionRgba(gfx, copy, map({}), 240, 160, {alpha0=true}), copy[0][0]))
  local grassPal = Bake.loadPalBanks(bytes(c:raw("gBirchBagGrassPal", 64)), 2); grassPal[0][0] = 0
  c:write("grass.rgba", opaque(Bake.bakeRegionRgba(bytes(c:lz("gBirchHelpGfx")), grassPal, bytes(c:lz("gBirchGrassTilemap")), 240, 160,
    { y0=32, alpha0=true }), 0))
  local animations = {}
  for _, def in ipairs({ {"animsPlayer", "gSpriteAnimTable_0840CA54", 4}, {"animsRival", "gSpriteAnimTable_0840CA94", 3} }) do
    local rows = c:readAnimTable(c:off(O .. def[2]), def[3], "credits.o")
    for _, row in ipairs(rows) do for _, cmd in ipairs(row) do if cmd.op == "frame" then cmd.frame = cmd.tile / 64 end end end
    animations[def[1]] = rows
  end
  local riders = {}
  for _, name in ipairs({ "brendan", "may" }) do
    local title = name == "brendan" and "Brendan" or "May"
    local raw = c:lz("gIntro2" .. title .. "Tiles")
    assert(#raw >= 0x3800, "RS credits seven native rider frames")
    riders[name .. "_credits"] = c:strip(name .. "_credits", raw, 64, 64, 7, c:pal("gIntro2" .. title .. "Palette", 16))
  end
  c:write("ampersand.4bpp", c:raw(O .. "gUnknown_0840B7FC"))
  return A.finish(c, { format_version = 1, creditsVersion = 2, pageCount = 52, entriesPerPage = 5, pages = pages,
    palette = palette, animsPlayer = animations.animsPlayer, animsRival = animations.animsRival,
    monSpritePos = A.pairs(c, O .. "sMonSpritePos"), credits = riders, numMonSlides = 68,
    pageTransitions = { [6]={mode=2}, [12]={mode=1,scene=1}, [18]={mode=2}, [24]={mode=1,scene=2},
      [30]={mode=2}, [35]={mode=1,scene=3}, [40]={mode=2}, [46]={mode=1,scene=4} },
    textWindow = { font=3, textMode=2, letterSpacing=0, foreground=1, shadow=2, top=9, vofs=-4 },
    theEnd="the_end.rgba", theEndBlank="the_end_blank.rgba", grass="grass.rgba" })
end
function M.ready(cache, root)
  if not A.ready(M.SUB, cache, root) then return false end
  local prefix = (root or "data/generated/gba") .. "/" .. M.SUB .. "/"
  local chunk = load(cache:read(prefix .. "manifest.lua"), "@RS credits readiness", "t", {})
  if not chunk then return false end
  local ok, man = pcall(chunk)
  if not ok or man.creditsVersion ~= 2 or man.theEnd ~= "the_end.rgba"
      or man.theEndBlank ~= "the_end_blank.rgba" or man.pageCount ~= 52
      or man.entriesPerPage ~= 5 or man.numMonSlides ~= 68 then return false end
  for _, file in ipairs(M.FILES) do if not cache:exists(prefix .. file) then return false end end
  return true
end
return M
