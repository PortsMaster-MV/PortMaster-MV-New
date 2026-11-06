local M = {}

function M.matches(man)
  return type(man) == "table" and man.layout == "rs"
end

function M.layout(man)
  local g, k = man.geometry, man.keyboard
  return {
    titleX = g.titleX, titleY = g.titleY, titleMaxW = 168,
    iconCX = 56, iconCY = 24, iconW = 16, iconH = 32,
    monIconCX = 52, monIconCY = 24, monIconW = 32, monIconH = 32,
    charY = g.inputY, underscoreBaseY = g.underscoreY - 4, underscoreXOfs = 0,
    arrowXOfs = -8, arrowY = g.inputArrowY - 4,
    cursorBaseX = k.cursorOriginX - k.textX - 8, cursorBaseY = k.cursorOriginY - 8,
    kbX = 0, kbY = k.textY, keyTextOx = 0, keyTextOy = 0,
    kbChromeX = man.kb_x, kbChromeY = man.kb_y,
    pageFrameX = g.pageFrameX, pageFrameY = g.pageFrameY,
    pageBtnX = g.pageButtonX, pageBtnY = g.pageButtonY,
    pageLabelX = g.pageTextX, pageLabelY = g.pageTextY,
    backX = g.backX, backY = g.backY, okX = g.okX, okY = g.okY,
    btnCursorX = 188, btnCursorY = {69, 98, 120}, bannerH = 0,
  }
end

function M.move(st, key)
  local n = #st.pages[st.page].rows[1]
  local side = st.col > n
  if key == "up" or key == "down" then
    local d = key == "up" and -1 or 1
    if side then
      st.btn = (st.btn - 1 + d) % 3 + 1
      st.row = ({1, 2, 4})[st.btn]
      if st.btn == 1 then st.savedKeyRow = 2 end
      if st.btn == 3 then st.savedKeyRow = 3 end
    else
      st.row = (st.row - 1 + d) % 4 + 1
    end
  elseif side then
    st.row = st.btn == 2 and (st.savedKeyRow or 1) or (st.btn == 3 and 4 or 1)
    st.col = key == "left" and n or 1
  else
    local x = st.col + (key == "left" and -1 or 1)
    if x < 1 or x > n then
      st.col = n + 1
      st.savedKeyRow = st.row
      st.btn = ({1, 2, 2, 3})[st.row]
      st.row = ({1, 2, 4})[st.btn]
      if st.btn == 1 then st.savedKeyRow = 2 end
      if st.btn == 3 then st.savedKeyRow = 3 end
    else
      st.col = x
    end
  end
  st.cursorAmount, st.cursorStep, st.cursorDelay = 0, 1, 2
end

function M.direction(st, input)
  local held, keys = {}, {"a", "b", "select", "start", "right", "left", "up", "down", "r", "l"}
  for _, key in ipairs(keys) do
    if input and input.isDown and input:isDown(key) then held[#held + 1] = key end
  end
  local mask = table.concat(held, ":")
  local repeatNow = false
  if mask ~= "" and mask == st.repeatMask then
    st.repeatCounter = st.repeatCounter - 1
    if st.repeatCounter == 0 then repeatNow, st.repeatCounter = true, 5 end
  else
    st.repeatCounter = 16
  end
  st.repeatMask = mask
  local direction
  for _, key in ipairs({"up", "down", "left", "right"}) do
    if input and ((input.wasPressed and input:wasPressed(key))
      or (repeatNow and input.isDown and input:isDown(key))) then direction = key end
  end
  return direction
end

local function rgb(c)
  c = tonumber(c) or 0
  local function ch(v) return (v * 8 + math.floor(v / 4)) / 255 end
  return {ch(c % 32), ch(math.floor(c / 32) % 32), ch(math.floor(c / 1024) % 32), 1}
end

function M.colors(man, bank)
  local p = man.palettes.menu
  return {fg = rgb(p[bank * 16 + 2]), shadow = rgb(p[bank * 16 + 9]), bg = {0, 0, 0, 0}}
end

function M.tint(c, r, g, b)
  c = tonumber(c) or 0
  local function ch(v, amount)
    v = v + math.floor((31 - v) * amount / 16)
    return (v * 8 + math.floor(v / 4)) / 255
  end
  return ch(c % 32, r), ch(math.floor(c / 32) % 32, g), ch(math.floor(c / 1024) % 32, b), 1
end

function M.tick(st)
  st.nativeFrame = (st.nativeFrame or 0) + 1
  local caret = 0
  for _ in tostring(st.name):gmatch("[%z\1-\127\194-\244][\128-\191]*") do caret = caret + 1 end
  caret = math.min(caret, st.maxLen - 1)
  if caret ~= st.previousCaret then st.caretFrame = 0 end
  st.previousCaret, st.caretFrame = caret, (st.caretFrame or 0) + 1
  local n = #st.pages[st.page].rows[1]
  local role = st.col > n and st.btn or nil
  if st.swapT ~= nil then role = 1 end
  if role ~= st.glowRole then
    st.glowRole, st.glowAmount, st.glowStep, st.glowDelay = role, 15, 1, 0
  end
  if role then
    if st.glowDelay > 0 then st.glowDelay = st.glowDelay - 1 end
    if st.glowDelay == 0 then
      st.glowDelay = 2
      st.glowAmount = st.glowAmount + st.glowStep
      if st.glowAmount == 16 or st.glowAmount == 0 then st.glowStep = -st.glowStep end
    end
  end
  st.cursorDelay = (st.cursorDelay or 2) - 1
  if st.cursorDelay == 0 then
    st.cursorDelay = 2
    st.cursorAmount = (st.cursorAmount or 0) + (st.cursorStep or 1)
    if st.cursorAmount == 16 or st.cursorAmount == 0 then st.cursorStep = -(st.cursorStep or 1) end
  end
  if st.cursorActivation then
    st.cursorActivation = st.cursorActivation + 1
    if st.cursorActivation > 16 then
      st.cursorActivation = nil
      if st.fullNameWait then
        st.fullNameWait = nil
        st.col, st.row, st.btn = n + 1, 4, 3
      end
    end
  end
end

function M.nameX(maxLen)
  return (14 - math.floor(maxLen / 2)) * 8
end

function M.playerFrame(st)
  local frame = math.floor((st.nativeFrame or 0) / 8) % 4
  return ({3, 0, 4, 0})[frame + 1], false
end

return M
