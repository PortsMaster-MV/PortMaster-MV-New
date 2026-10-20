local M = {}
function M.matches(session)
  local id = require("src.core.game3.profile").forSession(session).id
  return id == "ruby" or id == "sapphire"
end
function M.session(session)
  if session then return session end
  local R = package.loaded["src.core.game3.runtime"]
  return R and R.getSession and R.getSession()
end
function M.recordStatCalculation(oldMax, newMax)
  local delta = (tonumber(newMax) or 0) - (tonumber(oldMax) or 0)
  M._levelUpHP = delta == 0 and 1 or delta
end
function M.levelUpHP() return M._levelUpHP end
function M.restoreStatCalculation(value) M._levelUpHP = value end
function M.reset() M._levelUpHP = nil end
function M.info(session)
  session = M.session(session)
  if not M.matches(session) then return nil end
  local b = require("src.ui.game3.rs.berry_tag_data").enigma(session)
  if not b then return nil end
  local raw = session.enigmaBerryNativeBytes
  b.maxYield, b.minYield, b.stageDuration, b.smoothness = raw[11], raw[12], raw[21], raw[27]
  b.holdEffect, b.holdEffectParam, b.itemEffect = raw[1321], raw[1322], {}
  for i = 1, 18 do b.itemEffect[i] = raw[1302 + i] end
  return b
end
function M.battleInfo(raw)
  if type(raw) ~= "table" or #raw ~= 28 then return nil end
  local count = 0
  for key in pairs(raw) do
    if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 28 then return nil end
    count = count + 1
  end
  if count ~= 28 then return nil end
  for i = 1, 28 do
    local b = raw[i]
    if type(b) ~= "number" or b < 0 or b > 255 or b % 1 ~= 0 then return nil end
  end
  local effect = {holdEffect = raw[8], holdEffectParam = raw[27], itemEffect = {}, nameBytes = {}, nativeBytes = {}}
  for i = 1, 28 do effect.nativeBytes[i] = raw[i] end
  for i = 1, 7 do effect.nameBytes[i] = raw[i] end
  for i = 1, 18 do effect.itemEffect[i] = raw[8 + i] end
  local text = {}; for i = 1, 7 do text[i] = raw[i] end; text[8] = 255
  local IR = require("src.core.game3.scripting.text_ir")
  effect.name = IR.toAscii(IR.decode(text, {dialect = "rs"}))
  return effect
end
M.decodeBattle = M.battleInfo
function M.packBattle(session)
  session = M.session(session)
  if not M.matches(session) then return nil end
  local raw = session and session.enigmaBerryNativeBytes
  if type(raw) ~= "table" then raw = {} end
  local out = {}
  for i = 1, 28 do out[i] = 0 end
  for i = 1, 7 do out[i] = raw[i] or 0 end
  out[8], out[27] = raw[1321] or 0, raw[1322] or 0
  for i = 1, 18 do out[8 + i] = raw[1302 + i] or 0 end
  return out
end
function M.localBattleInfo(session)
  session = M.session(session)
  if not M.matches(session) then return nil end
  local raw = session and session.enigmaBerryNativeBytes
  if type(raw) ~= "table" or #raw < 1328 then return {holdEffect = 0, holdEffectParam = 0, itemEffect = {}} end
  local b = {holdEffect = raw[1321], holdEffectParam = raw[1322], itemEffect = {}}
  for i = 1, 18 do b.itemEffect[i] = raw[1302 + i] end
  return b
end
function M.itemEffect(session)
  local berry = M.localBattleInfo(session)
  return berry and berry.itemEffect
end
function M.effectType(e)
  local bit = require("bit")
  local function has(i, mask) return bit.band(e[i] or 0, mask) ~= 0 end
  if has(1, 0x3F) or (e[2] or 0) ~= 0 or (e[3] or 0) ~= 0 or has(4, 0x80) then return 0 end
  if has(1, 0x40) then return 10 end
  if has(4, 0x40) then return 1 end
  local status = bit.band(e[4] or 0, 0x3F)
  if status ~= 0 or has(1, 0x80) then
    return ({[0x20] = 4, [0x10] = 3, [8] = 5, [4] = 6, [2] = 7, [1] = 8})[status]
      or (status == 0 and 9 or 11)
  end
  if has(5, 0x44) then return 2 end
  for _, p in ipairs({{5,2,12},{5,1,13},{6,8,14},{6,4,15},{6,2,16},{6,1,17},{5,128,18},{5,32,19},{6,16,20},{5,24,21}}) do
    if has(p[1], p[2]) then return p[3] end
  end
  return 22
