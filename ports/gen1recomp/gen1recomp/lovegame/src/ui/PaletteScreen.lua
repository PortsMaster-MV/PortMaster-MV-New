
local Font    = require("src.render.Font")
local Theme   = require("src.ui.Theme")
local Sound   = require("src.core.Sound")
local Strings = require("src.core.Strings")
local Palette = require("src.render.Palette")
local PaletteFX = require("src.render.PaletteFX")

local PaletteScreen = {}
PaletteScreen.__index = PaletteScreen

PaletteScreen.isOpaque = true

local COLS, ROWS = 5, 4
local TILE_W, TILE_H = 28, 20
local GAP = 4
local GRID_X, GRID_Y = 2, 14
local PER_PAGE = COLS * ROWS

local SCREEN_W, SCREEN_H = 160, 144

local BACK = 0

local function sanitize(text)
  text = tostring(text or ""):upper():gsub("_", "'")
  text = text:gsub("[^A-Z0-9 %.'%-]", " ")
  text = text:gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  return text
end

PaletteScreen.sanitize = sanitize                -- named for the suite

local function wrap(text, width, lines)
  local out = {}
  local rest = text
  for i = 1, lines do
    if rest == "" then break end
    if #rest <= width then
      out[i] = rest
      rest = ""
    else
      local cut = rest:sub(1, width + 1):match("^.*() ")
      if not cut or cut < 2 then cut = width + 1 end
      out[i] = rest:sub(1, cut - 1)
      rest = rest:sub(cut):gsub("^ +", "")
    end
  end
  if rest ~= "" and #out > 0 then
    local last = out[#out]
    out[#out] = last:sub(1, math.max(0, width - 1)) .. "."
  end
  return out
end

PaletteScreen.wrap = wrap                        -- named for the suite

local function packLabel(name, width)
  local text = sanitize(name)
  if #text > width then
    local leaf = tostring(name):match("([^/]+)$")
    if leaf then text = sanitize(leaf) end
  end
  return wrap(text, width, 1)[1] or ""
end

PaletteScreen.packLabel = packLabel              -- named for the suite


local function fill(x, y, w, h, c)
  love.graphics.setColor(c[1] / 255, c[2] / 255, c[3] / 255, 1)
  love.graphics.rectangle("fill", x, y, w, h)
end

local function frame(x, y, w, h, shade)
  love.graphics.setColor(shade, shade, shade, 1)
  love.graphics.rectangle("line", x + 0.5, y + 0.5, w - 1, h - 1)
end

local function drawSwatch(x, y, w, h, swatch)
  if not swatch then
    frame(x, y, w, h, 0.5)
    return
  end
  local band = w / 4
  for i = 1, 4 do
    fill(x + math.floor((i - 1) * band), y,
         math.ceil(band), h, swatch[i])
  end
end

PaletteScreen.drawSwatch = drawSwatch            -- named for the suite

local function drawBack(selected)
  if selected then
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", 0, 0, 10, 9)
    love.graphics.setColor(1, 1, 1, 1)
  else
    love.graphics.setColor(0, 0, 0, 1)
  end
  for i = 0, 3 do
    love.graphics.rectangle("fill", 2 + i, 4 - i, 1, 1 + i * 2)
  end
end

PaletteScreen.drawBack = drawBack                -- named for the suite


local function engineModes()
  local labels = PaletteFX.MODE_LABELS or {}
  local out = {}
  for i, id in ipairs(PaletteFX.MODES) do
    out[i] = { PaletteFX.modeLabel(id) or labels[id] or id:upper(), id }
  end
  return out
end

local function dropConflictingMode(game)
  local mode = PaletteFX.mode
  local bakes = PaletteFX.usesGbcPack(mode) or PaletteFX.usesSpriteObp(mode)
  if not bakes then return end
  local o = game.save.options
  o.colors = "gbc"
  PaletteFX.setMode("gbc")
end

local function liveOpts(game)
  dropConflictingMode(game)
  return {
    palette = Palette,
    get = function() return game.save.options.palette or "" end,
    set = function(v)
      local o = game.save.options
      o.palette = v
      if v ~= "" then dropConflictingMode(game) end
      PaletteFX.setCustomRamp(v ~= "" and Palette.ramp(v) or nil)
      if game.writeOptions then pcall(game.writeOptions, game) end
    end,
    modes = engineModes(),
    getMode = function() return game.save.options.colors or "gbc" end,
    setMode = function(v)
      local o = game.save.options
      o.colors = v
      PaletteFX.setMode(v)
      if game.writeOptions then pcall(game.writeOptions, game) end
    end,
  }
end


function PaletteScreen.new(game, opts)
  opts = opts or liveOpts(game)
  local self = setmetatable({
    game = game,
    Palette = opts.palette,
    get = opts.get, set = opts.set,
    modes = opts.modes or {},
    getMode = opts.getMode, setMode = opts.setMode,
    onChange = opts.onChange,
    view = "root",
    index = 1,
    scroll = 0,
    group = nil,
    stackTrail = {},
  }, PaletteScreen)
  self.rows = self:buildRoot()
  self:enterFromSelection()
  return self
end


function PaletteScreen:buildRoot()
  local rows = {}
  for _, category in ipairs(self.Palette and self.Palette.categories() or {}) do
    if #(category.palettes or {}) > 0 then
      rows[#rows + 1] = { label = category.name, folder = true,
                          view = "tiles", group = category }
    end
  end
  if self.Palette and self.Palette.MONO_COLOURS then
    rows[#rows + 1] = { label = "MONOCHROME", folder = true, view = "mono" }
  end
  for _, mode in ipairs(self.modes) do
    rows[#rows + 1] = { label = mode[1], mode = mode[2] }
  end
  return rows
end

function PaletteScreen:rootIndexFor(view, group)
  for i, row in ipairs(self.rows or {}) do
    if row.view == view then
      if view ~= "tiles" then return i end
      if row.group and group and row.group.key == group.key then return i end
    end
  end
  return 1
end

function PaletteScreen:enterFromSelection()
  local Palette = self.Palette
  if not Palette then return end
  local id = self.get and self.get() or ""
  if type(id) ~= "string" or id == "" then return end

  if id:match("^m:") then
    for i, c in ipairs(Palette.MONO_COLOURS) do
      if Palette.monoId(c[2], c[3], c[4]) == id then
        self:openAt("mono", nil, i)
        return
      end
    end
    return
  end

  local key, at = Palette.locate(id)
  if key then self:openAt("tiles", Palette.category(key), at) end
end

function PaletteScreen:openAt(view, group, index)
  self.stackTrail = { { view = "root", index = self:rootIndexFor(view, group),
                        scroll = 0, group = nil } }
  self.view, self.group, self.index, self.scroll = view, group, index or 1, 0
  local items = self:items()
  self:clampScroll(#items, #items + 1, PER_PAGE)
end


function PaletteScreen:items()
  local Palette = self.Palette
  if self.view == "root" then return self.rows or {} end
  if self.view == "tiles" then
    return self.group and self.group.palettes or {}
  end
  if self.view == "mono" then
    return Palette and Palette.MONO_COLOURS or {}
  end
  return {}
end

function PaletteScreen:isGrid()
  return self.view == "tiles" or self.view == "mono"
end

function PaletteScreen:idAt(i)
  local Palette = self.Palette
  if not Palette then return nil end
  if self.view == "tiles" then
    local entry = self.group and (self.group.palettes or {})[i]
    return entry and entry.id or nil
  elseif self.view == "mono" then
    local c = Palette.MONO_COLOURS[i]
    return c and Palette.monoId(c[2], c[3], c[4]) or nil
  end
  return nil
end

function PaletteScreen:title()
  if self.view == "root" then return Strings("COLOUR") end
  if self.view == "mono" then return Strings("MONOCHROME") end
  return sanitize(self.group and self.group.name or "")
end


function PaletteScreen:update()
  local input = self.game.input
  local items = self:items()
  local total = #items
  local cancel = total + 1

  if input:wasPressed("b") then
    self:back()
    return
  end

  if self:isGrid() then
    self:moveGrid(input, total, cancel)
  else
    self:moveList(input, total, cancel)
  end

  if input:wasPressed("a") then
    self:activate(cancel)
  end
end

function PaletteScreen:moveList(input, total, cancel)
  if self.index == BACK then
    if input:wasPressed("down") or input:wasPressed("right") then
      self.index = 1
    end
    return
  end
  if input:wasPressed("left") then
    self.index = BACK
    return
  end
  if input:wasPressed("up") then
    self.index = self.index > 1 and self.index - 1 or BACK
  elseif input:wasPressed("down") then
    self.index = self.index < cancel and self.index + 1 or 1
  end
  self:clampScroll(total, cancel, 12)
end

function PaletteScreen:moveGrid(input, total, cancel)
  local i = self.index

  if i == BACK then
    if input:wasPressed("down") or input:wasPressed("right") then
      self.index = self.scroll + 1
      if self.index > total then self.index = 1 end
    end
    return
  end

  if i > total then
    if input:wasPressed("up") then
      self.index = total
    elseif input:wasPressed("down") then
      self.index = 1
    end
    self:clampScroll(total, cancel, PER_PAGE)
    return
  end

  if input:wasPressed("left") then
    self.index = ((i - 1) % COLS == 0) and BACK or i - 1
  elseif input:wasPressed("right") then
    self.index = i < total and i + 1 or 1
  elseif input:wasPressed("up") then
    self.index = (i - COLS >= 1) and i - COLS or BACK
  elseif input:wasPressed("down") then
    if i + COLS <= total then
      self.index = i + COLS
    else
      self.index = cancel
    end
  end
  self:clampScroll(total, cancel, PER_PAGE)
end

function PaletteScreen:clampScroll(total, cancel, visible)
  if self.index == BACK then return end
  if self.index >= cancel then
    self.scroll = math.max(0, total - visible)
    if self:isGrid() then
      self.scroll = math.floor(self.scroll / COLS) * COLS
    end
    return
  end
  local step = self:isGrid() and COLS or 1
  if self.index <= self.scroll then
    self.scroll = math.floor((self.index - 1) / step) * step
  elseif self.index > self.scroll + visible then
    self.scroll = math.floor((self.index - 1) / step) * step - visible + step
  end
  if self.scroll < 0 then self.scroll = 0 end
end

function PaletteScreen:activate(cancel)
  if self.index == BACK or self.index >= cancel then
    self:back()
    return
  end

  if self.view == "root" then
    local row = (self.rows or {})[self.index]
    if not row then return end
    if row.folder then
      self:push(row.view, row.group)
    elseif row.mode then
      if self.set then self.set("") end
      if self.setMode then self.setMode(row.mode) end
      self:changed()
    end

  elseif self:isGrid() then
    local id = self:idAt(self.index)
    if id then
      if self.set then self.set(id) end
      self:changed()
    end
  end
end

function PaletteScreen:changed()
  if self.game.data and Sound and Sound.play then
    pcall(Sound.play, self.game.data, "Press_AB")
  end
  if self.onChange then self.onChange() end
end

function PaletteScreen:push(view, group)
  self.stackTrail[#self.stackTrail + 1] =
    { view = self.view, index = self.index, scroll = self.scroll,
      group = self.group }
  self.view, self.index, self.scroll = view, 1, 0
  self.group = group
  self:cursorToSelection()
end

function PaletteScreen:cursorToSelection()
  local id = self.get and self.get() or ""
  if type(id) ~= "string" or id == "" then return end
  local items = self:items()
  for i = 1, #items do
    if self:idAt(i) == id then
      self.index = i
      self:clampScroll(#items, #items + 1,
                       self:isGrid() and PER_PAGE or 12)
      return
    end
  end
end

function PaletteScreen:back()
  local prev = table.remove(self.stackTrail)
  if prev then
    self.view, self.index = prev.view, prev.index
    self.scroll, self.group = prev.scroll, prev.group
    return
  end
  self:close()
end

function PaletteScreen:close()
  if self.game.data and Sound and Sound.play then
    pcall(Sound.play, self.game.data, "Press_AB")
  end
  self.game.stack:pop()
end


function PaletteScreen:sgbPalettes()
  return nil
end


function PaletteScreen:draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

  drawBack(self.index == BACK)

  love.graphics.setColor(0, 0, 0, 1)
  Font.draw(self:title(), 12, 0)

  if self:isGrid() then
    self:drawGrid()
  else
    self:drawList()
  end

  love.graphics.setColor(0, 0, 0, 1)
  local items = self:items()
  if self.index >= #items + 1 then
    Font.draw(Strings("CANCEL"), 16, SCREEN_H - 8)
    Font.drawCode(Theme.cursor, 8, SCREEN_H - 8)
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function PaletteScreen:drawList()
  local items = self:items()
  local mode = self.getMode and self.getMode() or nil
  local visible = 12
  for slot = 1, visible do
    local i = self.scroll + slot
    local row = items[i]
    if not row then break end
    local y = 16 + (slot - 1) * 8

    love.graphics.setColor(0, 0, 0, 1)
    Font.draw(Strings(row.label or ""), 16, y)
    if i == self.index then
      Font.drawCode(Theme.cursor, 8, y)
    end
    if row.folder then
      Font.drawCode(Theme.cursor, 8 + 8 * 17, y)
    elseif row.mode and mode and row.mode == mode then
      love.graphics.rectangle("fill", 8 + 8 * 17 + 2, y + 2, 4, 4)
    end
  end
end

function PaletteScreen:drawGrid()
  local Palette = self.Palette
  local items = self:items()
  local total = #items

  for slot = 1, PER_PAGE do
    local i = self.scroll + slot
    if i > total then break end
    local col = (slot - 1) % COLS
    local row = math.floor((slot - 1) / COLS)
    local x = GRID_X + col * (TILE_W + GAP)
    local y = GRID_Y + row * (TILE_H + GAP)

    local swatch
    if self.view == "mono" then
      local c = Palette and Palette.MONO_COLOURS[i]
      if c then
        local ramp = Palette.monoRamp(c[2], c[3], c[4])
        swatch = { ramp[4], ramp[3], ramp[2], ramp[1] }
      end
    else
      swatch = Palette and Palette.swatch(self:idAt(i)) or nil
    end
    drawSwatch(x, y, TILE_W, TILE_H, swatch)

    if i == self.index then
      frame(x - 2, y - 2, TILE_W + 4, TILE_H + 4, 0)
      frame(x - 1, y - 1, TILE_W + 2, TILE_H + 2, 1)
    end
  end

  self:drawFooter(total)
end

function PaletteScreen:drawFooter(total)
  local Palette = self.Palette
  love.graphics.setColor(0, 0, 0, 1)

  local name, pack = "", nil
  if self.index >= 1 and self.index <= total then
    if self.view == "mono" then
      local c = Palette and Palette.MONO_COLOURS[self.index]
      name = c and c[1] or ""
    else
      local entry = self.group and (self.group.palettes or {})[self.index]
      if entry then
        name = sanitize(entry.name)
        pack = entry.pack
      end
    end
  end

  local lines = wrap(name, 20, 2)
  for i = 1, #lines do
    Font.draw(lines[i], 0, 110 + (i - 1) * 8)
  end

  local at = 0
  if total > PER_PAGE then
    local page = math.floor(self.scroll / PER_PAGE) + 1
    local pages = math.ceil(total / PER_PAGE)
    Font.draw(("%d/%d"):format(page, pages), 0, 128)
    at = 40
  end
  if pack then
    Font.draw(packLabel(pack, (SCREEN_W - at) / 8), at, 128)
  end

  local stored = self.get and self.get() or ""
  if type(stored) == "string" and stored ~= "" then
    for slot = 1, PER_PAGE do
      local i = self.scroll + slot
      if i > total then break end
      if self:idAt(i) == stored then
        local col = (slot - 1) % COLS
        local row = math.floor((slot - 1) / COLS)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle(
          "fill",
          GRID_X + col * (TILE_W + GAP) + TILE_W - 5,
          GRID_Y + row * (TILE_H + GAP) + TILE_H - 5, 4, 4)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle(
          "fill",
          GRID_X + col * (TILE_W + GAP) + TILE_W - 4,
          GRID_Y + row * (TILE_H + GAP) + TILE_H - 4, 2, 2)
        break
      end
    end
  end
end

return PaletteScreen
