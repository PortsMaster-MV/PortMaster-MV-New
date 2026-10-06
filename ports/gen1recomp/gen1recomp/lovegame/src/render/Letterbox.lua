-- UI LETTERBOX: what fills the window around a 160x144 screen.
--
-- AUTO keeps what each screen was authored with (Gen 1 black, Gen 2 mostly
-- white, the Pokedex and credits black); the other three override every
-- screen uniformly. PALETTE takes the active COLORS ramp's paper shade, so
-- the bars match the panel they frame instead of a fixed grey.

local Letterbox = {}

-- Set from applyOptions on both generations, the same shape GbcPalette.setMode
-- and Tilt.setLevel use, so a draw call needs no options table in hand.
Letterbox.mode = "auto"

Letterbox.MODES = { "auto", "black", "white", "palette" }

local LABELS = {
  auto = "AUTO", black = "BLACK", white = "WHITE", palette = "PALETTE",
}

function Letterbox.normalize(mode)
  for _, id in ipairs(Letterbox.MODES) do
    if mode == id then return id end
  end
  return "auto"
end

function Letterbox.label(mode)
  return LABELS[Letterbox.normalize(mode)]
end

function Letterbox.cycle(mode, dir)
  local at = 1
  for i, id in ipairs(Letterbox.MODES) do
    if id == Letterbox.normalize(mode) then at = i break end
  end
  local n = #Letterbox.MODES
  return Letterbox.MODES[(at - 1 + (dir or 1)) % n + 1]
end

-- r, g, b for `mode`, falling back to the screen's authored colour on AUTO.
--
-- `paper` is supplied by the caller, not looked up here: the two generations
-- keep their picked palette in different modules (Gen 1 in PaletteFX, Gen 2 in
-- GbcPalette) and GbcPalette.available() is true on both, so anything that
-- sniffed for it answered with Gen 2's white default on a Gen 1 game.
function Letterbox.color(mode, r, g, b, paper)
  mode = Letterbox.normalize(mode)
  if mode == "black" then return 0, 0, 0 end
  if mode == "white" then return 1, 1, 1 end
  if mode == "palette" and paper then
    local pr, pg, pb = paper()
    if pr then return pr, pg, pb end
  end
  return r or 0, g or 0, b or 0
end

function Letterbox.setMode(mode)
  Letterbox.mode = Letterbox.normalize(mode)
  return Letterbox.mode
end

function Letterbox.applyOptions(options)
  return Letterbox.setMode(options and options.uiLetterbox)
end

-- What a drawWidescreen should paint the window with, given the colour that
-- screen was authored to use and its generation's paper reader.
function Letterbox.fill(r, g, b, paper)
  return Letterbox.color(Letterbox.mode, r, g, b, paper)
end

return Letterbox
