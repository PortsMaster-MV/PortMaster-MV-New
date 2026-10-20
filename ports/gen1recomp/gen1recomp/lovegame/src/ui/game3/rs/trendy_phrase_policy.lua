local Picker = require("src.ui.game3.rs.mail_composer_policy")
local Trend = require("src.core.game3.rs.dewford_trend")
local Easy = require("src.core.game3.easy_chat_text")
local P = {EMPTY = Trend.EMPTY, groupMove = Picker.groupMove,
  wordMove = Picker.wordMove, alphabetWords = Picker.alphabetWords}

function P.groups(session, gates)
  gates = gates or {}
  local function flag(name)
    if gates.flag then return gates.flag(name) end
    return require("src.core.game3.rse.init").flag(name, session)
  end
  local groups = {}
  for gid = 0, 21 do
    local enabled = gid <= 16
    if gid >= 17 and gid <= 19 then enabled = flag("FLAG_SYS_GAME_CLEAR")
    elseif gid == 20 then enabled = flag("FLAG_SYS_HIPSTER_MEET")
    elseif gid == 21 then
      enabled = gates.national and gates.national()
        or (not gates.national and require("src.core.game3.pokedex_data").isNationalUnlocked(session, session.dex) == true)
    end
    if enabled then groups[#groups + 1] = {id = gid, name = Easy.group(gid).name,
      words = Picker.groupWords(gid, session, gates)} end
  end
  return groups
end

function P.mainMove(row, col, key)
  if key == "start" then return 1, 2 end
  if key == "up" or key == "down" then return 1 - row, math.min(col, 1) end
  if key == "left" or key == "right" then
    col = (col + (key == "left" and -1 or 1)) % (row == 1 and 3 or 2)
  end
  return row, col
end
function P.valid(before, words) return Trend.editorValid(before, words) end
return P
