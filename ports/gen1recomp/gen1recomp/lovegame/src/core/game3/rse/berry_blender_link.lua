-- pokeemerald/src/berry_blender.c:1293,1357,1812 (link berries and per-frame player input).
local LinkSession = {}
LinkSession.__index = LinkSession

local function seatOf(msg)
  return tonumber(msg and (msg.seat or msg.senderSeat))
end

function LinkSession.new(link, players)
  local self = setmetatable({ link = link, players = players or {}, berries = {}, frames = {},
    localSeat = type(link.getSeat) == "function" and tonumber(link:getSeat()) or 0,
    berrySent = false, sentFrame = nil, rngState = 0, round = 1, continueChoice = nil,
    waitKey = nil, waitTicks = 0 }, LinkSession)
  for _, row in ipairs(self.players) do
    self.rngState = (self.rngState + (tonumber(row.trainerId) or 0) + (tonumber(row.seat) or 0) * 257) % 65536
  end
  if self.rngState == 0 then self.rngState = 1 end
  for _, row in ipairs(self.players) do
    local seat = tonumber(row.seat)
    if seat ~= self.localSeat then self.frames[seat] = {} end
  end
  return self
end

function LinkSession:random()
  self.rngState = (self.rngState * 25173 + 13849) % 65536
  return self.rngState
end

function LinkSession:peerSeats()
  local out = {}
  for seat in pairs(self.frames) do out[#out + 1] = seat end
  table.sort(out)
  return out
end

function LinkSession:abort(reason)
  if self:isOpen() then
    self.link:send({ type = "game3_blender_abort", senderSeat = self.localSeat,
      round = self.round, reason = tostring(reason or "cancel") })
  end
end

function LinkSession:takeAbort()
  for _ = 1, 8 do
    local msg = self.link:take("game3_blender_abort")
    if not msg then break end
    if tonumber(msg.round) == self.round and self.frames[seatOf(msg)] then return msg end
  end
  return nil
end

function LinkSession:submitBerry(itemId)
  if self:takeAbort() then return nil, "abort" end
  if not self.berrySent then
    self.link:send({ type = "game3_blender_berry", senderSeat = self.localSeat, round = self.round, itemId = itemId })
    self.berrySent = true
    self.berries[self.localSeat] = tonumber(itemId)
  end
  local peers = self:peerSeats()
  for _ = 1, 16 do
    local msg = self.link:take("game3_blender_berry")
    if not msg then break end
    local seat = seatOf(msg)
    if self.frames[seat] and tonumber(msg.round) == self.round and tonumber(msg.itemId) and tonumber(msg.itemId) > 0 then
      self.berries[seat] = tonumber(msg.itemId)
    end
  end
  for _, seat in ipairs(peers) do
    if not self.berries[seat] then
      self.waitTicks = self.waitKey == "berry" and self.waitTicks + 1 or 1
      self.waitKey = "berry"
      if self.waitTicks > 3600 then return nil, "timeout" end
      return nil
    end
  end
  self.waitTicks, self.waitKey = 0, nil
  return self.berries
end

function LinkSession:exchangeFrame(frame, score)
  if self:takeAbort() then return nil, "abort" end
  frame = tonumber(frame) or 0
  if self.sentFrame ~= frame then
    self.link:send({ type = "game3_blender_frame", senderSeat = self.localSeat,
      round = self.round, frame = frame, score = tonumber(score) or 0 })
    self.sentFrame = frame
  end
  for _ = 1, 32 do
    local msg = self.link:take("game3_blender_frame")
    if not msg then break end
    local seat, msgFrame = seatOf(msg), tonumber(msg.frame)
    if self.frames[seat] and tonumber(msg.round) == self.round and msgFrame and msgFrame >= frame then
      self.frames[seat][msgFrame] = tonumber(msg.score) or 0
    end
  end
  local out = {}
  for _, seat in ipairs(self:peerSeats()) do
    local remote = self.frames[seat][frame]
    if remote == nil then
      local key = "frame:" .. tostring(frame)
      self.waitTicks = self.waitKey == key and self.waitTicks + 1 or 1
      self.waitKey = key
      if self.waitTicks > 3600 then return nil, "timeout" end
      return nil
    end
    out[seat] = remote
  end
  self.waitTicks, self.waitKey = 0, nil
  self.sentFrame = nil
  for _, seat in ipairs(self:peerSeats()) do self.frames[seat][frame] = nil end
  return out
end

function LinkSession:exchangeContinue(choice)
  if self:takeAbort() then return nil, "abort" end
  if not self.continueChoice then
    self.continueChoice = { sent = true, choices = { [self.localSeat] = tonumber(choice) or 1 } }
    self.link:send({ type = "game3_blender_continue", senderSeat = self.localSeat,
      round = self.round, choice = self.continueChoice.choices[self.localSeat] })
  end
  local state = self.continueChoice
  if self.localSeat == 0 and not state.result then
    for _ = 1, 16 do
      local msg = self.link:take("game3_blender_continue")
      if not msg then break end
      local seat = seatOf(msg)
      if self.frames[seat] and tonumber(msg.round) == self.round and tonumber(msg.choice) then
        state.choices[seat] = tonumber(msg.choice)
      end
    end
    for _, seat in ipairs(self:peerSeats()) do
      if state.choices[seat] == nil then
        self.waitTicks = self.waitKey == "continue" and self.waitTicks + 1 or 1
        self.waitKey = "continue"
        if self.waitTicks > 3600 then return nil, "timeout" end
        return nil
      end
    end
    local continue = true
    local reason, reasonSeat = 0, nil
    for _, seat in ipairs(self:peerSeats()) do
      local value = state.choices[seat]
      if value ~= 0 then continue = false; reason, reasonSeat = value, seat; break end
    end
    if state.choices[0] ~= 0 then continue = false; reason, reasonSeat = state.choices[0], 0 end
    state.result = { continue = continue, reason = reason, seat = reasonSeat }
    self.link:send({ type = "game3_blender_continue_result", senderSeat = 0,
      round = self.round, continue = continue, reason = reason, reasonSeat = reasonSeat })
  elseif self.localSeat ~= 0 and not state.result then
    local msg = self.link:take("game3_blender_continue_result", function(row)
      return tonumber(row.round) == self.round
    end)
    if msg then state.result = { continue = msg.continue == true,
      reason = tonumber(msg.reason) or 0, seat = tonumber(msg.reasonSeat) } end
    if not state.result then
      self.waitTicks = self.waitKey == "continue" and self.waitTicks + 1 or 1
      self.waitKey = "continue"
      if self.waitTicks > 3600 then return nil, "timeout" end
    end
  end
  if state.result then self.waitTicks, self.waitKey = 0, nil end
  return state.result
end

function LinkSession:nextRound()
  self.round = self.round + 1
  self.berries, self.berrySent, self.sentFrame, self.continueChoice = {}, false, nil, nil
  self.waitTicks, self.waitKey = 0, nil
  for seat in pairs(self.frames) do self.frames[seat] = {} end
end

function LinkSession:isOpen()
  return self.link and self.link.isOpen and self.link:isOpen()
end

return LinkSession
