local Kit = require("src.ui.game3.rse.scene_kit")
local Gfx = require("src.ui.game3.rs.pokenav.gfx")
local Data = require("src.ui.game3.rs.pokenav.data")
local Pal = require("src.core.game3.pal_fade")
local Stack = require("src.ui.game3.stack")
local M = {ID = "rs_pokenav"}
M.MENU = {MAIN_MENU = "main", CONDITION_MENU = "condition", CONDITION_SEARCH_MENU = "search", REGION_MAP = "map", TRAINERS_EYES = "eyes"}
M.COVERAGE = {main = true, conditionMenu = true, searchMenu = true, map = true, trainersEyes = true,
  conditionGraph = true, conditionSearchResults = true, ribbons = true, giftRibbonDescriptions = false, ssTidalLocation = true}
local Host = {isMenu = true}
local State = {}; State.__index = State
local function stepRepeat(step, pressed)
  local held = step.held or {}
  local signature = {}
  for _, k in ipairs(Kit.KEYS) do if held[k] then signature[#signature + 1] = k end end
  signature = table.concat(signature, ",")
  local result = {}; for k, v in pairs(pressed) do result[k] = v end
  if signature ~= "" and signature == step.heldSig then
    step.repeatCounter = (step.repeatCounter or 20) - 1
    if step.repeatCounter <= 0 then for k in pairs(held) do result[k] = true end; step.repeatCounter = 5 end
  else step.repeatCounter = 20 end
  step.heldSig = signature
  return result
end
function State:setMenu(menu, cursor)
  self.menu, self.cursor, self.helpOverride = menu, cursor or 0, nil
  self.feature = nil
  self.rows = menu == "main" and Data.mainRows(self.session) or {}
  local count = self.nav.menus[menu].count
  if menu ~= "main" then for i = 1, count do self.rows[i] = true end end
  self.offsets = {}; for i = 1, count do self.offsets[i] = 0 end
  self.slide, self.busy = 104, 17
  self.headerTarget = 0
  self.dotTarget = menu == "main" and 0 or 30
end
function State:missing(name)
  self.missingFeature = name
  require("src.core.game3.rse.init").missing("ruby_sapphire_pokenav", name)
  if self.onMissingFeature then self.onMissingFeature(name, self) end
end
function State:openMap()
  local map, err = require("src.ui.game3.rs.pokenav.map").new(self.session, self.game, self.region)
  if not map then self:missing(err); return end
  self.menu, self.feature, self.headerTarget, self.busy = "map", map, 32, 16
end
function State:openEyes()
  local eyes = require("src.ui.game3.rs.pokenav.eyes").new(self.session, self.game, self.detail, self.region)
  if #eyes.entries == 0 then self.helpOverride = 7; Kit.playSe("SE_FAILURE"); return end
  self.menu, self.feature, self.headerTarget, self.busy = "eyes", eyes, 32, 16
end
function State:openCondition(rows, index)
  self.feature = require("src.ui.game3.rs.pokenav.condition").new(self.session, rows, index, self.conditionSearchId)
  self.menu, self.headerTarget, self.busy = rows and "graph_search" or "graph_party", 32, 16
end
function State:openSearch(rows, index, ribbons)
  self.feature = require("src.ui.game3.rs.pokenav.condition_search").new(self.session, self.conditionSearchId or 0, rows, index, ribbons)
  self.menu, self.headerTarget, self.busy = ribbons and "ribbons_list" or "condition_results", 32, 16
end
function State:menuInput(inp)
  local n, r = inp.new or {}, inp.rep or {}
  local delta = r.up and -1 or r.down and 1 or 0
  if delta ~= 0 then
    self.cursor = Data.moveCursor(self.rows, self.cursor, delta)
    self.helpOverride, self.busy = nil, 4; Kit.playSe("SE_SELECT"); return
  end
  if self.helpOverride then
    if n.a or n.b then self.helpOverride = nil; Kit.playSe("SE_SELECT") end
    return
  end
  if n.b then
    if self.menu == "main" then self:shutdown()
    elseif self.menu == "condition" then self:setMenu("main", 1); Kit.playSe("SE_SELECT")
    else self:setMenu("condition", 1); Kit.playSe("SE_SELECT") end
    return
  end
  if not n.a then return end
  if self.menu == "main" then
    if self.cursor == 0 then Kit.playSe("SE_SELECT"); self:openMap()
    elseif self.cursor == 1 then Kit.playSe("SE_SELECT"); self:setMenu("condition")
    elseif self.cursor == 2 then self:openEyes(); if self.menu == "eyes" then Kit.playSe("SE_SELECT") end
    elseif self.cursor == 3 then
      if require("src.core.game3.rse.ribbons").anyMonHasRibbon(self.session) then Kit.playSe("SE_SELECT"); self:openSearch(nil, nil, true)
      else self.helpOverride = 6; Kit.playSe("SE_FAILURE") end
    elseif self.cursor == 4 then self:shutdown() end
  elseif self.menu == "condition" then
    if self.cursor == 0 then Kit.playSe("SE_SELECT"); self:openCondition()
    elseif self.cursor == 1 then Kit.playSe("SE_SELECT"); self:setMenu("search")
    else Kit.playSe("SE_SELECT"); self:setMenu("main", 1) end
  elseif self.menu == "search" then
    if self.cursor == 5 then Kit.playSe("SE_SELECT"); self:setMenu("condition", 1)
    else self.conditionSearchId = self.cursor; Kit.playSe("SE_SELECT"); self:openSearch() end
  end
end
function State:shutdown()
  if self.feature and self.feature.close then self.feature:close() end
  Kit.playSe("SE_POKENAV_OFF")
  self.phase = "out"; self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
end
function State:close()
  if Host._s == self then Host._s = nil end
  Stack.pop(M.ID)
  local Fade = require("src.ui.game3.fade"); Fade.clear(); Fade.begin(Fade.MODE.FROM_BLACK, 1)
  if self.onClose then self.onClose() end
end
function State:frame(inp)
  self.frames = self.frames + 1
  self.pal:updateFade()
  if self.phase == "field" then
    if not self.pal:fadeActive() then self.phase = "in"; self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK); Kit.playSe("SE_POKENAV_ON") end
    return
  elseif self.phase == "out" then if not self.pal:fadeActive() then self:close() end; return
  elseif self.phase == "in" and not self.pal:fadeActive() then self.phase = "active" end
  if self.headerScroll < self.headerTarget then self.headerScroll = self.headerScroll + 2
  elseif self.headerScroll > self.headerTarget then self.headerScroll = self.headerScroll - 2 end
  if self.dotOffset < self.dotTarget then self.dotOffset = self.dotOffset + 2
  elseif self.dotOffset > self.dotTarget then self.dotOffset = self.dotOffset - 2 end
  if self.slide > 0 then self.slide = math.max(0, self.slide - 8) end
  for i, off in ipairs(self.offsets) do
    local target = i - 1 == self.cursor and -16 or 0
    self.offsets[i] = off < target and math.min(target, off + 4) or math.max(target, off - 4)
  end
  if self.busy > 0 then self.busy = self.busy - 1; return end
  if self.phase ~= "active" then return end
  if self.feature then
    local result = self.feature:frame(inp)
    if result == "graph" then
      local feature = self.feature
      self:openCondition(feature.rows, feature.index); Kit.playSe("SE_SELECT")
    elseif result == "exit" then
      local menu, feature = self.menu, self.feature
      if feature.close then feature:close() end
      Kit.playSe("SE_SELECT")
      if menu == "graph_party" then self:setMenu("condition", 0)
      elseif menu == "graph_search" then self:openSearch(feature.rows, feature.index)
      elseif menu == "condition_results" then self:setMenu("search", self.conditionSearchId)
      elseif menu == "ribbons_detail" then self:openSearch(feature.rows, feature.index, true)
      elseif menu == "ribbons_list" then self:setMenu("main", 3)
      else self:setMenu("main", menu == "map" and 0 or 2) end
    elseif result == "ribbon" then
      local feature = self.feature
      self.feature = require("src.ui.game3.rs.pokenav.ribbons").new(self.session, feature.rows, feature.index)
      self.menu, self.busy = "ribbons_detail", 12; Kit.playSe("SE_SELECT")
    end
  else self:menuInput(inp) end
