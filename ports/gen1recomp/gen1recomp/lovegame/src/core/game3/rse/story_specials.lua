local Story = {}

local function labels(C, list)
  local out = {}
  for _, row in ipairs(list) do
    out[#out + 1] = {
      from = C:require("metatile_labels", "METATILE_" .. row[1]),
      to = row[2] and C:require("metatile_labels", "METATILE_" .. row[2]) or nil,
      impassable = row[3] == true,
      special = row[4],
    }
  end
  return out
end

-- pokeemerald/src/field_specials.c:611
Story.MAUVILLE_SWITCHES = { { 0, 15 }, { 4, 12 }, { 3, 9 }, { 8, 9 } }

-- pokeemerald/src/field_specials.c:633
local DEFAULT_BARRIERS = {
  { "MauvilleGym_GreenBeamH1_On", "MauvilleGym_GreenBeamH1_Off" },
  { "MauvilleGym_GreenBeamH2_On", "MauvilleGym_GreenBeamH2_Off" },
  { "MauvilleGym_GreenBeamH3_On", "MauvilleGym_GreenBeamH3_Off" },
  { "MauvilleGym_GreenBeamH4_On", "MauvilleGym_GreenBeamH4_Off" },
  { "MauvilleGym_GreenBeamH1_Off", "MauvilleGym_GreenBeamH1_On" },
  { "MauvilleGym_GreenBeamH2_Off", "MauvilleGym_GreenBeamH2_On" },
  { "MauvilleGym_GreenBeamH3_Off", "MauvilleGym_GreenBeamH3_On", true },
  { "MauvilleGym_GreenBeamH4_Off", "MauvilleGym_GreenBeamH4_On", true },
  { "MauvilleGym_RedBeamH1_On", "MauvilleGym_RedBeamH1_Off" },
  { "MauvilleGym_RedBeamH2_On", "MauvilleGym_RedBeamH2_Off" },
  { "MauvilleGym_RedBeamH3_On", "MauvilleGym_RedBeamH3_Off" },
  { "MauvilleGym_RedBeamH4_On", "MauvilleGym_RedBeamH4_Off" },
  { "MauvilleGym_RedBeamH1_Off", "MauvilleGym_RedBeamH1_On" },
  { "MauvilleGym_RedBeamH2_Off", "MauvilleGym_RedBeamH2_On" },
  { "MauvilleGym_RedBeamH3_Off", "MauvilleGym_RedBeamH3_On", true },
  { "MauvilleGym_RedBeamH4_Off", "MauvilleGym_RedBeamH4_On", true },
  { "MauvilleGym_GreenBeamV1_On", "MauvilleGym_PoleBottom_On", true },
  { "MauvilleGym_GreenBeamV2_On", "MauvilleGym_FloorTile" },
  { "MauvilleGym_RedBeamV1_On", "MauvilleGym_PoleBottom_Off", true },
  { "MauvilleGym_RedBeamV2_On", "MauvilleGym_FloorTile" },
  { "MauvilleGym_PoleBottom_On", "MauvilleGym_GreenBeamV1_On", true },
  { "MauvilleGym_FloorTile", nil, true, "floor" },
  { "MauvilleGym_PoleBottom_Off", "MauvilleGym_RedBeamV1_On", true },
  { "MauvilleGym_PoleTop_Off", "MauvilleGym_PoleTop_On", true },
  { "MauvilleGym_PoleTop_On", "MauvilleGym_PoleTop_Off" },
}

-- pokeemerald/src/field_specials.c:727
local DEACTIVATE = {
  { "MauvilleGym_GreenBeamH1_On", "MauvilleGym_GreenBeamH1_Off" },
  { "MauvilleGym_GreenBeamH2_On", "MauvilleGym_GreenBeamH2_Off" },
  { "MauvilleGym_GreenBeamH3_On", "MauvilleGym_GreenBeamH3_Off" },
  { "MauvilleGym_GreenBeamH4_On", "MauvilleGym_GreenBeamH4_Off" },
  { "MauvilleGym_RedBeamH1_On", "MauvilleGym_RedBeamH1_Off" },
  { "MauvilleGym_RedBeamH2_On", "MauvilleGym_RedBeamH2_Off" },
  { "MauvilleGym_RedBeamH3_On", "MauvilleGym_RedBeamH3_Off" },
  { "MauvilleGym_RedBeamH4_On", "MauvilleGym_RedBeamH4_Off" },
  { "MauvilleGym_GreenBeamV1_On", "MauvilleGym_PoleBottom_On", true },
  { "MauvilleGym_RedBeamV1_On", "MauvilleGym_PoleBottom_Off", true },
  { "MauvilleGym_GreenBeamV2_On", "MauvilleGym_FloorTile" },
  { "MauvilleGym_RedBeamV2_On", "MauvilleGym_FloorTile" },
  { "MauvilleGym_PoleTop_On", "MauvilleGym_PoleTop_Off" },
}

-- pokeemerald/src/field_specials.c:620
function Story.mauvillePressSwitch(which, get, set, C, switches)
  local pressed = C:require("metatile_labels", "METATILE_MauvilleGym_PressedSwitch")
  local raised = C:require("metatile_labels", "METATILE_MauvilleGym_RaisedSwitch")
  for i, xy in ipairs(switches or Story.MAUVILLE_SWITCHES) do
    set(xy[1], xy[2], (i - 1 == which) and pressed or raised, false)
  end