end
function M.fieldKind(e, inBattle)
  local typ = M.effectType(e)
  if typ == 0 then return inBattle and "battle" or "none" end
  if typ == 1 then return inBattle and "none" or "level" end
  if typ == 2 then return require("bit").band(e[5] or 0, 0x40) ~= 0 and "revive" or "heal" end
  if typ >= 3 and typ <= 7 or typ == 11 or (inBattle and (typ == 8 or typ == 9)) then return "status" end
  if typ == 10 then return inBattle and "none" or "revive" end
  if typ >= 12 and typ <= 17 then return inBattle and "none" or "vitamin" end
  if typ >= 19 and typ <= 21 then return inBattle and typ ~= 21 and "none" or "pp" end
  return "none"
end
function M.applyEffects(e, ops)
  local bit = require("bit")
  local changed, at, friendshipMod = false, 7, 0
  local function has(i, mask) return bit.band(e[i] or 0, mask) ~= 0 end
  local function call(name, ...)
    local fn = ops[name]
    return fn and fn(...) or false
  end
  local function mark(value) if value then changed = true end end
  mark(call("volatile", e, "infatuation"))
  mark(call("stats", e))
  if has(4, 0x40) then mark(call("level")) end
  mark(call("status", e))
  mark(call("volatile", e, "confusion"))
  if has(5, 0x20) then mark(call("ppBoost", false)) end
  local function ev(i, mask, key)
    if not has(i, mask) then return true end
    local outcome = call("ev", key, e[at] or 0)
    if outcome == "abort" then return false end
    if outcome == "applied" then at = at + 1; changed = true end
    return true
  end
  if not ev(5, 1, "hp") or not ev(5, 2, "atk") then
    return false, {aborted = true, parameterIndex = at}
  end
  if has(5, 4) then
    mark(call("hp", e[at] or 0, has(5, 0x40)))
    at = at + 1
  end
  if has(5, 8) then
    local one = has(5, 0x10)
    local applied = call("ppHeal", e[at] or 0, one)
    mark(applied)
    if not one or applied then at = at + 1 end
  end
  if has(5, 0x80) and call("evolve") then
    return true, {evolved = true, parameterIndex = at}
  end
  for _, spec in ipairs({{1,"def"},{2,"spe"},{4,"spd"},{8,"spa"}}) do
    if not ev(6, spec[1], spec[2]) then return false, {aborted = true, parameterIndex = at} end
  end
  if has(6, 0x10) then mark(call("ppBoost", true)) end
  for tier, mask in ipairs({32,64,128}) do
    if has(6, mask) then
      local raw = e[at] or 0
      if changed and friendshipMod == 0 and call("friendshipTier") == tier then
        friendshipMod = raw >= 128 and raw - 256 or raw
        call("friendship", tier, friendshipMod)
      end
      at = at + 1
    end
  end
  return changed, {parameterIndex = at}
end
function M.parameters(e)
  local bit = require("bit")
  local out, at = {evs = {}, friendship = {}}, 7
  local function param() local value = e[at] or 0; at = at + 1; return value end
  for _, p in ipairs({{5,1,"hp"},{5,2,"atk"},{5,4,"hpHeal"},{5,8,"ppHeal"},
      {6,1,"def"},{6,2,"spe"},{6,4,"spd"},{6,8,"spa"}}) do
    if bit.band(e[p[1]] or 0, p[2]) ~= 0 then
      local value = param()
      if p[3] == "hpHeal" or p[3] == "ppHeal" then out[p[3]] = value else out.evs[p[3]] = value end
    end
  end
  for i, mask in ipairs({32,64,128}) do
    if bit.band(e[6] or 0, mask) ~= 0 then local n = param(); out.friendship[i] = n >= 128 and n - 256 or n end
  end
  return out
end
function M.installBattle(st)
  if not M.matches(st.session) then return end
  st.enigmaBerries = st.enigmaBerries or {}
  if not st.link then
    st.enigmaBerries[0], st.enigmaBerries[2] = M.localBattleInfo(st.session), M.localBattleInfo(st.session)
    st.enigmaBerries[1], st.enigmaBerries[3] = {holdEffect = 0, holdEffectParam = 0}, {holdEffect = 0, holdEffectParam = 0}
  end
end
return M
