local IR = require("src.core.game3.scripting.text_ir")
local M = {}

-- pokeruby/berry.c:1042
function M.enigma(session)
  local raw = session and session.enigmaBerryNativeBytes
  if type(raw) ~= "table" or #raw < 1328 then return nil end
  for i = 1, 1328 do
    local v = raw[i]
    if type(v) ~= "number" or v < 0 or v > 255 or v % 1 ~= 0 then return nil end
  end
  if raw[21] == 0 or raw[11] == 0 then return nil end
  local sum, expected = 0, 0
  for off = 0, 1323 do if off < 12 or off >= 20 then sum = sum + raw[off + 1] end end
  for i = 0, 3 do expected = expected + raw[1325 + i] * 256 ^ i end
  if sum ~= expected then return nil end
  local function text(off, n)
    local bytes = {}
    for i = 0, n - 1 do
      local v = raw[off + i + 1]; bytes[#bytes + 1] = v
      if v == 255 then break end
    end
    return IR.toAscii(IR.decode(bytes, {dialect = "rs"}))
  end
  local pic, palette = {}, {}
  for i = 1, 1152 do pic[i] = string.char(raw[28 + i]) end
  for i = 0, 15 do palette[i + 1] = raw[1181 + i * 2] + raw[1182 + i * 2] * 256 end
  return {name = text(0, 7), firmness = raw[8], size = raw[9] + raw[10] * 256,
    description1 = text(1212, 45), description2 = text(1257, 45),
    spicy = raw[22], dry = raw[23], sweet = raw[24], bitter = raw[25], sour = raw[26],
    pic = table.concat(pic), palette = palette}
end

function M.sizeParts(size)
  local inches = math.floor(size * 1000 / 254)
  if inches % 10 >= 5 then inches = inches + 10 end
  return math.floor(inches / 100), math.floor((inches % 100) / 10)
end

function M.sizeText(man, size)
  if size == 0 then return man.strings.unknown end
  local whole, fraction = M.sizeParts(size)
  return IR.toAscii(IR.fromAscii(man.strings.sizeValue, {dialect = "rs"}),
    {stringVars = {tostring(whole), tostring(fraction)}})
end
return M
