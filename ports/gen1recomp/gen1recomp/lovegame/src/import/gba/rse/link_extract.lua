local TradeExtract = require("src.import.gba.trade_extract")

local M = {}

M.SUB = TradeExtract.CACHE_SUB

-- pokeemerald/src/data/trade.h:624
M.FILES = {
  "manifest.lua", "gba_screen.rgba", "gba_screen_wireless.rgba", "gba_screen_flash.rgba",
  "cable_closeup.rgba", "cable_end.rgba", "link_mon_glow.rgba", "link_mon_shadow.rgba",
  "mon_shadow_bg.rgba", "ball.rgba", "ball_spin.rgba", "menu_bg1.rgba", "stripes_bg2.rgba",
  "stripes_bg3.rgba", "party_box.rgba", "moves_box.rgba", "mon_box.rgba", "menu_tiles.rgba",
  "cursor.rgba",
}

M.REQUIRED = {}
for i, f in ipairs(M.FILES) do M.REQUIRED[i] = M.SUB .. "/" .. f end

function M.run(rom, cache, opts)
  return TradeExtract.run(rom, cache, opts)
end

return M
