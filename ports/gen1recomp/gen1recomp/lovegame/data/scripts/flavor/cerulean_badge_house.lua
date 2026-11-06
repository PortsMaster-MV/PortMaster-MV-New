-- CeruleanBadgeHouse (pokered/scripts/CeruleanBadgeHouse.asm)
--
-- CeruleanBadgeHouseMiddleAgedManText is a text_asm: it prints a
-- greeting, then loops a badge-description menu (LoadItemList /
-- DisplayListMenuID over CeruleanBadgeHouseBadgeTextPointers) until the
-- player backs out with B, then prints a goodbye line.  The badge list
-- is the fixed set of all 8 badges (not filtered by what the player
-- owns) -- it's an explanatory menu, not a real item pick.

local function push(game, s, done)
  local TextBox = require("src.render.TextBox")
  game.stack:push(TextBox.new(game, s, done))
end

-- CeruleanBadgeHouseBadgeTextPointers / .BadgeItemList
local BADGE_ORDER = {
  "BOULDERBADGE", "CASCADEBADGE", "THUNDERBADGE", "RAINBOWBADGE",
  "SOULBADGE", "MARSHBADGE", "VOLCANOBADGE", "EARTHBADGE",
}
local BADGE_TEXT = {
  BOULDERBADGE = "_CeruleanBadgeHouseBoulderBadgeText",
  CASCADEBADGE = "_CeruleanBadgeHouseCascadeBadgeText",
  THUNDERBADGE = "_CeruleanBadgeHouseThunderBadgeText",
  RAINBOWBADGE = "_CeruleanBadgeHouseRainbowBadgeText",
  SOULBADGE = "_CeruleanBadgeHouseSoulBadgeText",
  MARSHBADGE = "_CeruleanBadgeHouseMarshBadgeText",
  VOLCANOBADGE = "_CeruleanBadgeHouseVolcanoBadgeText",
  EARTHBADGE = "_CeruleanBadgeHouseEarthBadgeText",
}

local function middleAgedMan(game, ow, npc, done)
  local t = game.data.text
  local ListMenu = require("src.ui.ListMenu")
  local Strings = require("src.core.Strings")
  local TextBox = require("src.render.TextBox")

  local items = {}
  for _, id in ipairs(BADGE_ORDER) do
    local idef = game.data.items[id]
    items[#items + 1] = { label = idef and idef.name or id, value = id }
  end
  items[#items + 1] = { cancel = true, label = Strings("CANCEL") }

  local prompt
  local function closePrompt()
    if prompt and game.stack:top() == prompt then game.stack:pop() end
    prompt = nil
  end

  -- text/CeruleanBadgeHouse.asm:19
  local function whichBadge(onShown)
    local box = TextBox.new(game,
      t._CeruleanBadgeHouseMiddleAgedManWhichBadgeText, nil,
      { stay = { onShown = onShown } })
    game.stack:push(box)
    return box
  end

  -- LIST_MENU_BOX 4,2 - 19,12 (home/list_menu.asm:29-31, data/text_boxes.asm:13);
  -- one menu for the whole .loop (scripts/CeruleanBadgeHouse.asm:16-18, 47)
  local menu = ListMenu.new(game, nil, items, {
    kind = "badge_descriptions",
    itemBox = true,
    onChoose = function(item, list)
      if item.cancel or not item.value then
        list:close()
        closePrompt()
        push(game, t._CeruleanBadgeHouseMiddleAgedManVisitAnyTimeText, done)
        return
      end
      -- home/list_menu.asm:160-171
      push(game, t[BADGE_TEXT[item.value]], function()
        whichBadge(function() game.stack:pop() end)
      end)
    end,
    onCancel = function()
      closePrompt()
      push(game, t._CeruleanBadgeHouseMiddleAgedManVisitAnyTimeText, done)
    end,
  })

  push(game, t._CeruleanBadgeHouseMiddleAgedManText, function()
    prompt = whichBadge(function() game.stack:push(menu) end)
  end)
end

return {
  CERULEAN_BADGE_HOUSE = {
    talk = {
      TEXT_CERULEANBADGEHOUSE_MIDDLE_AGED_MAN = middleAgedMan,
    },
  },
}
