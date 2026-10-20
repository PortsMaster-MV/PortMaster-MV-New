local Stack = require("src.ui.game3.stack")
local FrlgFont = require("src.ui.game3.frlg_font")
local RomText = require("src.core.game3.rom_text")
local Mail = require("src.core.game3.mail")

local MailRead = {}

MailRead.open = false
MailRead.CACHE_SUB = "mail"

-- pokeemerald/src/mail.c:88
local WIN_LEFT, WIN_TOP = 2, 3

local images = {}
local manifest

local function cache_root()
  local ok, Extract = pcall(require, "src.import.gba.extract_island1")
  return ((ok and Extract and Extract.CACHE_ROOT) or "data/generated/gba") .. "/" .. MailRead.CACHE_SUB
end

local function load_manifest()
  if manifest then return manifest end
  local rel = cache_root() .. "/manifest.lua"
  local src = assert(require("src.core.game3.dataset").cache():read(rel), rel .. " is not in the cache")
  manifest = assert(load(src, "@" .. rel, "t", {}))()
  return manifest
end
MailRead.manifest = load_manifest

local function image(file)
  if images[file] then return images[file] end
  local m = load_manifest()
  local rel = cache_root() .. "/" .. file
  local bytes = assert(require("src.core.game3.dataset").cache():read(rel), rel .. " is not in the cache")
  local img = love.graphics.newImage(love.image.newImageData(m.width, m.height, "rgba8", bytes))
  img:setFilter("nearest", "nearest")
  images[file] = img
  return img
end

local function rgb(c)
  return { (c % 32) / 31, (math.floor(c / 32) % 32) / 31, (math.floor(c / 1024) % 32) / 31, 1 }
end

-- pokeemerald/src/mail.c:639
function MailRead.lines(mail, design)
  local EasyChatText = require("src.core.game3.easy_chat_text")
  local layout = load_manifest().layouts[design or 0]
  local out, n = {}, 1
  for i, line in ipairs(layout.lines) do
    local words = {}
    for _ = 1, line.words do
      local w = EasyChatText.word(mail.words and mail.words[n])
      if w ~= "" then words[#words + 1] = w end
      n = n + 1
    end
    out[i] = table.concat(words, " ")
  end
  return out
end

function MailRead.designOf(mail)
  local item = tonumber(mail and mail.itemId) or 0
  local m = load_manifest()
  local d = item - m.firstMailItem
  if not m.designs[d] then return 0, false end
  return d, true
end

-- pokeemerald/src/mail.c:423
function MailRead.read(mail, opts)
  opts = opts or {}
  MailRead.open = true
  MailRead._mail = mail
  MailRead._onClose = opts.onClose
  MailRead._session = opts.session
  local design, hasText = MailRead.designOf(mail)
  MailRead._design = design
  MailRead._hasText = hasText and opts.hasText ~= false
  MailRead._fade = 16
  MailRead._fadeDir = -1
  MailRead._lines = MailRead._hasText and MailRead.lines(mail, design) or {}
  Stack.push("rse_mail", MailRead, { hideBelow = true, fullscreen = true })
end

function MailRead.isOpen()
  return MailRead.open
end

function MailRead.close()
  if not MailRead.open then return end
  MailRead.open = false
  Stack.pop("rse_mail")
  local cb = MailRead._onClose
  MailRead._onClose = nil
  if cb then cb() end
end

function MailRead.reset()
  MailRead.open = false
  MailRead._onClose = nil
  Stack.pop("rse_mail")
end

function MailRead.update()
  if not MailRead.open then return end
  -- pokeemerald/src/mail.c:717
  if MailRead._fadeDir ~= 0 then
    MailRead._fade = MailRead._fade + MailRead._fadeDir
    if MailRead._fade <= 0 then
      MailRead._fade, MailRead._fadeDir = 0, 0
    elseif MailRead._fade >= 16 then
      MailRead.close()
    end
  end
end

function MailRead.handleInput(input)
  if not MailRead.open or not input or MailRead._fadeDir ~= 0 then return end
  -- pokeemerald/src/mail.c:725
  if input:wasPressed("a") or input:wasPressed("b") then
    MailRead._fadeDir = 1
  end
end

local function gender(sess)
  local g = sess and (sess.gender or sess.playerGender)
  return (g == 1 or g == "female" or g == "F") and 1 or 0
end

function MailRead.draw()
  if not MailRead.open then return end
  local m = load_manifest()
  local d = m.designs[MailRead._design]
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.draw(image(d.files[gender(MailRead._session) + 1]), 0, 0)
  local layout = m.layouts[MailRead._design]
  local colors = { fg = rgb(d.textColor), shadow = rgb(d.textShadow), bg = { 0, 0, 0, 0 } }
  if MailRead._hasText then
    local ox, oy, y = WIN_LEFT * 8, WIN_TOP * 8, 0
    for i, line in ipairs(MailRead._lines) do
      -- pokeemerald/src/mail.c:685
      if line ~= "" then
        FrlgFont.draw(line, ox + layout.lines[i].xOffset + layout.wordsXPos, oy + y + layout.wordsYPos, { colors = colors })
        y = y + layout.lines[i].height
      end
    end
    local sig = RomText.plain("gText_FromSpace") .. tostring(MailRead._mail and MailRead._mail.playerName or "")
    -- pokeemerald/src/mail.c:693
    local bx = math.floor((layout.signatureWidth - FrlgFont.measure(sig)) / 2)
    if bx < 0 then bx = 0 end
    FrlgFont.draw(sig, ox + bx + 104, oy + layout.signatureYPos + 88, { colors = colors })
  end
  if MailRead._fade > 0 then
    love.graphics.setColor(0, 0, 0, MailRead._fade / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 160)
    love.graphics.setColor(1, 1, 1, 1)
  end
end

function MailRead.invalidate()
  images, manifest = {}, nil
end

MailRead.Mail = Mail

return MailRead
