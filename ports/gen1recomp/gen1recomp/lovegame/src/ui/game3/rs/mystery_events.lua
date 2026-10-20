local Kit = require("src.ui.game3.rse.scene_kit")
local Pal = require("src.core.game3.pal_fade")
local Chrome = require("src.ui.game3.chrome")
local Link = require("src.core.game3.link.init")
local Event = require("src.core.game3.rs.mystery_event")
local M = {MESSAGE = "rs_mystery_event", REQUEST = "rs_mystery_event_request"}
M.__index = M
function M.send(link, bytes)
  if type(bytes) == "string" then bytes = {bytes:byte(1, #bytes)} end
  if type(bytes) ~= "table" or #bytes == 0 or #bytes > Event.MAX_BYTES then return false end
  local copy = {}
  for i, b in ipairs(bytes) do
    if type(b) ~= "number" or b < 0 or b > 255 or b % 1 ~= 0 then return false end
    copy[i] = b
  end
  return link:send({type = M.MESSAGE, bytes = copy})
end
function M.new(opts)
  opts = opts or {}
  local saved = opts.save or Kit.loadRawSave()
  local session = opts.session or (saved and require("src.core.game3.save_schema_firered").fromSaveTable(saved))
  assert(session, "RS Mystery Events require an existing save")
  local self = setmetatable({game = opts.game, session = session, opts = opts, state = "fade_in",
    pal = Pal.new(), ticks = 0, step = Kit.stepper()}, M)
  self.pal:beginFade(Pal.ALL, 0, 16, 0, Pal.BLACK)
  return self
end
function M:message(source, vars)
  self.printer = Kit.printer(source, {speed = 2, canSpeedUp = false, ctx = {stringVars = vars or {}}})
end
function M:close()
  require("src.ui.game3.rs.cable_lobby").close()
  Link.clientCall("leaveGroup"); Link.closeLink("rs_mystery_event_exit")
end
function M:exit()
  self:close(); self.state = "exit"
  self.pal:beginFade(Pal.ALL, 0, 0, 16, Pal.BLACK)
end
function M:failed(why)
  self.error = why; self.loading = false
  self:close(); self:message("gSystemText_LoadingError"); self.state = "result_print"
end
function M:startEntry()
  local profile = self.opts.profile
  if not profile then profile = require("src.online.ArenaData").liveProfile3(self.game, "g3_link") end
  local s = self.session
  local avatar = {name = s.name or s.playerName or "", gender = s.gender or 0, version = s.version,
    trainerId = require("src.core.game3.link.rs").trainerId(s)}
  local spec = {wire = "mystery_event", linkType = 0x5501, min = 2, max = 2, profile = profile,
    avatar = avatar, game = self.game,
    hello = require("src.link.Game3Link").hello(self.game, 0x5501, {session = s, version = s.version,
      name = avatar.name, gender = avatar.gender, trainerId = avatar.trainerId}),
    connect = function()
      return require("src.online.Connect").start({source = "game", version = s.version,
        trainerName = avatar.name, profiles = {assert(profile, "Mystery Event live profile missing")},
        presence = {where = "game", status = "busy", version = s.version}})
    end}
  self.ctx = require("src.core.game3.scripting.ctx").new()
  local function ready()
    Kit.playSe("SE_PIN")
    self.state = "ready_print"; self:message("gSystemText_LoadEventPressA")
    return false, 1
  end
  local yielded, result = require("src.core.game3.rs.link_entry").run(self.ctx, {}, spec, ready)
  if self.state == "ready_print" then return end
  if yielded then self.state = "lobby" else self:failed(result) end
end
function M:frame(inp)
  self.ticks = self.ticks + 1
  local lk = Link.link
  if lk then lk:update(1 / 60) end
  if self.opts.payload and lk and lk:isReady() and lk:take(M.REQUEST) then M.send(lk, self.opts.payload) end
  if self.state == "fade_in" then
    if not self.pal:fadeActive() then self:message("gSystemText_LinkStandby"); self.state = "standby_print" end
  elseif self.state == "standby_print" then
    self.printer:run(inp)
    if not self.printer:isActive() then self:startEntry() end
  elseif self.state == "lobby" then
    require("src.ui.game3.rs.cable_lobby").update(inp)
    if self.ctx.nativePoll and self.ctx.nativePoll() and self.state == "lobby" then
      local result = self.ctx.specialVars[0x800D]
      if result == 5 then self:exit() else self:failed(result) end
    end
  elseif self.state == "ready_print" then
    self.printer:run(inp); if not self.printer:isActive() then self.state = "ready" end
  elseif self.state == "ready" then
    if inp.new.b then Kit.playSe("SE_SELECT"); self:exit()
    elseif not lk or not lk:isOpen() then self:failed("peer_closed")
    elseif inp.new.a then
      Kit.playSe("SE_SELECT")
      local players = lk:players()
      if #players ~= 2 or players[1].language ~= players[2].language then self:failed("peer_language_or_count")
      else self:message("gSystemText_DontCutLink"); self.state = "receive_print"; self.loading = true end
    end
  elseif self.state == "receive_print" then
    if not lk or not lk:isOpen() then self:failed("peer_closed")
    else self.printer:run(inp) end
    if self.state == "receive_print" and not self.printer:isActive() then
      lk:send({type = M.REQUEST}); self.state, self.ticks = "receive", 0
    end
  elseif self.state == "receive" then
    if not lk or not lk:isOpen() then self:failed("peer_closed")
    else
      local block = lk:take(M.MESSAGE)
      if block then self.block, self.state = block.bytes, "received"
      elseif self.ticks > 1200 then self:failed("receive_timeout") end
    end
  elseif self.state == "received" then
    self:close(); self.state = "execute"
  elseif self.state == "execute" then
    self.result = Event.run(self.block, self.session, {adapters = self.opts.adapters,
      saveBlock1Address = self.opts.saveBlock1Address})
    self.block = nil
    if self.result.save then
      local save = require("src.core.game3.save_schema_firered").toSaveTable(self.session)
      local ok, written = pcall(require("src.core.SaveData").save, save)
      if not ok or written == false then return self:failed("save_failed") end
      self.saved = save; if self.game then self.game.save = save end
    end
    self.loading = false
    self:message(self.result.message, self.result.stringVars); self.state = "result_print"
  elseif self.state == "result_print" then
    self.printer:run(inp)
    if not self.printer:isActive() then self.loading, self.state = false, "result" end
  elseif self.state == "result" then if inp.new.a then Kit.playSe("SE_SELECT"); self:exit() end
  elseif self.state == "exit" and not self.pal:fadeActive() then return "title" end
  self.pal:updateFade()
end
function M:update(input, dt)
  self.step:collect(input)
  return self.step:run(dt, function(inp) return self:frame(inp) end)
end
function M:draw()
  love.graphics.clear(0, 0, 0, 1)
  if self.state == "lobby" then require("src.ui.game3.rs.cable_lobby").draw()
  else
    Chrome.stdFrame(1, 15, 28, 4)
    if self.printer then self.printer:draw(8, 120, {colors = Kit.messageColors()}) end
    if self.loading then
      Chrome.stdFrame(7, 6, 16, 2)
      require("src.ui.game3.frlg_font").draw(require("src.core.game3.rom_text").plain("gSystemText_LoadingEvent"),
        56, 48, {colors = Kit.messageColors()})
    end
  end
  Kit.drawFade(self.pal, 0)
end
function M:destroy() self:close() end
return M
