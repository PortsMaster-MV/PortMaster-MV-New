local bit = require("bit")
local IR = require("src.core.game3.scripting.text_ir")
local Text = require("src.core.game3.rom_text")
local M = {LOAD_OK = 0, LOAD_ERROR = 1, SUCCESS = 2, FAILURE = 3, MAX_BYTES = 0x7D4}
local function rawString(bytes)
  local out = {}; for i, b in ipairs(bytes) do out[i] = string.char(b) end
  return table.concat(out)
end
local function crc(bytes)
  local value = 0x1121
  for _, b in ipairs(bytes) do
    value = bit.bxor(value, b)
    for _ = 1, 8 do
      if bit.band(value, 1) ~= 0 then value = bit.bxor(bit.rshift(value, 1), 0x8408)
      else value = bit.rshift(value, 1) end
    end
  end
  return bit.band(bit.bnot(value), 0xFFFF)
end
M.crc = crc
function M.run(bytes, session, opts)
  opts = opts or {}
  local result = {status = 0, stringVars = {"", "", ""}, valid = false}
  local function message(key) result.message = Text.ir(key) end
  local function execute()
    assert(require("src.core.game3.rs.enigma").matches(session), "Mystery Events require RS")
    if type(bytes) == "string" then bytes = {bytes:byte(1, #bytes)} end
    assert(type(bytes) == "table" and #bytes > 0 and #bytes <= M.MAX_BYTES, "invalid Mystery Event size")
    for _, b in ipairs(bytes) do assert(type(b) == "number" and b >= 0 and b <= 255 and b % 1 == 0, "invalid Mystery Event byte") end
    local pos, base, stopped = 1, 0, false
    local C = require("src.core.game3.constants").of(session.version)
    local Flags = require("src.core.game3.scripting.flags")
    local codec = require("src.save_convert.Gen3Save").forVersion(session.version)
    local function byte() local b = assert(bytes[pos], "truncated Mystery Event"); pos = pos + 1; return b end
    local function half() return byte() + byte() * 256 end
    local function word() return half() + half() * 65536 end
    local function pointer() return word() - base + 1 end
    local function slice(first, count)
      assert(first >= 1 and count >= 0 and first + count - 1 <= #bytes, "Mystery Event pointer outside payload")
      local out = {}; for i = first, first + count - 1 do out[#out + 1] = bytes[i] end
      return out
    end
    local function text(at, length)
      local out = {}
      for i = at, math.min(#bytes, at + (length or #bytes) - 1) do
        out[#out + 1] = bytes[i]; if bytes[i] == 255 then break end
      end
      return IR.decode(out, {dialect = "rs"})
    end
    local function success(key) message(key); result.status = M.SUCCESS end
    local guard = 0
    while not stopped do
      guard = guard + 1; assert(guard <= #bytes, "Mystery Event runaway")
      local op, yields = byte(), false
      if op == 0 then
      elseif op == 1 then
        base = word()
        local lang1, lang2, rs, version = half(), word(), half(), word()
        local mask = session.version == "sapphire" and 256 or 128
        result.valid = bit.band(lang1, 2) ~= 0 and bit.band(lang2, 2) ~= 0
          and bit.band(rs, 4) ~= 0 and bit.band(version, mask) ~= 0
        if not result.valid then result.status = M.FAILURE; message("gText_MysteryEventCantBeUsed") end
        yields = true
      elseif op == 2 then stopped, yields = true, true
      elseif op == 3 then
        local status, at = byte(), pointer()
        if status == 255 or status == result.status then result.message = text(at) end
      elseif op == 4 then result.status = byte()
      elseif op == 5 then
        local at = pointer()
        local Space = require("src.core.game3.scripting.space")
        local bundle = Space.ensureBundle()
        local Vm = require("src.core.game3.scripting.vm")
        local Bag = require("src.core.game3.bag")
        local Items = require("src.core.game3.items_data")
        local inherited = opts.adapters or (Space.vm and Space.vm.adapters)
          or require("src.core.game3.scripting.adapters").stub()
        local adapters = setmetatable({
          playerName = session.name or session.playerName or "PLAYER",
          modifyItem = function(op, item, qty)
            local id = Items.toNumericId(item) or item
            if op == "removeitem" then return Bag.remove(session.bag, id, qty) end
            return Bag.add(session.bag, id, qty)
          end,
          giveMonToPlayer = function(species, level, item, nickname)
            local code, mon, box, slot = require("src.core.game3.party").giveMonToPlayer(session, species, level, nickname)
            -- pokeruby/contest_util.c:411
            if mon then mon.item = Items.toNumericId(item) or tonumber(item) or 0; mon.heldItem = mon.item end
            return code, mon, box, slot
          end,
          giveEggToPlayer = function(species)
            return require("src.core.game3.party").giveEggToPlayer(session, species)
          end,
          checkItem = function(item, qty)
            return Bag.has(session.bag, Items.toNumericId(item) or item, qty)
          end,
          checkItemSpace = function(item, qty)
            return Bag.canAdd(session.bag, Items.toNumericId(item) or item, qty)
          end,
        }, {__index = inherited})
        local vm = Vm.new({scripts = {}, text = {}, movements = {}, store = session,
          adapters = adapters})
        for k, v in pairs(bundle.scripts or {}) do vm.scripts[k] = v end
        for k, v in pairs(bundle.text or {}) do vm.text[k] = v end
        for k, v in pairs(bundle.movements or {}) do vm.movements[k] = v end
        local resume = vm.resume
        vm.resume = function(self)
          self.resume = resume
          self.ctx.stringVars = result.stringVars
          return resume(self)
        end
        vm.ctx.rsRamSession = session
        local key = require("src.core.game3.rs.ram_script").compile(bytes, vm, {start = at, base = base, prefix = "rsevent:"})
        vm:start(key)
        assert(not vm:isRunning(), "immediate Mystery Event script yielded")
        if vm.ctx.mysteryEventStatus ~= nil then result.status = vm.ctx.mysteryEventStatus end
        if type(result.stringVars[4]) == "string" then result.message = IR.fromAscii(result.stringVars[4]) end
      elseif op == 6 then
        local group, num, id, first, last = byte(), byte(), byte(), pointer(), pointer()
        require("src.core.game3.rs.ram_script").install(session, slice(first, last - first), group, num, id)
      elseif op == 7 then
        local at = pointer()
        local E = require("src.core.game3.rs.enigma")
        local old = E.info(session)
        result.stringVars[1] = codec.decodeString(rawString(session.enigmaBerryNativeBytes or {}), 0, 7)
        session.enigmaBerryNativeBytes = slice(at, 1328)
        -- load_save.c:23
        local ramBase = opts.saveBlock1Address or 0x02025734
        if ramBase then
          for _, off in ipairs({12, 16}) do
            local addr = ramBase + 0x3160 + (off == 12 and 1212 or 1257)
            for i = 0, 3 do session.enigmaBerryNativeBytes[off + i + 1] = math.floor(addr / 256 ^ i) % 256 end
          end
        end
        result.stringVars[2] = codec.decodeString(rawString(session.enigmaBerryNativeBytes), 0, 7)
        success(not old and "gText_MysteryEventBerry" or result.stringVars[1] ~= result.stringVars[2]
          and "gText_MysteryEventBerryTransform" or "gText_MysteryEventBerryObtained")
        if E.info(session) then Flags.setVar(session, nil, C:require("vars", "VAR_ENIGMA_BERRY_AVAILABLE"), 1)
        else result.status = M.LOAD_ERROR end
      elseif op == 8 then
        local index, id = byte(), byte()
        require("src.core.game3.rse.ribbons").giveGiftRibbonToParty(session, index, id,
          function(name) Flags.setFlag(session, nil, C:require("flags", name), true) end)
        success("gText_MysteryEventSpecialRibbon")
      elseif op == 9 then require("src.core.game3.dex").enableNational(session); success("gText_MysteryEventNationalDex")
      elseif op == 10 then require("src.core.game3.rse.old_man").unlockTrendySaying(byte(), session); success("gText_MysteryEventRareWord")
      elseif op == 11 then
        local unk, quantity, item = byte(), byte(), half()
        local old = session.recordMixingGift or {}
        local g = {unk0 = unk, quantity = quantity, itemId = item, filler4 = {}, checksum = 0}
        if unk == 0 or quantity == 0 or item == 0 then g.unk0, g.quantity, g.itemId = 0, 0, 0 end
        for i = 1, 8 do g.filler4[i] = g.unk0 ~= 0 and ((old.filler4 or {})[i] or 0) or 0 end
        g.checksum = g.unk0 + g.quantity + g.itemId % 256 + math.floor(g.itemId / 256)
        for _, b in ipairs(g.filler4) do g.checksum = g.checksum + b end
        session.recordMixingGift = g
      elseif op == 12 then
        local at = pointer()
        local cart = codec.decodePartyMon(rawString(slice(at, 100)))
        local mon = codec.toPortMon(cart, true)
        require("src.core.game3.save_mon").normalize(mon)
        result.stringVars[1] = IR.toPlain(Text.ir(mon.isEgg and "gText_EggNickname" or "gText_Pokemon"))
        session.party = session.party or {}
        if #session.party >= 6 then result.status = M.FAILURE; message("gText_MysteryEventFullParty")
        else
          if not mon.isEgg then
            session.dex = session.dex or {}
            require("src.core.game3.dex").setCaught(session.dex, mon.species)
          end
          local B = require("src.core.game3.link.rs_record_cross_bytes")
          local rawMail = rawString(slice(at + 100, 36))
          local record = B.read(codec, rawMail, B.MAIL)
          record.playerName = record.playerName:gsub(" +$", "")
          record.trainerId = record.trainerIdRaw % 65536; record._rsNativeBytes = {rawMail:byte(1, 36)}
          if require("src.core.game3.mail").isMailItem(mon.item or mon.heldItem) then
            require("src.core.game3.mail").giveMailToMon2(session, mon, record)
          end
          session.party[#session.party + 1] = mon
          success("gText_MysteryEventSentOver")
        end
      elseif op == 13 then
        local at = pointer()
        local record = require("src.save_convert.gen3_port.rs").readTowerRecord(rawString(slice(at, 188)), codec, true)
        if not record.checksumValid then record = {nativeCleared = true} end
        session.battleTower = session.battleTower or {}; session.battleTower.ereaderTrainer = record
        success("gText_MysteryEventNewTrainer")
      elseif op == 14 then
        Flags.setVar(session, nil, C:require("vars", "VAR_RESET_RTC_ENABLE"), 0x920)
        Flags.setFlag(session, nil, C:require("flags", "FLAG_SYS_RESET_RTC_ENABLE"), true)
        success("gText_InGameClockUsable")
      elseif op == 15 or op == 16 then
        local expected, first, last = word(), pointer(), pointer()
        local data, actual = slice(first, last - first), 0
        if op == 16 then actual = crc(data) else for _, b in ipairs(data) do actual = actual + b end end
        if actual ~= expected then result.valid, result.status = false, M.LOAD_ERROR end
        yields = true
      else error("unknown Mystery Event opcode " .. op) end
      if yields and not result.valid then stopped = true end
    end
  end
  local ok, why = pcall(execute)
  if not ok then result.status, result.error = M.LOAD_ERROR, tostring(why) end
  result.save = result.status == M.LOAD_OK or result.status == M.SUCCESS
  if result.status == M.LOAD_OK then message("gSystemText_EventLoadSuccess")
  elseif result.status == M.LOAD_ERROR then message("gSystemText_LoadingError") end
  result.message = result.message or {}
  return result
end
return M
