local LinkArt = require("src.import.gba.link_art_extract")
local OnlineUi = require("src.import.gba.online_ui_extract")
local Classes = require("src.import.gba.union_room_classes_extract")

local M = {}

M.FILES = {
  union_room = {
    "manifest.lua", "wireless_icon.rgba", "chat_bg.rgba", "chat_panel.rgba", "chat_icons.rgba",
    "chat_selector_cursor.rgba", "chat_text_entry_cursor.rgba", "chat_char_select_cursor.rgba",
    "chat_r_button.rgba", "avatars.lua",
  },
  wireless_status = { "manifest.lua", "bg.rgba", "bg_index.bin", "palettes.pal" },
  trainers = { Classes.FILE },
}

M.REQUIRED = {}
for _, sub in ipairs({ "union_room", "wireless_status", "trainers" }) do
  for _, f in ipairs(M.FILES[sub]) do M.REQUIRED[#M.REQUIRED + 1] = sub .. "/" .. f end
end

function M.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local out = LinkArt.run(rom, cache, { cacheRoot = root })
  OnlineUi.avatars(rom, cache, root)
  Classes.run(rom, cache, { cacheRoot = root })
  return out
end

return M
