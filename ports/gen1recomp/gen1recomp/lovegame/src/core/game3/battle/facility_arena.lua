local State = require("src.core.game3.battle.state")
local Moves = require("src.core.game3.battle.moves")
local Data = require("src.core.game3.rse.frontier.f2_data")

local Fac = {}
Fac.__index = Fac

-- pokeemerald/include/constants/battle_arena.h:16
Fac.CATEGORY = { MIND = 0, SKILL = 1, BODY = 2 }
-- pokeemerald/include/constants/battle_arena.h:20
Fac.RESULT = { RUNNING = 0, STEP_DONE = 1, PLAYER_WON = 2, PLAYER_LOST = 3, TIE = 4 }
-- pokeemerald/include/constants/battle_string_ids.h:592
Fac.REF = { NOTHING_IS_DECIDED = 0, THATS_IT = 1, JUDGE_MIND = 2, JUDGE_SKILL = 3, JUDGE_BODY = 4,
  PLAYER_WON = 5, OPPONENT_WON = 6, DRAW = 7, COMMENCE_BATTLE = 8 }
-- pokeemerald/src/battle_arena.c:45
Fac.ANIM = { X = 0, TRIANGLE = 1, CIRCLE = 2, LINE = 3 }
-- pokeemerald/include/battle.h:465
Fac.WIN = { PLAYER_NAME = 15, VS = 16, OPPONENT_NAME = 17, MIND = 18, SKILL = 19, BODY = 20,
  JUDGMENT_TITLE = 21, JUDGMENT_TEXT = 22 }
-- pokeemerald/include/constants/battle.h:324
local B_WAIT_TIME_LONG = 64

-- pokeemerald/src/battle_arena.c:562
local DEDUCT = {}
for _, n in ipairs({
  "PKMNSXMADEYUSELESS", "PKMNSXMADEITINEFFECTIVE", "PKMNSXPREVENTSFLINCHING", "PKMNSXBLOCKSY2",
  "PKMNSXPREVENTSYLOSS", "PKMNSXMADEYINEFFECTIVE", "PKMNSXPREVENTSBURNS", "PKMNSXBLOCKSY", "PKMNPROTECTEDBY",
  "PKMNPREVENTSUSAGE", "PKMNRESTOREDHPUSING", "PKMNPREVENTSPARALYSISWITH", "PKMNPREVENTSROMANCEWITH",
  "PKMNPREVENTSPOISONINGWITH", "PKMNPREVENTSCONFUSIONWITH", "PKMNRAISEDFIREPOWERWITH", "PKMNANCHORSITSELFWITH",
  "PKMNPREVENTSSTATLOSSWITH", "PKMNSTAYEDAWAKEUSING",
}) do DEDUCT["STRINGID_" .. n] = true end
Fac.DEDUCT = DEDUCT

-- pokeemerald/data/battle_scripts_1.s:300
local ALREADY = {}
for _, n in ipairs({ "PKMNALREADYASLEEP", "PKMNALREADYPOISONED", "PKMNALREADYASLEEP2", "PKMNALREADYCONFUSED",
  "PKMNISALREADYPARALYZED", "PKMNHASSUBSTITUTE", "PKMNALREADYHASBURN" }) do
  ALREADY["STRINGID_" .. n] = true
end
Fac.ALREADY = ALREADY

-- pokeemerald/include/battle.h:629
local NO_EFFECT = {}
for _, n in ipairs({ "STRINGID_ATTACKMISSED", "sText_AttackMissed", "STRINGID_PKMNAVOIDEDATTACK",
  "sText_PkmnAvoidedAttack", "STRINGID_ITDOESNTAFFECT", "sText_ItDoesntAffect", "STRINGID_PKMNUNAFFECTED",
  "sText_PkmnUnaffected", "STRINGID_BUTITFAILED", "sText_ButItFailed", "STRINGID_PKMNPROTECTEDITSELF",
  "sText_PkmnProtectedItself", "STRINGID_PKMNSXMADEITINEFFECTIVE", "STRINGID_PKMNSXMADEYUSELESS",
  "STRINGID_PKMNAVOIDEDATTACK" }) do NO_EFFECT[n] = true end
local PROTECTED = { STRINGID_PKMNPROTECTEDITSELF = true, sText_PkmnProtectedItself = true }
local SUPER = { STRINGID_SUPEREFFECTIVE = true, sText_SuperEffective = true }
local NOT_VERY = { STRINGID_NOTVERYEFFECTIVE = true, sText_NotVeryEffective = true }

