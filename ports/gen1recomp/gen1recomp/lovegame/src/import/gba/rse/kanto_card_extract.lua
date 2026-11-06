local TrainerCardExtract = require("src.import.gba.trainer_card_extract")

local M = {}

M.SUB = TrainerCardExtract.CACHE_SUB

M.FILES = { "manifest.lua", "bg.rgba", "bg_female.rgba", "badges.rgba", "star.rgba", "stickers.rgba" }
for stars = 0, TrainerCardExtract.STAR_COUNT - 1 do
  for _, side in ipairs({ "front", "back", "screen" }) do
    M.FILES[#M.FILES + 1] = string.format("%s_%d.rgba", side, stars)
    M.FILES[#M.FILES + 1] = string.format("%s_%d_female.rgba", side, stars)
  end
end

M.REQUIRED = {}
for i, f in ipairs(M.FILES) do M.REQUIRED[i] = M.SUB .. "/" .. f end

-- pokeemerald/src/trainer_card.c:274
function M.run(rom, cache, opts)
  return TrainerCardExtract.run(rom, cache, opts)
end

return M
