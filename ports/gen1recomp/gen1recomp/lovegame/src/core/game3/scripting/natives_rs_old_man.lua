-- pokeruby/data/specials.inc:97
local R = require("src.core.game3.rse.init")
local Town = require("src.core.game3.rse.town_common")
local OldMan = require("src.core.game3.rse.old_man")
local Text = require("src.core.game3.rom_text")
local N = {BY_NAME = {}}
local B = N.BY_NAME

N.TEXT_ALIASES = {GiddyText_Is = "gOtherText_Is", GiddyText_DontYouAgree = "gOtherText_DontYouAgree",
  gText_FiveMarks = "gOtherText_FiveQuestions"}

local function delegate(name)
  return function(...) return require("src.core.game3.scripting.natives_old_man").BY_NAME[name](...) end
end
local names = {
  ScrSpecial_GetCurrentMauvilleMan = "Script_GetCurrentMauvilleMan",
  ScrSpecial_HasBardSongBeenChanged = "HasBardSongBeenChanged",
  ScrSpecial_SaveBardSongLyrics = "SaveBardSongLyrics",
  ScrSpecial_GetHipsterSpokenFlag = "HasHipsterTaughtWord",
  ScrSpecial_SetHipsterSpokenFlag = "SetHipsterTaughtWord",
  ScrSpecial_HipsterTeachWord = "HipsterTryTeachWord",
  ScrSpecial_PlayBardSong = "PlayBardSong",
  ScrSpecial_GenerateGiddyLine = "GenerateGiddyLine",
  ScrSpecial_GiddyShouldTellAnotherTale = "GiddyShouldTellAnotherTale",
  ScrSpecial_StorytellerGetFreeStorySlot = "StorytellerGetFreeStorySlot",
  ScrSpecial_StorytellerDisplayStory = "Script_StorytellerDisplayStory",
  ScrSpecial_StorytellerUpdateStat = "StorytellerUpdateStat",
  ScrSpecial_StorytellerInitializeRandomStat = "Script_StorytellerInitializeRandomStat",
  ScrSpecial_HasStorytellerAlreadyRecorded = "HasStorytellerAlreadyRecorded",
  ScrSpecial_GetTraderTradedFlag = "GetTraderTradedFlag",
  ScrSpecial_DoesPlayerHaveNoDecorations = "DoesPlayerHaveNoDecorations",
  ScrSpecial_IsDecorationFull = "IsDecorationCategoryFull",
  ScrSpecial_TraderMenuGiveDecoration = "TraderShowDecorationMenu",
  ScrSpecial_TraderDoDecorationTrade = "TraderDoDecorationTrade",
}
for native, shared in pairs(names) do B[native] = delegate(shared) end

B.SetMauvilleOldManObjEventGfx = function()
  -- mauville_man.c:807
  local s = R.session()
  local c = require("src.core.game3.constants").active(s)
  R.setVar("VAR_OBJ_GFX_ID_0", c:require("event_objects", "OBJ_EVENT_GFX_BARD") + OldMan.current(s), s)
  return false
end

local function choose(ctx, adapters, labels, layout, picked)
  return require("src.core.game3.scripting.natives").yieldHost(ctx, adapters, function(done)
    require("src.ui.game3.choice").multi(labels, 0, function(sel) picked(sel); done() end, layout)
  end)
end
B.ScrSpecial_StorytellerStoryListMenu = function(ctx, adapters)
  -- mauville_man.c:1060
  local labels = OldMan.storyTitles()
  local count = #labels
  labels[#labels + 1] = Text.plain("gPCText_Cancel")
  return choose(ctx, adapters, labels, {left = 1, top = 2}, function(sel)
    local canceled = sel == 127 or sel == count
    R.setSpecialVar(ctx, 0x800D, canceled and 0 or 1)
    if not canceled then OldMan.selectedStory = sel end
  end)
end
B.ScrSpecial_TraderMenuGetDecoration = function(ctx, adapters)
  -- trader.c:85
  local t, labels = OldMan.state(), {}
  local Inv = require("src.core.game3.rse.decoration_inventory")
  for i = 1, 4 do
    local d = t.decorations[i] or 0
    if d ~= 0 then
      labels[#labels + 1] = d > 120 and Text.plain("gOtherText_FiveQuestions") or Inv.info(d).name
    end
  end
  local count = #labels
  labels[count + 1] = Text.plain("gOtherText_CancelNoTerminator")
  return choose(ctx, adapters, labels, {left = 1, top = 2}, function(sel)
    if sel ~= 127 then R.setSpecialVar(ctx, 0x8005, sel) end
    if sel == 127 or sel == count then R.setSpecialVar(ctx, 0x8004, 0); return end
    Town.setString(ctx, adapters, 1, t.playerNames[sel + 1])
    local decor = t.decorations[sel + 1] or 0
    R.setSpecialVar(ctx, 0x8004, decor > 120 and 0xFFFF or decor)
  end)
end
return N