local function num(mv)
  local n = tonumber(mv)
  if n then return n end
  if mv == nil or mv == "" then return 0 end
  return Moves.numForName and Moves.numForName(mv) or 0
end

function Fac.new()
  local f = setmetatable({ kind = "arena", fixedOrder = true }, Fac)
  f:reset()
  return f
end

function Fac:reset()
  self.mind, self.skill, self.hpStart = { [0] = 0, 0 }, { [0] = 0, 0 }, { [0] = 0, 0 }
  self.counter = 0
  self.seen = {}
  self.steps = nil
  self.ref = nil
  self.window = nil
end

function Fac:start(st)
  self:reset()
end

local function hp(st, id)
  local b = State.battler(st, id)
  return b and b.mon and tonumber(b.mon.hp) or 0
end

-- pokeemerald/src/battle_arena.c:513
function Fac:initPoints(st)
  self.mind[0], self.mind[1] = 0, 0
  self.skill[0], self.skill[1] = 0, 0
  self.hpStart[0], self.hpStart[1] = hp(st, 0), hp(st, 1)
end

-- pokeemerald/src/battle_arena.c:527
function Fac:addMind(id, move)
  local r = Data.arena().mindRatings[num(move) + 1] or 0
  self.mind[id] = (self.mind[id] or 0) + r
end

-- pokeemerald/src/battle_arena.c:533
function Fac:addSkill(id, flags)
  if not flags.obeys then return end
  local s = self.skill[id] or 0
  if flags.alreadyStatused then
    s = s - 2
  elseif flags.noEffect then
    if not flags.protectedMiss then s = s - 2 end
  elseif flags.super and flags.notVery then
    s = s + 1
  elseif flags.super then
    s = s + 2
  elseif flags.notVery then
    s = s - 1
  elseif not flags.userProtected then
    s = s + 1
  end
  self.skill[id] = s
end

-- pokeemerald/src/battle_arena.c:562
function Fac:deductSkill(id, stringId)
  if DEDUCT[stringId] then self.skill[id] = (self.skill[id] or 0) - 3 end
end

function Fac.moveFlags(events, id)
  local AnimSeq = require("src.core.game3.battle.anim_seq")
  local f = { obeys = false }
  for _, e in ipairs(events or {}) do
    if e.kind == "move" and (tonumber(e.attackerId) == id or (e.attackerId == nil and e.attacker == State.sideOf(id))) then
      f.obeys = true
    elseif e.kind == "msg" and e.id then
      if AnimSeq.isMoveUsedId(e.id) then f.obeys = true end
      if ALREADY[e.id] then f.alreadyStatused = true end
      if NO_EFFECT[e.id] then f.noEffect = true end
      if PROTECTED[e.id] then f.protectedMiss = true end
      if SUPER[e.id] then f.super = true end
      if NOT_VERY[e.id] then f.notVery = true end
    end
  end
  return f
end

local function actorId(act)
  if tonumber(act.battler) then return tonumber(act.battler) end
  local u = act.user
  if u == "enemy" or (type(u) == "table" and u.side == "enemy") then return 1 end
  return 0
end

-- pokeemerald/src/battle_util.c:288
function Fac:resolveMove(st, ad, act, out, userRef, targetRef)
  local Engine = require("src.core.game3.battle.engine")
  local id = actorId(act)
  local user = State.battler(st, id)
  self:addMind(id, user and user.expLockedMove or act.move)
  local r = Engine.resolveMove(userRef, targetRef, act.move, act.slot, ad, st, out)
  local events = (r and r.events) or (out and out.events) or {}
  local flags = Fac.moveFlags(events, id)
  flags.userProtected = user and user.expProtected and true or false
  self:addSkill(id, flags)
  for _, e in ipairs(events) do
    if e.kind == "msg" and e.id then self:deductSkill(id, e.id) end
  end
  return r
end

local function syncSwitchIns(self, st)
  local changed, initial = false, false
  for id = 0, 1 do
    local b = State.battler(st, id)
    local mon = b and b.mon
    if self.seen[id] ~= mon then
      if self.seen[id] == nil then initial = true else changed = true end
      self.seen[id] = mon
    end
  end
  return changed, initial
end

