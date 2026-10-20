local R = require("src.core.game3.rse.init")
local Playback = require("src.core.game3.rs.tv_playback")
local M = {BY_NAME = {}}
local function vars(ctx)
  return ctx and ctx.stringVars or {}
end
local function rawVars(ctx)
  return ctx and ctx.rsTvStringVarBytes or {}
end
local function value(v) return type(v) == "function" and v() or v end
local function view(ctx, adapters)
  return {stringVars = vars(ctx), playerName = value(adapters and adapters.playerName) or ctx and ctx.playerName,
    rivalName = value(adapters and adapters.rivalName) or ctx and ctx.rivalName, dialect = "rs"}
end
function M.render(ctx, adapters, response)
  local TextIR = require("src.core.game3.scripting.text_ir")
  if response.text then return TextIR.toTextBox(TextIR.fromAscii(response.text, {dialect = "rs"}), view(ctx, adapters)) end
  local RomText = require("src.core.game3.rom_text")
  return RomText.box(RomText.key(response.group, response.index), view(ctx, adapters))
end
local function message(ctx, adapters, response)
  if adapters and adapters.setStringVar then
    for i = 1, 4 do if vars(ctx)[i] ~= nil then adapters.setStringVar(i, vars(ctx)[i]) end end
  end
  local body = M.render(ctx, adapters, response)
  M.lastText, M.lastMessage = response, body
  if ctx then ctx.messageOpen = true; ctx.printerDone = false end
  local host = adapters and (adapters.openMessageStay or adapters.openMessageAsync)
  if host then host(body, nil)
  elseif adapters and adapters.openMessage then adapters.openMessage(body)
  else error("RS TV field message host missing") end
end
M.BY_NAME.DoTVShow = function(ctx, adapters)
  local strings, bytes = vars(ctx), rawVars(ctx)
  local response, result = Playback.doTVShow(R.session(), R.specialVar(ctx, 0x8004), strings, bytes)
  if ctx and response then ctx.stringVars, ctx.rsTvStringVarBytes = strings, bytes end
  if result ~= nil then R.setSpecialVar(ctx, 0x800D, result) end
  if response then message(ctx, adapters, response) end
  return false
end
M.BY_NAME.DoTVShowInSearchOfTrainers = function(ctx, adapters)
  local strings, bytes = vars(ctx), rawVars(ctx)
  local response, result = Playback.doGabby(R.session(), strings, bytes)
  if ctx then ctx.stringVars, ctx.rsTvStringVarBytes = strings, bytes end
  R.setSpecialVar(ctx, 0x800D, result); message(ctx, adapters, response)
  return false
end
M.BY_NAME.DoPokeNews = function(ctx, adapters)
  local Rtc = require("src.core.game3.rtc")
  local strings, bytes = vars(ctx), rawVars(ctx)
  local response, result = Playback.doNews(R.session(), (Rtc.localTime or {}).hours or 0, strings, bytes)
  if ctx and response then ctx.stringVars, ctx.rsTvStringVarBytes = strings, bytes end
  R.setSpecialVar(ctx, 0x800D, result)
  if response then message(ctx, adapters, response) end
  return false
end
M.BY_NAME.ResetTVShowState = function()
  require("src.core.game3.rse.tv")._showState = 0
  return false
end
return M