end
function State:drawMenu()
  local nav, shell, menu = self.nav, self.shell, self.nav.menus[self.menu]
  Gfx.fill(Gfx.color(shell.palettes.dots, 0), 0, 0, 240, 160)
  local scroll = math.floor((self.frames + 1) / 2) % 256
  for _, x in ipairs({-scroll, 256 - scroll}) do
    Gfx.draw(shell.layers.dotsBase, x, 0)
    Gfx.draw(shell.layers.dots1, x, 0, nil, nil, nil, nil, Kit.color555(shell.dotsGradient[self.dotOffset + 1]))
    Gfx.draw(shell.layers.dots2, x, 0, nil, nil, nil, nil, Kit.color555(shell.dotsGradient[self.dotOffset + 2]))
  end
  Gfx.draw(nav.layers.outline, 0, 0)
  local options = nav.sprites["options_" .. self.menu]
  local phase = self.frames * 3 % 128
  local amount = math.floor(math.max(0, math.floor(256 * math.sin(phase * math.pi / 128))) / 32)
  for i = 0, menu.count - 1 do
    if self.rows[i + 1] then
      if i == self.cursor then Gfx.highlight(amount) end
      Gfx.draw(options, menu.optionX + self.slide + self.offsets[i + 1], menu.top + i * menu.spacing - 8, 128, 16, 0, i * 16)
      love.graphics.setShader()
    end
  end
  if self.nearbyRematch and math.floor(self.frames / 7) % 2 == 0 then
    local light = nav.sprites.blueLight; Gfx.draw(light, 12 - light.w / 2, 96 - light.h / 2)
  end
  Gfx.draw(nav.layers.message, 0, 0)
  local text = menu.help[self.helpOverride or self.cursor + 1]
  if text then
    local win = shell.windows.message
    local colors = Gfx.colors(nav.palettes.message, win.backgroundColor, win.foregroundColor, win.shadowColor)
    Gfx.text(text, 24 + math.floor((192 - Gfx.measure(text)) / 2), 136, colors, "native_" .. win.fontNum, 192)
  end
  Gfx.header(nav, self.menu == "main" and "main_menu" or "condition", self.headerScroll)
