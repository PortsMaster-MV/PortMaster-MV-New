local M = {}
M.SUB = "rse/trade"
local keys = {
  gText_Trade_CommunicationStandby = "TradeText_LinkStandby", gText_TradeHasBeenCanceled = "TradeText_TradeCancelled",
  gText_OnlyPkmnForBattle = "TradeText_OnlyPoke", gText_OtherTrainersPkmnCantBeTraded = "TradeText_NonTradablePoke",
  gText_WaitingForFriendToFinish = "TradeText_WaitingForFriend", gText_FriendWantsToTrade = "TradeText_WantToTrade",
  gText_4Qmark = "gOtherText_FourQuestions", gText_IsThisTradeOkay = "gTradeText_TradeOkayPrompt",
  gText_TradeAction_Summary = "TradeText_Summary2", gText_TradeAction_Trade = "TradeText_Trade2",
  gText_SavingDontTurnOffThePower2 = "gSystemText_Saving", gText_Yes = "OtherText_Yes", gText_No = "OtherText_No",
  gText_NumPlayerLink = "gOtherText_PLink",
  gText_XWillBeSentToY = "gTradeText_WillBeSent", gText_ByeByeVar1 = "gTradeText_ByeBye",
  gText_XSentOverY = "gTradeText_SentOverPoke", gText_TakeGoodCareOfX = "gTradeText_TakeGoodCare",
  gText_CommunicationStandby4 = "gOtherText_LinkStandby2",
}
function M.matches(version) return version == "ruby" or version == "sapphire" end
function M.textKey(key) return keys[key] or key end
function M.text(key, context) return require("src.core.game3.rom_text").plain(M.textKey(key), context) end
function M.activeSlots(ownCount, peerCount)
  local out = {[12] = true}
  for i = 0, 5 do out[i], out[i + 6] = i < ownCount, i < peerCount end
  return out
end
function M.nextSlot(man, current, direction, active)
  for _, slot in ipairs(assert(man.navigation[current][direction + 1])) do if active[slot] then return slot end end
  return 0
end
function M.iconCenter(man, slot)
  local p, o = man.coords.mon[slot + 1], man.geometry.iconOffset
  return p[1] * 8 + o[1], p[2] * 8 + o[2]
end
function M.cursorCenter(man, slot)
  if slot == 12 then return man.geometry.cancelCursor[1], man.geometry.cancelCursor[2], 1 end
  local p, o = man.coords.mon[slot + 1], man.geometry.cursorOffset
  return p[1] * 8 + o[1], p[2] * 8 + o[2], 0
end
function M.selectedGeometry(man, side)
  local name, moves = man.coords.selectedText[side * 2 + 1], man.coords.selectedText[side * 2 + 2]
  local a, b = man.coords.mon[side * 6 + 1], man.coords.mon[side * 6 + 2]
  return {name = {name[1] * 8, name[2] * 8}, moves = {moves[1] * 8, (moves[2] + 1) * 8},
    icon = {math.floor((a[1] + b[1]) / 2) * 8 + 14, a[2] * 8 - 12}, box = man.coords.selectedBox[side + 1]}
end
local function blit(dst, source, x, y, w, h)
  for row = 0, h - 1 do for col = 0, w - 1 do dst[(y + row) * 32 + x + col + 1] = source[row * w + col + 1] end end
end
function M.monBoxWords(man, dst, slot, level, gender, isEgg, hasGenderSymbol, selectedSide)
  local box = selectedSide ~= nil and man.coords.selectedBox[selectedSide + 1] or man.coords.box[slot + 1]
  local p = selectedSide ~= nil and {box[1] + 4, box[2] + 1} or man.coords.level[slot + 1]
  blit(dst, man.maps.mon_box.words, box[1], box[2], 6, 3)
  local at = p[1] + 32 * p[2] + 1
  if isEgg then
    dst[at - 32] = dst[at - 33]
    dst[at - 31] = require("bit").bor(dst[at - 36], 0x400)
  else
    local tens = math.floor(level / 10)
    if tens ~= 0 then dst[at] = tens + 0x60 end
    dst[at + 1] = level % 10 + 0x70
    if not hasGenderSymbol then
      if gender == 0 then dst[at - 31] = dst[at - 31] + 1
      elseif gender == 254 then dst[at - 31] = dst[at - 31] + 2 end
    end
  end
  return dst
end
function M.nicknamePadding(width, selected)
  width = width % 256
  if selected and width >= 128 then width = width - 256 end
  return math.modf(((selected and 64 or 50) - width) / 2) % 256
end
function M.cableCount(man, count)
  if count < man.cableClub.minCount then return nil end
  return {rect = man.cableClub.countRect, origin = man.cableClub.countOrigin, width = man.cableClub.countWidth,
    key = man.cableClub.countText, stringVars = {tostring(count)}}
end
return M
