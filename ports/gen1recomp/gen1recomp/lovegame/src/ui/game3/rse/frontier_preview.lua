local M = { exchangeOpen = false, tutorOpen = false }

local function ids(file)
  local bytes = require("src.core.game3.dataset").cache():read("data/generated/gba/frontier_exchange_corner/" .. file .. ".bin")
  local out = {}
  if bytes then for i = 1, #bytes - 1, 2 do out[#out + 1] = bytes:byte(i) + bytes:byte(i + 1) * 256 end end
  return out
end
M.ids = ids

local function wrap(text, width)
  local Font, lines, line = require("src.ui.game3.frlg_font"), {}, ""
  for word in tostring(text or ""):gmatch("%S+") do
    local candidate = line == "" and word or line .. " " .. word
    if line ~= "" and Font.measure(candidate) > width then lines[#lines + 1], line = line, word else line = candidate end
  end
  if line ~= "" then lines[#lines + 1] = line end
  return lines
end

function M.draw(menu)
  local Window = require("src.core.game3.scripting.natives_listmenu").windowMod
  Window = Window and Window() or require("src.ui.game3.window")
  if not Window then return end
  local name, id, description
  if M.exchangeOpen then
    local files = { [3] = "decor1", [4] = "decor2", [5] = "vitamins", [6] = "holdItems" }
    local file = files[tonumber(menu.kind)]
    local list = file and ids(file)
    id = list and list[menu.selection() + 1]
    if id then
      if file == "decor1" or file == "decor2" then
        local info = require("src.core.game3.rse.decoration_inventory").info(id)
        description = info and info.description
      else
        local info = require("src.core.game3.items_data").info(id)
        description = info and info.description
      end
    end
    if not description then description = require("src.core.game3.rom_text").plain("gText_Exit") end
    Window.stdFrame(Window.template(0, 9, 27, 4))
    for i, line in ipairs(wrap(description, 168)) do if i <= 2 then Window.printPx(line, 50, 73 + (i - 1) * 15, { maxWidth = 166 }) end end
    if id and (file == "decor1" or file == "decor2") then
      local cache = require("src.core.game3.dataset").cache()
      local bytes = cache:read("data/generated/gba/decorations/icons.rgba")
      if bytes then
        local image = love.graphics.newImage(love.image.newImageData(24, #bytes / 4 / 24, "rgba8", bytes))
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(image, love.graphics.newQuad(0, id * 24, 24, 24, 24, select(2, image:getDimensions())), 24, 80)
      end
    elseif id then
      -- pokeemerald/src/field_specials.c:3037
      require("src.ui.game3.rse.bag_chrome").drawItemIcon(require("src.core.game3.items_data").toNumericId(id) or id, 24, 80)
    end
  elseif M.tutorOpen and (menu.kind == 9 or menu.kind == 10) then
    local moveId = ids(menu.kind == 9 and "tutor1" or "tutor2")[menu.selection() + 1]
    local moveName = moveId and require("src.core.game3.pokemon").moveName(moveId)
    local text = moveId and require("src.core.game3.summary_data").moveDescription(moveId, moveName) or require("src.core.game3.rom_text").plain("gText_Exit")
    Window.stdFrame(Window.template(1, 7, 12, 6))
    for i, line in ipairs(wrap(text, 84)) do if i <= 3 then Window.printPx(line, 8, 57 + (i - 1) * 15, { maxWidth = 82 }) end end
  end
end

return M