end
function State:draw()
  love.graphics.push("all")
  if self.phase == "field" then Kit.drawFade(self.pal); love.graphics.pop(); return end
  Gfx.fill({0, 0, 0, 1}, 0, 0, 240, 160)
  local help
  if self.feature then
    self.feature:draw(self.nav, self.shell)
    local header = self.menu == "map" and "hoenn_map" or self.menu == "eyes" and "trainers_eyes"
      or (self.menu == "ribbons_list" or self.menu == "ribbons_detail") and "ribbons" or "condition"
    Gfx.header(self.nav, header, self.headerScroll, self.feature.zoomed)
    help = self.feature.help and self.feature:help()
      or self.menu == "map" and (self.feature.zoomed and 7 or 8) or self.feature.detail and 10 or 9
  else self:drawMenu() end
  Gfx.shell(self.shell, self.frames, self.headerScroll, help)
  Kit.drawFade(self.pal)
  love.graphics.pop()
end
function M.show(opts)
  opts = opts or {}
  local s = setmetatable({session = assert(opts.session), game = opts.game, onClose = opts.onClose, onMissingFeature = opts.onMissingFeature,
    nav = Gfx.manifest("pokenav"), shell = Gfx.manifest("pokenav_shell"), detail = Gfx.manifest("pokenav_detail"), region = Gfx.manifest("region_map"),
    frames = 0, headerScroll = 0, dotOffset = 0, pal = Pal.new(), phase = "field"}, State)
  s:setMenu("main")
  s.nearbyRematch = Data.nearbyRematch(s.session, s.detail)
  s.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
  Host._s, Host._step = s, Kit.stepper(); Host._step._repeat = stepRepeat
  Stack.push(M.ID, Host, {hideBelow = false, fullscreen = function() return Host._s and Host._s.phase ~= "field" end})
  return s
end
function M.active() return Host._s end
function M.isOpen() return Host._s ~= nil end
function M.reset()
  if Host._s then
    if Host._s.feature and Host._s.feature.close then Host._s.feature:close() end
    Host._s = nil; Stack.pop(M.ID)
  end
  Host._step = nil
end
function Host.handleInput(input) if Host._step then Host._step:collect(input) end end
function Host.update(dt)
  local s = Host._s
  if s and Host._step then Host._step:run(dt, function(inp) s:frame(inp); if Host._s ~= s then return true end end) end
end
function Host.draw() if Host._s then Host._s:draw() end end
M.Host = Host
return M
