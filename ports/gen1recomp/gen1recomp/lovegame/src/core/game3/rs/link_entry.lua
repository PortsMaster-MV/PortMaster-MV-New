local Link = require("src.core.game3.link.init")
local Strings = require("src.core.Strings")
local M = {}
-- pokeruby/cable_club.c:558
M.SERVICES = {
  [1] = {wire = "battle_single", linkType = 0x2233, min = 2, max = 2},
  [2] = {wire = "battle_double", linkType = 0x2244, min = 2, max = 2},
  [5] = {wire = "battle_multi", linkType = 0x2255, min = 4, max = 4},
  trade = {wire = "trade", linkType = 0x1133, min = 2, max = 2},
  records = {wire = "record_corner", linkType = 0x3311, min = 2, max = 4},
  blender = {wire = "berry_blender", linkType = 0x4411, min = 2, max = 4},
}
function M.contest(category)
  local names = {"cool", "beauty", "cute", "smart", "tough"}
  return {wire = "contest_" .. assert(names[(tonumber(category) or 0) + 1]), linkType = 0x6601, min = 4, max = 4}
end
function M.run(ctx, adapters, spec, handshake)
  assert(spec, "RS cable service missing")
  local live = Link.link
  if live and live.isOpen and live:isOpen() then return handshake(ctx, adapters) end
  local N = require("src.core.game3.scripting.natives")
  local UI = require("src.ui.game3.rs.cable_lobby")
  local phase, ticks, done, role, pending, answered = "connect", 0, false, nil, nil, {}
  local seenGroup, goneTicks, awayTicks = false, 0, 0
  local profile = assert(spec.profile or Link.liveProfile(), "RS link profile missing")
  local avatar = spec.avatar or Link.avatar()
  local function finish(code)
    Link.clientCall("leaveGroup"); Link.closeLink("rs_cable_failed")
    UI.close(); Link.clientCall("groupList", nil); Link.setStatus("busy")
    Link.setResult(ctx, code); done = true
  end
  local function offline(member)
    if type(member) ~= "table" then return false end
    if member.online == false then return true end
    for _, entry in ipairs(Link.clientCall("lobby") or {}) do
      if type(entry) == "table" and entry.id ~= nil and entry.id == member.id then return entry.online == false end
    end
    return false
  end
  local function liveMembers(group)
    local members = type(group) == "table" and type(group.members) == "table" and group.members or {}
    local live = {}
    for _, member in ipairs(members) do
      if not offline(member) then live[#live + 1] = member end
    end
    return live, #live == #members
  end
  local function rows()
    if phase == "mode" then return {{id = "leader", label = Strings("CREATE GROUP")}, {id = "join", label = Strings("JOIN GROUP")}} end
    if phase == "ask" then return {{id = "yes", label = Strings("YES")}, {id = "no", label = Strings("NO")}} end
    local out, group = {}, Link.clientCall("group")
    if role == "leader" then
      local members, all = liveMembers(group)
      for _, member in ipairs(members) do
        local av = member.avatar or {}
        out[#out + 1] = {label = av.name or member.name or "", disabled = true}
      end
      out[#out + 1] = {id = "start", label = Strings("START"), disabled = not all or #members < spec.min or #members > spec.max}
    elseif phase == "list" then
      for _, groupRow in ipairs(Link.clientCall("groups", spec.wire) or {}) do
        local av = groupRow.avatar or {}
        out[#out + 1] = {id = groupRow.leader, label = av.name or groupRow.name or "",
          disabled = (tonumber(groupRow.joined) or 0) >= (tonumber(groupRow.max) or spec.max)}
      end
    end
    return out
  end
  local poll
  local function select(row)
    if phase == "mode" then
      role, phase = row.id, "list"
      if role == "leader" then Link.clientCall("openGroup", spec.wire, profile, avatar)
      else Link.clientCall("groupList", spec.wire, profile) end
    elseif phase == "ask" then
      answered[pending.id] = true
      Link.clientCall("acceptGroup", pending.id, row.id == "yes"); pending, phase = nil, "list"
    elseif role == "leader" and row.id == "start" then
      Link.clientCall("startGroup"); phase, ticks = "starting", 0
    elseif role == "join" then Link.clientCall("joinGroup", row.id, profile, avatar); phase, ticks = "waiting", 0 end
  end
  N.yieldHost(ctx, adapters, function() end)
  Link.setResult(ctx, 0)
  if not Link.online() then
    local ok = (spec.connect or Link.connect)()
    if not ok then finish(Link.LINKUP.CONNECTION_ERROR); return false, Link.LINKUP.CONNECTION_ERROR end
  else phase = "mode" end
  poll = function()
    if done then return true end
    ticks = ticks + 1
    if phase == "connect" then
      if Link.online() then phase, ticks = "mode", 0
      elseif ticks > 1200 or Link.connectState() == "error" then finish(Link.LINKUP.CONNECTION_ERROR) end
      return done
    end
    if not Link.online() then finish(Link.LINKUP.CONNECTION_ERROR); return true end
    if phase == "ready" then
      local lk = Link.link
      if not lk or not lk:isOpen() then finish(Link.LINKUP.CONNECTION_ERROR); return true end
      if lk:isReady() then
        UI.close(); Link.clientCall("groupList", nil); Link.setStatus("busy")
        local yielded, value = handshake(ctx, adapters)
        if not yielded then Link.setResult(ctx, value or Link.getVar(ctx, Link.VAR_RESULT)); return true end
        return false
      elseif ticks > 600 then finish(Link.LINKUP.CONNECTION_ERROR); return true end
      return false
    end
    local room = Link.clientCall("room")
    if type(room) == "table" and room.stage == "battling" and room.match ~= nil then
      UI.close()
      if not Link.openRelay({linkType = spec.linkType, game = spec.game, hello = spec.hello}) then finish(Link.LINKUP.CONNECTION_ERROR); return true end
      phase, ticks = "ready", 0
      return false
    end
    local g = Link.clientCall("group")
    if role == "leader" and phase == "ask" then
      local still = false
      for _, request in ipairs(type(g) == "table" and type(g.pending) == "table" and g.pending or {}) do
        if pending and request.id == pending.id and not offline(request) then still = true end
      end
      if not still then
        if pending then answered[pending.id] = true end
        pending, phase = nil, "list"
        UI.cursor = 1
      end
    elseif role == "leader" and phase == "list" then
      for _, request in ipairs(type(g) == "table" and type(g.pending) == "table" and g.pending or {}) do
        if not answered[request.id] and not offline(request) then pending, phase = request, "ask"; break end
      end
    elseif role == "leader" and phase == "starting" and type(g) == "table" then
      local members, all = liveMembers(g)
      if not all or #members < spec.min then phase, ticks = "list", 0 end
    elseif role == "join" and phase == "waiting" then
      if type(g) == "table" then
        seenGroup, goneTicks = true, 0
        local leader
        for _, member in ipairs(type(g.members) == "table" and g.members or {}) do
          if member.id == g.leader then leader = member end
        end
        awayTicks = offline(leader) and awayTicks + 1 or 0
        if awayTicks > 600 then finish(Link.LINKUP.CONNECTION_ERROR); return true end
        ticks = 0
      elseif seenGroup then
        goneTicks = goneTicks + 1
        if goneTicks > 120 then finish(Link.LINKUP.CONNECTION_ERROR); return true end
      end
    end
    if not done and (phase == "starting" or phase == "waiting") and ticks > 1200 then finish(Link.LINKUP.CONNECTION_ERROR); return true end
    return false
  end
  ctx.nativePoll = poll
  UI.show({rows = rows, select = select, tick = function()
    if ctx.nativePoll == poll then poll() end
  end,
    title = function() return phase == "ask" and Strings("ADD %s?", (pending.avatar or {}).name or pending.name or "") or Strings(spec.wire:upper():gsub("_", " ")) end,
    cancel = function() finish(Link.LINKUP.FAILED) end})
  return true
end
return M