end

local function sweep(rows, get, set, C)
  local byFrom = {}
  for _, r in ipairs(labels(C, rows)) do byFrom[r.from] = r end
  local greenV1 = C:require("metatile_labels", "METATILE_MauvilleGym_GreenBeamV1_On")
  local greenV2 = C:require("metatile_labels", "METATILE_MauvilleGym_GreenBeamV2_On")
  local redV2 = C:require("metatile_labels", "METATILE_MauvilleGym_RedBeamV2_On")
  for y = 5, 16 do
    for x = 0, 8 do
      local r = byFrom[get(x, y)]
      if r then
        if r.special == "floor" then
          -- pokeemerald/src/field_specials.c:706
          if get(x, y - 1) == greenV1 then set(x, y, greenV2, true) else set(x, y, redV2, true) end
        else
          set(x, y, r.to, r.impassable)
        end
      end
    end
  end
end

-- pokeemerald/src/field_specials.c:633
function Story.mauvilleSetDefaultBarriers(get, set, C)
  sweep(DEFAULT_BARRIERS, get, set, C)
end

-- pokeemerald/src/field_specials.c:727
function Story.mauvilleDeactivatePuzzle(get, set, C, switches)
  local pressed = C:require("metatile_labels", "METATILE_MauvilleGym_PressedSwitch")
  for _, xy in ipairs(switches or Story.MAUVILLE_SWITCHES) do set(xy[1], xy[2], pressed, false) end
  sweep(DEACTIVATE, get, set, C)
end

-- pokeemerald/src/field_specials.c:784
Story.SLIDING_DOOR_DELAY = { [0] = 0, 1, 1, 1, 1 }
Story.SLIDING_DOOR_FRAMES = {
  [0] = "PetalburgGym_SlidingDoor_Frame0", "PetalburgGym_SlidingDoor_Frame1", "PetalburgGym_SlidingDoor_Frame2",
  "PetalburgGym_SlidingDoor_Frame3", "PetalburgGym_SlidingDoor_Frame4",
}

-- pokeemerald/src/field_specials.c:820
Story.PETALBURG_DOORS = {
  [1] = { { 1, 104 }, { 7, 104 } },
  [2] = { { 1, 78 }, { 7, 78 } },
  [3] = { { 1, 91 }, { 7, 91 } },
  [4] = { { 7, 39 } },
  [5] = { { 1, 52 }, { 7, 52 } },
  [6] = { { 1, 65 } },
  [7] = { { 7, 13 } },
  [8] = { { 1, 26 } },
}

-- pokeemerald/include/global.fieldmap.h:60
Story.METATILE_ROW_WIDTH = 8

-- pokeemerald/src/field_specials.c:820 PetalburgGymSetDoorMetatiles
function Story.petalburgSetDoorMetatiles(room, mid, set)
  for _, xy in ipairs(Story.PETALBURG_DOORS[room] or {}) do
    set(xy[1], xy[2], mid, true)
    set(xy[1], xy[2] + 1, mid + Story.METATILE_ROW_WIDTH, true)
  end
end

function Story.slidingDoorMetatile(C, frame)
  return C:require("metatile_labels", "METATILE_" .. Story.SLIDING_DOOR_FRAMES[frame])
end

-- pokeemerald/src/field_specials.c:802 Task_PetalburgGymSlideOpenRoomDoors
function Story.slideDoorsTask(room, set, C, onFrame)
  local counter, frame = 0, 0
  return function()
    if Story.SLIDING_DOOR_DELAY[frame] == counter then
      Story.petalburgSetDoorMetatiles(room, Story.slidingDoorMetatile(C, frame), set)
      if onFrame then onFrame(frame) end
      counter = 0
      frame = frame + 1
      return frame == 5
    end
    counter = counter + 1
    return false
  end
end

-- pokeemerald/src/field_specials.c:1969 BufferVarsForIVRater
function Story.ivRater(ivs, random)
  local order = { "hp", "atk", "def", "spe", "spa", "spd" }
  local v = {}
  local total = 0
  for i, k in ipairs(order) do
    v[i - 1] = tonumber(ivs and ivs[k]) or 0
    total = total + v[i - 1]
  end
  local best, bestVal = 0, v[0]
  for i = 1, 5 do
    if v[best] < v[i] then
      best, bestVal = i, v[i]
    elseif v[best] == v[i] then
      if random() % 2 == 1 then best, bestVal = i, v[i] end
    end
  end
  return total, best, bestVal
end

-- pokeemerald/src/field_specials.c:1555
function Story.daysUntilPacifidlogTM(days, receivedDay)
  days = tonumber(days) or 0
  receivedDay = tonumber(receivedDay) or 0
  if days - receivedDay >= 7 then return 0 end
  if days < 0 then return 8 end
  return 7 - (days - receivedDay)
end

-- pokeemerald/src/field_specials.c:940
function Story.weekCount(days)
  local w = math.floor((tonumber(days) or 0) / 7)
  if w > 9999 then w = 9999 end
  return w
end

return Story
