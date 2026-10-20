local Picker = require("src.ui.game3.rs.trendy_phrase_policy")
local Contracts = require("src.core.game3.rs.easy_chat_contracts")
local P = {EMPTY = Contracts.EMPTY, groups = Picker.groups, groupMove = Picker.groupMove,
  wordMove = Picker.wordMove, alphabetWords = Picker.alphabetWords}

function P.mainMove(row, col, key, shape)
  local count = shape.wordCount or shape.count
  if key == "start" then return shape.rows, 2 end
  if key == "up" or key == "down" then
    row = (row + (key == "up" and -1 or 1)) % (shape.rows + 1)
    if count == 1 then return row, row == shape.rows and 2 or 0 end
    col = math.min(col, shape.columns - 1)
    if row ~= shape.rows and row * shape.columns + col >= count then col = row * shape.columns + col - count end
  elseif key == "left" or key == "right" then
    col = (col + (key == "left" and -1 or 1)) % (row == shape.rows and 3 or shape.columns)
    if row ~= shape.rows and row * shape.columns + col >= count then col = row * shape.columns + col - count end
  end
  return row, col
end
function P.valid(token, words) return Contracts.validate(token, words) end

function P.blueRamp(palette)
  local ramp = {}; for step = 0, 8 do ramp[step] = {} end
  local function trunc(n) return n < 0 and math.ceil(n) or math.floor(n) end
  for i = 1, 3 do
    local start, finish = assert(palette[i + 1]), assert(palette[i + 4])
    local value, delta, target = {}, {}, {}
    for component = 1, 3 do
      local unit = 2 ^ ((component - 1) * 5)
      value[component] = math.floor(start / unit) % 32 * 256
      target[component] = math.floor(finish / unit) % 32 * 256
      delta[component] = trunc((target[component] - value[component]) / 8)
    end
    for step = 0, 7 do
      local color = 0
      for component = 1, 3 do
        color = color + math.floor(value[component] / 256) % 32 * 2 ^ ((component - 1) * 5)
        value[component] = value[component] + delta[component]
      end
      ramp[step][i] = color
    end
    ramp[8][i] = finish % 32768
  end
  return ramp
end
return P