-- pokeemerald/src/battle_arena.c:470
function Fac:score(st, category)
  local sc = { [0] = 0, 0 }
  local icons = {}
  for side = 0, 1 do
    local me, them = side, 1 - side
    local p, o
    if category == Fac.CATEGORY.MIND then
      p, o = self.mind[me] or 0, self.mind[them] or 0
    elseif category == Fac.CATEGORY.SKILL then
      p, o = self.skill[me] or 0, self.skill[them] or 0
    else
      p = math.floor(hp(st, me) * 100 / math.max(1, self.hpStart[me] or 1))
      o = math.floor(hp(st, them) * 100 / math.max(1, self.hpStart[them] or 1))
    end
    if p > o then
      icons[side] = Fac.ANIM.CIRCLE
      sc[side] = 2
    elseif p == o then
      icons[side] = Fac.ANIM.TRIANGLE
      sc[side] = 1
    else
      icons[side] = Fac.ANIM.X
      sc[side] = 0
    end
  end
  return sc, icons
end

-- pokeemerald/src/battle_arena.c:436
function Fac:judge(st)
  local total = { [0] = 0, 0 }
  local rows = {}
  for c = 0, 2 do
    local sc, icons = self:score(st, c)
    total[0], total[1] = total[0] + sc[0], total[1] + sc[1]
    rows[c] = { icons = icons, total = { [0] = total[0], total[1] } }
  end
  local result
  if total[0] > total[1] then result = Fac.RESULT.PLAYER_WON
  elseif total[0] < total[1] then result = Fac.RESULT.PLAYER_LOST
  else result = Fac.RESULT.TIE end
  return result, rows, total
end

local function fill(st, extra)
  local Adapter = require("src.core.game3.battle.adapter")
  extra = extra or {}
  extra.playerMon1 = extra.playerMon1 or State.battler(st, 0)
  extra.opponentMon1 = extra.opponentMon1 or State.battler(st, 1)
  return Adapter.fill(st, extra)
end

function Fac:refText(st, which, extra)
  local RomText = require("src.core.game3.rom_text")
  local ir = RomText.irOr(RomText.key("gRefereeStringsTable", which), Data.arena().refereeStrings[which + 1])
  return Data.battleText(ir, fill(st, extra))
end

local function se(name)
  local ok, Audio = pcall(require, "src.core.game3.audio")
  local okS, SE = pcall(require, "src.core.game3.se_ids")
  if ok and okS and SE[name] then pcall(Audio.playSe, SE[name]) end
end

