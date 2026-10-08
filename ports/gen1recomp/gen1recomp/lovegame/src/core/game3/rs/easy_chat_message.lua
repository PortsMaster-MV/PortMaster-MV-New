local M = {FILE = "data/generated/gba/rse/easy_chat_editor/manifest.lua"}
local FIELDS = {[0] = "easyChatProfile", [1] = "easyChatBattleStart", [2] = "easyChatBattleWon", [3] = "easyChatBattleLost"}

function M.metadata()
  local src = assert(require("src.core.game3.dataset").cache():read(M.FILE), "native RS Easy Chat message metadata missing")
  local man = assert(load(src, "@" .. M.FILE, "t", {}))()
  assert(man.layout == "rs" and man.editorVersion == 2 and man.messageWords and man.invalidWord, "native RS Easy Chat word bytes required")
  return man
end
function M.format(words, columns, rows, wordBytes, invalidWord)
  local out, index = {}, 1
  for row = 1, rows do
    for col = 1, columns do
      local id = tonumber(words and words[index]) or 65535
      index = index + 1
      if id ~= 65535 then
        local bytes = wordBytes[id] or assert(invalidWord, "native invalid-word bytes required")
        for _, b in ipairs(bytes) do if b == 255 then break end; out[#out + 1] = b end
        if col < columns then out[#out + 1] = 0 end
      end
    end
    out[#out + 1] = row == rows and 255 or 254
  end
  return out
end
function M.build(session, kind, man)
  local field = FIELDS[kind]
  if not field then return nil end
  local codec = require("src.save_convert.Gen3Save").forVersion(assert(session.version))
  assert(codec.L.FAMILY == "rs", "native RS Easy Chat message requires RS")
  man = man or M.metadata()
  local columns, rows = kind == 0 and 2 or 3, 2
  local bytes = M.format(session[field], columns, rows, man.messageWords, man.invalidWord)
  local IR = require("src.core.game3.scripting.text_ir")
  local ir = IR.decode(bytes, {dialect = "rs"})
  return {nativeBytes = bytes, text = IR.toAscii(ir), ir = ir, columns = columns, rows = rows, type = kind,
    fieldWindow = {template = "gMenuTextWindowTemplate", fontNum = 3, textMode = 2,
      left = 2, top = 15, lineLength = 26, autoScroll = true}}
end
return M
