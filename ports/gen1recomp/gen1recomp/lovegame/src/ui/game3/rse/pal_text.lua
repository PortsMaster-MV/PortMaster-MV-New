local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Kit = require("src.ui.game3.rse.scene_kit")

local PalText = {}

local function color(pal, idx)
  if idx == nil or idx == 0 then return { 0, 0, 0, 0 } end
  local c = pal and pal[idx + 1]
  if type(c) == "table" then return { c[1] / 255, c[2] / 255, c[3] / 255, 1 } end
  return Kit.color555(c or 0)
end
PalText.color = color

function PalText.colors(pal, ids)
  return { bg = color(pal, ids[1]), fg = color(pal, ids[2]), shadow = color(pal, ids[3]) }
end

-- pokeemerald/src/text.c:1063
local function flatten(ir, ctx, out)
  for _, node in ipairs(ir) do
    local t = node.t
    if t == "text" then
      out[#out + 1] = { s = node.s }
    elseif t == "strvar" then
      local v = ctx.vars and ctx.vars[node.n]
      if type(v) == "table" then flatten(v, ctx, out) else out[#out + 1] = { s = tostring(v or "") } end
    elseif t == "dynamic" then
      local v = ctx.dynamic and ctx.dynamic[node.n]
      if type(v) == "table" then flatten(v, ctx, out) elseif v then out[#out + 1] = { s = tostring(v) } end
    elseif t == "nl" or t == "para" then
      out[#out + 1] = { nl = true }
    elseif t == "ext" then
      local a = node.args or {}
      if node.cmd == 0x01 then out[#out + 1] = { fg = a[1] }
      elseif node.cmd == 0x02 then out[#out + 1] = { bg = a[1] }
      elseif node.cmd == 0x03 then out[#out + 1] = { shadow = a[1] }
      elseif node.cmd == 0x04 then out[#out + 1] = { fg = a[1], bg = a[2], shadow = a[3] }
      elseif node.cmd == 0x11 then out[#out + 1] = { clear = a[1] or 0 }
      elseif node.cmd == 0x13 then out[#out + 1] = { clearto = a[1] or 0 }
      end
    elseif t == "tag" then
      out[#out + 1] = { s = node.tag }
    elseif t == "player" then
      out[#out + 1] = { s = tostring(ctx.playerName or "") }
    end
  end
  return out
end

function PalText.segments(source, ctx)
  ctx = ctx or {}
  local ir = source
  if type(source) == "string" then
    if RomText.has(source) then ir = RomText.ir(source) else ir = { { t = "text", s = source } } end
  end
  return flatten(ir, ctx, {})
end

function PalText.width(source, ctx)
  local w, best = 0, 0
  local opts = ctx and ctx.font and { font = ctx.font } or nil
  for _, seg in ipairs(PalText.segments(source, ctx)) do
    if seg.s then w = w + FrlgFont.measure(seg.s, opts)
    elseif seg.clear then w = w + seg.clear
    elseif seg.clearto then w = math.max(w, seg.clearto)
    elseif seg.nl then best = math.max(best, w); w = 0 end
  end
  return math.max(best, w)
end

function PalText.draw(source, x, y, ctx)
  ctx = ctx or {}
  local pal = ctx.pal
  local ids = { ctx.colors and ctx.colors[1] or 0, ctx.colors and ctx.colors[2] or 2, ctx.colors and ctx.colors[3] or 3 }
  local pitch = ctx.pitch or FrlgFont.linePitch()
  local opts = { font = ctx.font }
  local px, py = 0, 0
  for _, seg in ipairs(PalText.segments(source, ctx)) do
    if seg.nl then
      px, py = 0, py + pitch
    elseif seg.clear then
      px = px + seg.clear
    elseif seg.clearto then
      if seg.clearto > px then px = seg.clearto end
    elseif seg.s then
      opts.colors = PalText.colors(pal, ids)
      local _, endX = FrlgFont.draw(seg.s, x + px, y + py, opts)
      px = (endX or (x + px + FrlgFont.measure(seg.s, opts))) - x
    else
      if seg.fg then ids[2] = seg.fg end
      if seg.bg then ids[1] = seg.bg end
      if seg.shadow then ids[3] = seg.shadow end
    end
  end
  return px, py
end

return PalText