local function pushSteps(list, ...)
  for i = 1, select("#", ...) do list[#list + 1] = select(i, ...) end
end

-- pokeemerald/data/battle_scripts_1.s:4448
function Fac:commenceSteps()
  local s = {}
  pushSteps(s, { k = "se", name = "SE_ARENA_TIMEUP1" }, { k = "pause", n = 8 }, { k = "se", name = "SE_ARENA_TIMEUP1" },
    { k = "refbox", on = true }, { k = "ref", id = Fac.REF.COMMENCE_BATTLE }, { k = "pause", n = B_WAIT_TIME_LONG },
    { k = "refbox", on = false })
  return s
end

-- pokeemerald/src/battle_main.c:4015
function Fac:turnStart(st, ad, headless)
  local changed, initial = syncSwitchIns(self, st)
  if initial and not changed then self:initPoints(st) end
  if changed then
    -- pokeemerald/src/battle_main.c:3258
    self.counter = 0xFF
    self:initPoints(st)
  end
  if (tonumber(st.turn) or 0) > 0 then self.counter = (self.counter + 1) % 256 end
  if self.counter ~= 0 then return false end
  if headless then return false end
  self.steps, self.stepI, self.wait = self:commenceSteps(), 1, 0
  return true
end

function Fac:applyJudgment(st, result)
  local lost = {}
  if result == Fac.RESULT.PLAYER_WON then lost = { 1 }
  elseif result == Fac.RESULT.PLAYER_LOST then lost = { 0 }
  else lost = { 0, 1 } end
  for _, id in ipairs(lost) do
    local b = State.battler(st, id)
    if b and b.mon then
      b.mon.hp = 0
      -- pokeemerald/src/battle_script_commands.c:3069
      b.mon.status = nil
      b.status = nil
      if b.side == "player" then
        State.syncBattlerToParty(b, st.playerParty)
      else
        State.syncBattlerToParty(b, st.foeParty)
      end
    end
  end
  return lost
end

local function resultStringId(result)
  if result == Fac.RESULT.PLAYER_WON then return "STRINGID_DEFEATEDOPPONENTBYREFEREE" end
  if result == Fac.RESULT.PLAYER_LOST then return "STRINGID_LOSTTOOPPONENTBYREFEREE" end
  return "STRINGID_TIEDOPPONENTBYREFEREE"
end

-- pokeemerald/src/battle_util.c:1856
function Fac:endTurn(st, ad, headless)
  if self.counter ~= 2 or hp(st, 0) == 0 or hp(st, 1) == 0 then return false end
  if self.judgedTurn == st.turn then return false end
  self.judgedTurn = st.turn
  for id = 0, 1 do
    local b = State.battler(st, id)
    if b then require("src.core.game3.battle.engine").cancelMultiTurnMoves(b) end
  end
  local result, rows, total = self:judge(st)
  self.lastJudgment = { result = result, rows = rows, total = total }
  local BattleText = require("src.core.game3.battle.battle_text")
  if headless then
    local Ui = require("src.core.game3.battle.ui")
    Ui.push(BattleText.get(resultStringId(result), fill(st)))
    self:applyJudgment(st, result)
    return false
  end
  local refFor = { [Fac.RESULT.PLAYER_WON] = Fac.REF.PLAYER_WON, [Fac.RESULT.PLAYER_LOST] = Fac.REF.OPPONENT_WON,
    [Fac.RESULT.TIE] = Fac.REF.DRAW }
  local s = {}
  pushSteps(s,
    { k = "se", name = "SE_ARENA_TIMEUP1" }, { k = "pause", n = 8 }, { k = "se", name = "SE_ARENA_TIMEUP1" },
    { k = "pause", n = B_WAIT_TIME_LONG },
    { k = "refbox", on = true }, { k = "ref", id = Fac.REF.THATS_IT }, { k = "pause", n = B_WAIT_TIME_LONG },
    { k = "judge", state = "open" }, { k = "pause", n = B_WAIT_TIME_LONG },
    { k = "judge", state = "row", row = 0 }, { k = "ref", id = Fac.REF.JUDGE_MIND },
    { k = "judge", state = "row", row = 1 }, { k = "ref", id = Fac.REF.JUDGE_SKILL },
    { k = "judge", state = "row", row = 2 }, { k = "ref", id = Fac.REF.JUDGE_BODY },
    { k = "judge", state = "result" }, { k = "ref", id = refFor[result] },
    { k = "judge", state = "close" }, { k = "refbox", on = false },
    { k = "msg", text = BattleText.get(resultStringId(result), fill(st)) },
    { k = "faint", result = result })
  self.steps, self.stepI, self.wait = s, 1, 0
  return true
end

-- pokeemerald/src/text.c:258
local function textDelay(st)
  local Kit = require("src.ui.game3.rse.scene_kit")
  local s = st and st.session
  local ok, v = pcall(Kit.textSpeedDelay, s and s.options and s.options.textSpeed)
  return ok and tonumber(v) or 4
end

function Fac:runStep(st, step)
  local k = step.k
  if k == "se" then
    se(step.name)
    return true
  elseif k == "pause" then
    self.wait = step.n
    return true
  elseif k == "refbox" then
    self.refbox = step.on
    if step.on then
      -- pokeemerald/src/battle_arena.c:771
      require("src.core.game3.battle.ui").clearLinger()
    else
      self.ref = nil
    end
    return true
  elseif k == "ref" then
    local text = self:refText(st, step.id, self.window and self.window.buffs or nil)
    self.ref = { text = text, shown = 0, len = #text, delay = textDelay(st), timer = 0 }
    return false
  elseif k == "msg" then
    require("src.core.game3.battle.ui").push(step.text)
    self.msgWait = true
    return false
  elseif k == "judge" then
    return self:judgeStep(st, step)
  elseif k == "faint" then
    return self:faintStep(st, step)
  end
  return true
end

-- pokeemerald/src/battle_arena.c:412
local JUDGMENT_TEXTS = {
  { Fac.WIN.PLAYER_NAME, "gText_PlayerMon1Name", "playerMon1Name" },
  { Fac.WIN.VS, "gText_Vs", "vs" },
  { Fac.WIN.OPPONENT_NAME, "gText_OpponentMon1Name", "opponentMon1Name" },
  { Fac.WIN.MIND, "gText_Mind", "mind" },
  { Fac.WIN.SKILL, "gText_Skill", "skill" },
  { Fac.WIN.BODY, "gText_Body", "body" },
  { Fac.WIN.JUDGMENT_TITLE, "gText_Judgment", "judgment" },
}

local function judgmentTexts()
  local RomText = require("src.core.game3.rom_text")
  local text, out = Data.arena().text, {}
  for i, row in ipairs(JUDGMENT_TEXTS) do
    out[i] = { win = row[1], ir = RomText.irOr(row[2], text[row[3]]) }
  end
  return out
end

-- pokeemerald/src/battle_arena.c:395
function Fac:judgeStep(st, step)
  local j = self.window
  if step.state == "open" then
    self.window = { fade = 0, target = 8, icons = {}, line = true, buffs = { buff1 = "0", buff2 = "0" },
      texts = judgmentTexts() }
    self.fadeWait = true
    return false
  elseif step.state == "row" then
    local row = self.lastJudgment.rows[step.row]
    se("SE_ARENA_TIMEUP1")
    local ys = { [0] = 40, 56, 72 }
    j.icons[#j.icons + 1] = { x = 80, y = ys[step.row], anim = row.icons[0] }
    j.icons[#j.icons + 1] = { x = 160, y = ys[step.row], anim = row.icons[1] }
    j.buffs = { buff1 = tostring(row.total[0]), buff2 = tostring(row.total[1]) }
    return true
  elseif step.state == "result" then
    se("SE_ARENA_TIMEUP2")
    return true
  elseif step.state == "close" then
    j.icons, j.line, j.closing = {}, false, true
    j.target = 0
    self.fadeWait = true
    return false
  end
  return true
end

function Fac:faintStep(st, step)
  local Anim = require("src.core.game3.battle.anim")
  local lost = self:applyJudgment(st, step.result)
  self.fainting = #lost
  for _, id in ipairs(lost) do
    local b = State.battler(st, id)
    local sp = b and b.mon and (b.mon.species or b.mon.speciesId)
    pcall(function()
      require("src.core.game3.audio").playCry(sp, 5, (id % 2 == 0) and -25 or 25)
    end)
    Anim.faintMon(id, { onComplete = function() self.fainting = self.fainting - 1 end })
  end
  return false
end

function Fac:update(st)
  local Ui = require("src.core.game3.battle.ui")
  local Anim = require("src.core.game3.battle.anim")
  if not self.steps then return true end
  for _ = 1, 64 do
    if (self.wait or 0) > 0 then
      self.wait = self.wait - 1
      return false
    end
    if self.ref and self.ref.shown < self.ref.len then
      self.ref.timer = self.ref.timer + 1
      if self.ref.timer >= self.ref.delay then
        self.ref.timer = 0
        self.ref.shown = self.ref.delay <= 0 and self.ref.len or (self.ref.shown + 1)
      end
      return false
    end
    if self.msgWait then
      if not Ui.pump() then return false end
      if Ui.dialogPending and Ui.dialogPending() then return false end
      self.msgWait = nil
    end
    if self.fadeWait then
      local j = self.window
      if j.fade < j.target then j.fade = j.fade + 0.25 elseif j.fade > j.target then j.fade = j.fade - 0.25 end
      if j.fade ~= j.target then return false end
      self.fadeWait = nil
      if j.closing then self.window = nil end
    end
    if (self.fainting or 0) > 0 then
      if Anim.busy() then return false end
      return false
    end
    local step = self.steps[self.stepI]
    if not step then
      self.steps = nil
      return true
    end
    self.stepI = self.stepI + 1
    self:runStep(st, step)
  end
  return false
end

local function wincolors(info)
  local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
  local pal = Data.dome().palettes.windowText
  return { fg = Gfx.color(pal[info.fg + 1]), shadow = Gfx.color(pal[info.shadow + 1]), bg = { 0, 0, 0, 0 } },
    Gfx.color(pal[info.bg + 1])
end

-- pokeemerald/src/text.c:753
local function fontText(ir, fl)
  local parts = {}
  for _, seg in ipairs(ir or {}) do
    if seg.t == "ext" then
      local args = seg.args or {}
      local bytes = { 0xFC, tonumber(seg.cmd) or 0 }
      for _, a in ipairs(args) do bytes[#bytes + 1] = tonumber(a) or 0 end
      parts[#parts + 1] = string.char(unpack(bytes))
    elseif seg.t ~= "eos" then
      parts[#parts + 1] = Data.battleText({ seg, { t = "eos" } }, fl)
    end
  end
  return table.concat(parts)
end

local function windowText(win, info, text)
  local FrlgFont = require("src.ui.game3.frlg_font")
  local colors, bg = wincolors(info)
  love.graphics.setColor(bg)
  love.graphics.rectangle("fill", win.left * 8, win.top * 8, win.w * 8, win.h * 8)
  love.graphics.setColor(1, 1, 1, 1)
  local x = info.x
  if x < 0 then x = math.floor((win.w * 8 - FrlgFont.measure(text)) / 2) end
  FrlgFont.draw(text, win.left * 8 + x, win.top * 8 + info.y, { colors = colors })
end

function Fac:iconImage(anim)
  self.iconCache = self.iconCache or {}
  local hit = self.iconCache[anim]
  if hit then return hit end
  local Gfx = require("src.ui.game3.rse.pokeblock_gfx")
  local pal = Data.arena().judgmentPal
  hit = Gfx.of("rse/frontier_f2"):sprite("judgment", anim * 4, 16, 16, pal)
  self.iconCache[anim] = hit
  return hit
end

-- pokeemerald/src/battle_arena.c:393
function Fac:draw(st)
  if not (love and love.graphics) then return end
  local A = Data.arena()
  local j = self.window
  if j then
    love.graphics.setColor(0, 0, 0, (j.fade or 0) / 16)
    love.graphics.rectangle("fill", 0, 0, 240, 112)
    love.graphics.setColor(1, 1, 1, 1)
    if not j.closing and j.fade >= j.target then
      local Chrome = require("src.ui.game3.chrome")
      -- pokeemerald/src/battle_script_commands.c:10152
      Chrome.userFrame(Chrome._frameType or 0, 6, 1, 18, 12)
      local W, I = A.windows, A.textInfo
      local fl = fill(st, j.buffs)
      for _, t in ipairs(j.texts) do
        windowText(W[t.win + 1], I[t.win + 1], fontText(t.ir, fl))
      end
      if j.line then
        local img = self:iconImage(Fac.ANIM.LINE)
        for i = 0, 7 do love.graphics.draw(img, 64 + i * 16 - 8, 84 - 8) end
      end
      for _, ic in ipairs(j.icons) do
        love.graphics.draw(self:iconImage(ic.anim), ic.x - 8, ic.y - 8)
      end
    end
  end
  if self.refbox then
    local Chrome = require("src.ui.game3.chrome")
    local FrlgFont = require("src.ui.game3.frlg_font")
    local Kit = require("src.ui.game3.rse.scene_kit")
    Chrome.dialogueFrame()
    if self.ref then
      local win, info = A.windows[Fac.WIN.JUDGMENT_TEXT + 1], A.textInfo[Fac.WIN.JUDGMENT_TEXT + 1]
      local text = self.ref.text:sub(1, self.ref.shown)
      FrlgFont.draw(text, win.left * 8 + info.x, win.top * 8 + info.y,
        { colors = Kit.messageColors("message_box", info.fg, info.bg, info.shadow) })
    end
  end
end

-- pokeemerald/src/battle_main.c:4243
function Fac:canSwitch(st, ad, battler)
  local name = State.displayName(battler)
  local RomText = require("src.core.game3.rom_text")
  local ok, txt = pcall(RomText.ascii, "gText_PkmnCantSwitchOut", { stringVars = { name } })
  return false, ok and txt or nil
end

-- pokeemerald/src/battle_main.c:4185
function Fac:actions(st, playerAct, enemyAct)
  if enemyAct and (enemyAct.kind == "switch" or enemyAct.kind == "item") then
    -- pokeemerald/src/battle_ai_switch_items.c:452
    local Ai = require("src.core.game3.battle.ai")
    enemyAct = Ai.chooseMove(st) or enemyAct
  end
  return playerAct, enemyAct
end

local installed = false
function Fac.install()
  if installed then return end
  installed = true
  local Engine = require("src.core.game3.battle.engine")
  local orig = Engine.canSwitch
  Engine.canSwitch = function(st, adapter, battler, ...)
    local fac = st and st.facility
    if fac and fac.canSwitch then return fac:canSwitch(st, adapter, battler or st.player) end
    return orig(st, adapter, battler, ...)
  end
end
Fac.install()

return Fac
