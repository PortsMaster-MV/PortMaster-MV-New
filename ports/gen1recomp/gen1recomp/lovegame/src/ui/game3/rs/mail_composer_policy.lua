local Easy = require("src.core.game3.easy_chat_text")
local P = {EMPTY = 65535}

function P.wordEnabled(id, session, gates)
  local gid, value = math.floor(id / 512), id % 512
  gates = gates or {}
  local function flag(name)
    if gates.flag then return gates.flag(name) end
    return require("src.core.game3.rse.init").flag(name, session)
  end
  if gid == 0 then
    if gates.seen then return gates.seen(value) end
    return session.dex and require("src.core.game3.dex").isSeen(session.dex, value) == true or false
  elseif gid == 17 or gid == 18 or gid == 19 then return flag("FLAG_SYS_GAME_CLEAR")
  elseif gid == 20 then
    return flag("FLAG_SYS_HIPSTER_MEET") and require("src.core.game3.rse.old_man").isTrendySayingUnlocked(value, session)
  elseif gid == 21 then
    if gates.national then return gates.national() end
    return require("src.core.game3.pokedex_data").isNationalUnlocked(session, session.dex) == true
  end
  return gid >= 1 and gid <= 16
end

function P.groupWords(gid, session, gates)
  local source, result = assert(Easy.group(gid)), {}
  for _, word in ipairs(source.words) do if P.wordEnabled(word.id, session, gates) then result[#result + 1] = word end end
  table.sort(result, function(a, b) return assert(a.alphabeticalOrder) < assert(b.alphabeticalOrder) end)
  return result
end

function P.groups(session, gates)
  local groups = {}
  for gid = 0, 21 do
    local list = P.groupWords(gid, session, gates)
    if #list > 0 then groups[#groups + 1] = {id = gid, name = Easy.group(gid).name, words = list} end
  end
  return groups
end

function P.alphabetWords(letter, man, session, gates)
  local result, index = {}, man.letterOffsets[letter + 1] + 1
  local finish = man.letterOffsets[letter + 2]
  while index <= finish do
    local id = man.alphabeticalWords[index]; index = index + 1
    if id > 0xFEFF then
      local chosen
      for _ = 1, id % 256 do
        local alt = man.alphabeticalWords[index]; index = index + 1
        if not chosen and P.wordEnabled(alt, session, gates) then chosen = alt end
      end
      if chosen then result[#result + 1] = {id = chosen, text = Easy.rawWord(chosen)} end
    elseif P.wordEnabled(id, session, gates) then result[#result + 1] = {id = id, text = Easy.rawWord(id)} end
  end
  return result
end

function P.changed(before, after)
  local count = 0
  for i = 1, 9 do if Easy.rawWord(before[i]) ~= Easy.rawWord(after[i]) then count = count + 1 end end
  return count
end
function P.empty(words)
  for i = 1, 9 do if words[i] ~= P.EMPTY then return false end end
  return true
end

function P.mainMove(row, col, key)
  if key == "start" then return 5, 2 end
  if key == "up" or key == "down" then
    row = (row + (key == "up" and -1 or 1)) % 6
    col = math.min(col, 1)
  elseif key == "left" or key == "right" then
    col = (col + (key == "left" and -1 or 1)) % (row == 5 and 3 or 2)
  end
  if row < 5 and row * 2 + col >= 9 then col = row * 2 + col - 9 end
  return row, col
end

function P.groupMove(s, key, groupCount)
  local old = {row = s.row, col = s.col, top = s.top, sidebar = s.sidebar}
  local function columns(row)
    if s.alpha then return row == 1 and 6 or 7 end
    return math.min(2, groupCount - row * 2)
  end
  if key == "up" or key == "down" then
    local delta = key == "up" and -1 or 1
    if s.sidebar then s.row = (s.row - 1 + delta) % 3 + 1
    elseif s.alpha then s.row = (s.row + delta) % 4; s.col = math.min(s.col, columns(s.row) - 1)
    else
      s.row = math.max(0, math.min(math.ceil(groupCount / 2) - 1, s.row + delta))
      s.top = math.max(math.min(s.top, s.row), s.row - 3)
      s.col = math.min(s.col, columns(s.row) - 1)
    end
  elseif key == "left" or key == "right" then
    local side = s.sidebar
    local row = side and s.row + s.top or s.row
    local count = columns(row)
    if side then
      s.row, s.sidebar = math.min(row, s.alpha and 3 or math.ceil(groupCount / 2) - 1), false
      s.col = key == "right" and 0 or columns(s.row) - 1
    else
      s.col = (s.col + (key == "left" and -1 or 1)) % (count + 1)
      if s.col == count then
        s.sidebar, s.row = true, math.max(1, s.row - s.top)
        s.col = columns(s.row)
      end
    end
  end
  return old.row ~= s.row or old.col ~= s.col or old.top ~= s.top or old.sidebar ~= s.sidebar, s.top - old.top
end

function P.wordMove(s, key, count)
  local rows, oldTop, oldRow, oldCol = math.ceil(count / 2), s.top, s.row, s.col
  local cols = function(row) return math.min(2, count - row * 2) end
  if key == "up" or key == "down" then s.row = math.max(0, math.min(rows - 1, s.row + (key == "up" and -1 or 1)))
  elseif key == "left" or key == "right" then s.col = (s.col + (key == "left" and -1 or 1)) % cols(s.row)
  elseif key == "start" or key == "select" then
    local delta = key == "start" and -math.min(s.top, 4) or math.min(math.max(0, rows - 4 - s.top), 4)
    s.row, s.top = s.row + delta, s.top + delta
  end
  s.top = math.max(math.min(s.top, s.row), s.row - 3)
  s.col = math.min(s.col, cols(s.row) - 1)
  return oldTop ~= s.top or oldRow ~= s.row or oldCol ~= s.col, s.top - oldTop
end
return P
