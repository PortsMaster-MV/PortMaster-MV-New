local Rse = require("src.core.game3.rse.init")
local U = require("src.core.game3.rs.contest_util")
local N = {BY_NAME = {}}
local B = N.BY_NAME
local function NC() return require("src.core.game3.scripting.natives_contest") end
local function variable(ctx, id) return Rse.specialVar(ctx, id) end
local function put(ctx, id, value) Rse.setSpecialVar(ctx, id, value) end
local function text(ctx, index, value)
  ctx.stringVars = ctx.stringVars or {}; ctx.stringVars[index] = value
end
local function alias(name)
  return function(ctx, adapters) return assert(NC().BY_NAME[name], name)(ctx, adapters) end
end
-- pokeruby/data/specials.inc:87
for native, shared in pairs({
  ScrSpecial_GetContestWinnerIdx = "GetContestWinnerId",
  ScrSpecial_GetContestPlayerMonIdx = "GetContestPlayerId",
  ScrSpecial_GetContestWinnerNick = "BufferContestWinnerMonName",
  ScrSpecial_CountContestMonsWithBetterCondition = "GetContestMonConditionRanking",
  ScrSpecial_CheckSelectedMonAndInitContest = "TryEnterContestMon",
  ScrSpecial_GetMonCondition = "GetContestMonCondition",
  ScrSpecial_CanMonParticipateInSelectedLinkContest = "HasMonWonThisContestBefore",
  ScrSpecial_GiveContestRibbon = "GiveMonContestRibbon",
}) do B[native] = alias(shared) end

-- contest_link_util.c:2682
B.ScrSpecial_GetContestWinnerTrainerName = function(ctx)
  local c = U.current()
  if c then text(ctx, 3, U.trainerNameAt(c, U.winnerId(c))) end
  return false
end
B.BufferContestTrainerAndMonNames = function(ctx)
  local c, index = U.current(), variable(ctx, 0x8006)
  if c and c.mons[index] then
    text(ctx, 1, U.trainerNameAt(c, index)); text(ctx, 3, U.monName(c.mons[index]))
    put(ctx, 0x8004, tonumber(c.mons[index].species) or 0)
  end
  return false
end
B.GetContestantNamesAtRank = function(ctx)
  local c = U.current()
  if c then
    local who, adjusted = U.contestantAtConditionRank(c, variable(ctx, 0x8006))
    text(ctx, 1, U.monName(c.mons[who])); text(ctx, 2, U.trainerNameAt(c, who))
    put(ctx, 0x8006, adjusted)
  end
  return false
end
-- contest_util.c:243
B.ScrSpecial_SetLinkContestTrainerGfxIdx = function()
  local c = U.current()
  if c then
    for i = 0, 3 do Rse.setVar("VAR_OBJ_GFX_ID_" .. i, c.mons[i].trainerGfxId or 0, Rse.session()) end
  end
  return false
end
B.sub_80C5044 = function() return false, 0 end
B.ShowContestWinner = function(ctx, adapters)
  local nc = NC()
  local winnerId = nc.curIsForArtist and 0 or (nc.curSaveIdx and nc.curSaveIdx + 1 or 0)
  return nc.showContestPainting({ctx = ctx, adapters = adapters}, winnerId)
end
return N
