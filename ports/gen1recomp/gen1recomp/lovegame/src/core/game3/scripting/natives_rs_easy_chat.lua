local R = require("src.core.game3.rse.init")
local Contracts = require("src.core.game3.rs.easy_chat_contracts")
local M = {BY_NAME = {}}
local INPUT, RESULT = 0x8004, 0x800D

local function apply(ctx, adapters, out)
  R.setSpecialVar(ctx, RESULT, out.result)
  if out.input ~= nil then R.setSpecialVar(ctx, INPUT, out.input) end
  if out.stringVar2 then
    if adapters and adapters.setStringVar then adapters.setStringVar(2, out.stringVar2) end
    ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[2] = out.stringVar2
  end
end

M.BY_NAME.ShowEasyChatScreen = function(ctx, adapters)
  local kind = R.specialVar(ctx, INPUT)
  if not Contracts.TYPES[kind] then return false end
  if kind == 9 then
    return require("src.core.game3.scripting.natives_rs_dewford").showTrendyPhrase(ctx, adapters)
  end
  if not (adapters and adapters.openRsEasyChat) then
    R.missing("easyChat", "native RS type" .. kind .. " openRsEasyChat host", adapters and adapters.log)
    R.setSpecialVar(ctx, RESULT, 0)
    return false
  end
  local session = R.session()
  local token = Contracts.prepare(session, kind, {slot = R.specialVar(ctx, 0x8005),
    person = R.specialVar(ctx, 0x8006), variant = R.specialVar(ctx, 0x8006)})
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    local finalized, opened = false, false
    local function commit(words)
      if finalized then return token.committed == true end
      local out, reason = Contracts.commit(token, words)
      if not out then return false, reason end
      apply(ctx, adapters, out); finalized = true
      return true
    end
    local function cancel()
      if not finalized then apply(ctx, adapters, Contracts.cancel(token)); finalized = true end
    end
    adapters.openRsEasyChat({type = kind, token = token, descriptor = token.descriptor,
      words = token.words, wordCount = token.wordCount, columns = token.columns, rows = token.rows,
      variant = token.variant, session = session,
      onOpened = function()
        if not opened then R.setFlag(Contracts.USED_FLAG, true, session); opened = true end
      end,
      validate = function(words) return Contracts.validate(token, words) end,
      declineSave = function(words) return Contracts.declineSave(token, words) end,
      commit = commit, cancel = cancel}, function(confirmed, words)
      if not finalized then
        if not confirmed or not commit(words) then cancel() end
      end
      done()
    end)
  end)
end
return M
