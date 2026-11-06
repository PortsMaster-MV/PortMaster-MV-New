local R = require("src.core.game3.rse.init")
local Message = require("src.core.game3.rs.easy_chat_message")
local M = {BY_NAME = {}}
M.BY_NAME.sub_80EB7C4 = function(ctx, adapters)
  local kind = R.specialVar(ctx, 0x8004)
  if kind < 0 or kind > 3 then return false end
  local presentation = Message.build(R.session(), kind)
  if ctx then
    ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[4] = presentation.text
    ctx.rsEasyChatStringVarBytes = ctx.rsEasyChatStringVarBytes or {}
    ctx.rsEasyChatStringVarBytes[4] = presentation.nativeBytes
  end
  if adapters and adapters.setStringVar then adapters.setStringVar(4, presentation.text) end
  if not (adapters and adapters.rsFieldMessageBoxMode and adapters.openRsFieldAutoScrollMessage) then
    R.missing("easyChat", "native RS special96 field auto-scroll host", adapters and adapters.log)
    return false
  end
  -- field_message_box.c:82
  if adapters.rsFieldMessageBoxMode() ~= 0 then return false end
  local printed = false
  local accepted = adapters.openRsFieldAutoScrollMessage(presentation, function()
    printed = true
    if ctx then ctx.printerDone = true; ctx.rsFieldMessageBoxMode = 0 end
  end)
  if accepted ~= false and ctx then
    ctx.messageOpen, ctx.printerDone = true, printed
    ctx.rsFieldMessageBoxMode = printed and 0 or 2
  end
  return false
end
return M
