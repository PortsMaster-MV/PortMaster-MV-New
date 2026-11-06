local Profile = require("src.core.game3.profile")
local RomText = require("src.core.game3.rom_text")
local Pokemon = require("src.core.game3.pokemon")
local M = {}
function M.matches(session)
  local id = Profile.forSession(session).id
  return id == "ruby" or id == "sapphire"
end
-- pokeruby/src/pokemon_storage_system.c:28
function M.options()
  local out = {}
  for _, r in ipairs({{"withdraw", "WithdrawPoke", "MovePokeToParty"}, {"deposit", "DepositPoke", "StorePokeInBox"},
    {"move", "MovePoke", "OrganizeBoxesParty"}, {"quit", "SeeYa", "ReturnToPrevMenu"}}) do
    out[#out + 1] = {id = r[1], label = RomText.plain("PCText_" .. r[2]), desc = RomText.plain("PCText_" .. r[3])}
  end
  return out
end
local labels = {CANCEL = "Cancel2", STORE = "Deposit", DEPOSIT = "Deposit", WITHDRAW = "Withdraw", MOVE = "Move",
  SWITCH = "Switch", PLACE = "Place", SUMMARY = "Summary", RELEASE = "Release", MARK = "Mark",
  ["SWITCH BOX"] = "Jump", WALLPAPER = "Wallpaper", NAME = "Name"}
function M.menuText(action) return RomText.plain("PCText_" .. assert(labels[action], action)) end
local wallpapers = {"Forest", "City", "Desert", "Savanna", "Crag", "Volcano", "Snow", "Cave", "Beach", "Seafloor", "River", "Sky", "Polka", "PokeCenter", "Machine", "Plain"}
function M.wallpaperName(id) return RomText.plain("PCText_" .. assert(wallpapers[id], "native RS wallpaper")) end
function M.text(name, mon)
  local text = RomText.plain("PCText_" .. name)
  local nick = mon and Pokemon.displayMonName(mon) or ""
  if name == "WasReleased" or name == "CameBack" or name == "IsSelected" then return nick .. text end
  if name == "ByeBye" then return text:sub(1, -2) .. nick .. text:sub(-1) end
  return text
end
-- pokeruby/src/pokemon_storage_system_4.c:2263
function M.actions(mode, loc, holding, occupied)
  if occupied == false and not holding then return nil end
  local out = {mode == "deposit" and "STORE" or mode == "withdraw" and "WITHDRAW" or holding and (occupied and "SWITCH" or "PLACE") or "MOVE", "SUMMARY"}
  if mode == "move" then out[#out + 1] = loc == "box" and "WITHDRAW" or "STORE" end
  out[#out + 1], out[#out + 2], out[#out + 3] = "MARK", "RELEASE", "CANCEL"
  return out
end
function M.boxActions() return {"SWITCH BOX", "WALLPAPER", "NAME", "CANCEL"} end
local function alive(mon)
  return type(mon) == "table" and (tonumber(Pokemon.speciesOf(mon)) or 0) ~= 0 and not Pokemon.isEgg(mon) and (tonumber(mon.hp) or 0) > 0
end
-- pokeruby/src/pokemon_storage_system.c:120
function M.canRemoveParty(session, index)
  for i, mon in pairs(session.party or {}) do if i ~= index and alive(mon) then return true end end
  return false
end
function M.canReplaceParty(session, index, incoming) return M.canRemoveParty(session, index) or alive(incoming) end
function M.aliveCount(session)
  local count = 0; for _, mon in pairs(session.party or {}) do if alive(mon) then count = count + 1 end end
  return count
end
function M.hasMail(mon) return require("src.core.game3.mail").isMailItem(mon and (mon.heldItem or mon.item)) end
function M.depositError(session, index)
  if not M.canRemoveParty(session, index) then return "LastPoke" end
  if M.hasMail(session.party[index]) then return "PleaseRemoveMail" end
end
function M.releaseError(session, mon, loc, index)
  if loc == "party" and not M.canRemoveParty(session, index) then return "LastPoke" end
  if Pokemon.isEgg(mon) then return "CantReleaseEgg" end
  if M.hasMail(mon) then return "PleaseRemoveMail" end
end
-- pokeruby/src/pokemon_storage_system_4.c:1425
function M.releaseReturns(session, mon, loc, boxId, index)
  local C = require("src.core.game3.constants").of(Profile.forSession(session).id)
  local needed = {}
  for _, name in ipairs({"MOVE_SURF", "MOVE_DIVE"}) do local id = C:require("moves", name); if Pokemon.knowsMove(mon, id) then needed[id] = true end end
  local function scan(other)
    if other then for id in pairs(needed) do if Pokemon.knowsMove(other, id) then needed[id] = nil end end end
  end
  for i, other in pairs(session.party or {}) do if loc ~= "party" or i ~= index then scan(other) end end
  for b, box in pairs(session.storage and session.storage.boxes or {}) do
    for i, other in pairs(box.mons or {}) do if loc ~= "box" or b ~= boxId or i ~= index then scan(other) end end
  end
  return next(needed) ~= nil
end
return M
