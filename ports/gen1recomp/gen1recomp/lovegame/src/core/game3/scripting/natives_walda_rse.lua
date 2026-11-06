local Rse = require("src.core.game3.rse.init")
local bit = require("bit")

local Walda = {}
local function friends()
  return require("src.import.gba.versions_game").game().STORAGE_FRIENDS
end

local LETTERS = "BCDFGHJKLMNPQRSTVWZbcdfghjkmnpqs"
local TID_XOR = 6
local PATTERN_XOR = 7

local function state(session)
  session = session or Rse.session()
  if not session then return nil end
  if type(session.waldaPhrase) ~= "table" then
    session.waldaPhrase = {
      phrase = "", colors = { 0x7B35, 0x6186 }, iconId = 0, patternId = 0, unlocked = false,
    }
  end
  local w = session.waldaPhrase
  w.phrase = tostring(w.phrase or "")
  w.colors = type(w.colors) == "table" and w.colors or { 0x7B35, 0x6186 }
  return w
end

local function setString(ctx, adapters, slot, text)
  text = tostring(text or "")
  if adapters and adapters.setStringVar then adapters.setStringVar(slot, text) end
  if ctx and ctx.stringVars then ctx.stringVars[slot] = text end
end

local function varSet(ctx, id, value)
  Rse.setSpecialVar(ctx, id, value)
end

local function getBit(bytes, bitNum)
  local i = math.floor(bitNum / 8) + 1
  return math.floor((bytes[i] or 0) / (2 ^ (7 - bitNum % 8))) % 2
end

local function putBit(bytes, bitNum, value)
  local i = math.floor(bitNum / 8) + 1
  local mask = 2 ^ (7 - bitNum % 8)
  local old = bytes[i] or 0
  if value ~= 0 then
    if math.floor(old / mask) % 2 == 0 then bytes[i] = old + mask end
  elseif math.floor(old / mask) % 2 == 1 then
    bytes[i] = old - mask
  end
end

local function getBits(bytes, offset, count)
  local n = 0
  for i = 0, count - 1 do n = n * 2 + getBit(bytes, offset + i) end
  return n
end

local function rotateLeft(bytes, size, shifts)
  for _ = 1, shifts do
    local carry = math.floor((bytes[1] or 0) / 128)
    for i = size, 1, -1 do
      local nextCarry = math.floor((bytes[i] or 0) / 128)
      bytes[i] = ((bytes[i] or 0) * 2 + carry) % 256
      carry = nextCarry
    end
  end
end

-- pokeemerald/src/walda_phrase.c:143
function Walda.calculate(phrase, trainerId)
  phrase = tostring(phrase or "")
  if #phrase ~= 15 then return nil end
  local letterIds = {}
  for i = 1, 15 do
    local at = LETTERS:find(phrase:sub(i, i), 1, true)
    if not at then return nil end
    letterIds[i] = at - 1
  end

  local data = { 0, 0, 0, 0, 0, 0, 0, 0, 0 }
  local function setFromLetters(dstOffset, srcOffset, count)
    for bitIndex = 0, count - 1 do
      putBit(data, dstOffset + bitIndex, getBit(letterIds, srcOffset + bitIndex))
    end
  end
  for i = 0, 13 do setFromLetters(i * 5, 3 + 8 * i, 5) end
  setFromLetters(70, 3 + 8 * 14, 2)
  if getBits(data, 0, 3) ~= getBits(letterIds, 3 + 8 * 14 + 2, 3) then return nil end

  local key = data[9]
  rotateLeft(data, 9, 21)
  rotateLeft(data, 8, key % 16)
  local mask = math.floor(key / 16)
  mask = mask * 17
  for i = 1, 8 do data[i] = bit.band(bit.bxor(data[i] or 0, mask), 0xFF) end

  local tid = (tonumber(trainerId) or 0) % 65536
  local outHi = bit.band(bit.bxor(data[1], data[3], data[5], math.floor(tid / 256)), 0xFF)
  local outLo = bit.band(bit.bxor(data[2], data[4], data[6], tid % 256), 0xFF)
  if data[7] ~= outHi or data[8] ~= outLo then
    return nil
  end

  return {
    colors = { data[1] + data[2] * 256, data[3] + data[4] * 256 },
    iconId = data[5], patternId = data[6], unlocked = true,
  }
end

-- pokeemerald/src/walda_phrase.c:41
function Walda.tryBuffer(ctx, adapters)
  local w = state()
  local phrase = w and w.phrase or ""
  if phrase == "" then return false, 0 end
  setString(ctx, adapters, 1, phrase)
  return false, 1
end

-- pokeemerald/src/walda_phrase.c:50
function Walda.namingScreen(ctx, adapters)
  local session, w = Rse.session(), state()
  if not (session and w) then return false end
  local Native = require("src.core.game3.scripting.natives")
  return Native.yieldHost(ctx, adapters, function(done)
    require("src.ui.game3.naming").open({
      template = "WALDA",
      maxLen = 15,
      title = require("src.core.game3.rom_text").plain("gText_TellHimTheWords"),
      initialText = w.phrase,
      seed = "",
      session = session,
      onDone = function(input)
        input = tostring(input or "")
        local status
        if input == "" then
          if w.phrase == "" then
            w.phrase = require("src.core.game3.rse.init").text("gText_Peekaboo")
            status = 2
          else
            status = 1
          end
        elseif input == w.phrase then
          status = 1
        else
          w.phrase = input
          status = 0
        end
        varSet(ctx, Rse.varId("VAR_0x8004", Rse.session()), status)
        setString(ctx, adapters, 1, w.phrase)
        done()
      end,
    })
  end)
end

-- pokeemerald/src/walda_phrase.c:96
function Walda.tryWallpaper(ctx)
  local session, w = Rse.session(), state()
  if not (session and w) then return false, 0 end
  local result = Walda.calculate(w.phrase, session.trainerId or session.id)
  if result then
    w.colors = result.colors
    -- pokeemerald/src/pokemon_storage_system.c:9686,9697
    local FRIENDS = friends()
    if result.patternId < (FRIENDS and FRIENDS.patternCount or 0) then w.patternId = result.patternId end
    if result.iconId < (FRIENDS and FRIENDS.iconCount or 0) then w.iconId = result.iconId end
  end
  w.unlocked = result ~= nil
  return false, w.unlocked and 1 or 0
end

Walda.BY_NAME = {
  TryBufferWaldaPhrase = Walda.tryBuffer,
  DoWaldaNamingScreen = Walda.namingScreen,
  TryGetWallpaperWithWaldaPhrase = Walda.tryWallpaper,
}

return Walda
