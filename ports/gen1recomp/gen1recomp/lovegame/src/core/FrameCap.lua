-- Render frame-rate cap.  With a driver control panel forcing
-- vsync off, the 160x144 game is trivially cheap and love.run will present
-- thousands of frames a second; over hours that cooks the graphics driver
-- until a restart, and it wastes power whenever the window is left open in
-- the background.  A hard cap bounds the present rate.  Render-only: game
-- logic is fixed-step off dt (src/core/FixedStep.lua), so pacing present()
-- changes nothing about timing, audio, or determinism.
--
-- Persisted as save.options.fpsCap; applied from OptionsMenu and on boot
-- via Game:applyOptions.  main.lua's love.run reads FrameCap.current each
-- frame for its sleep budget.  The module never touches love.timer itself,
-- so it stays safe under the headless test stub.

local FrameCap = {}

local function isHandheldEnv()
  return os.getenv("HANDHELD") == "1" or os.getenv("PORTMASTER") == "1"
    or os.getenv("POKEPORT_HANDHELD") == "1" or os.getenv("TRIMUI") == "1"
    or os.getenv("MUOS") == "1" or os.getenv("KNULLI") == "1"
end

-- Platforms where PresentSync should pace via the panel (DISPLAY), not a
-- numeric FrameCap default.  Android/iOS/UWP need uncapped probe isolation
-- so composed GLES swapchains can lock; PortMaster handhelds likewise
-- follow KMSDRM through PresentSync.
function FrameCap.loopSupportsPanelSync()
  return rawget(_G, "POKEPORT_LOOP_PANEL_SYNC") == true
end

function FrameCap.prefersPanelSync()
  if not FrameCap.loopSupportsPanelSync() then return false end
  if isHandheldEnv() then return true end
  if love and love.system and love.system.getOS then
    local osName = love.system.getOS()
    if osName == "Android" or osName == "iOS" or osName == "UWP" then
      return true
    end
  end
  return false
end

-- Selectable steps: the normal framerate stops between the floor and the
-- ceiling.  STEPS[1] == MIN and STEPS[#STEPS] == MAX, so the nearest-step
FrameCap.STEPS = { 30, 40, 50, 60, 75, 90, 100, 120, 144, 160 }
FrameCap.MIN = 30
FrameCap.MAX = 160
FrameCap.DEFAULT = 60

FrameCap.DISPLAY = 0

FrameCap.CYCLE = {}
for i, step in ipairs(FrameCap.STEPS) do FrameCap.CYCLE[i] = step end
FrameCap.CYCLE[#FrameCap.CYCLE + 1] = FrameCap.DISPLAY

-- The live cap the run loop paces to.  Defaults so the launcher and the
-- save editor are paced before any save applies its stored option.
FrameCap.current = FrameCap.DEFAULT

-- Nearest valid step for an arbitrary value (a hand-edited options.lua or
-- an old save with no fpsCap key), so a bad number degrades to something
function FrameCap.normalize(value)
  value = tonumber(value)
  if not value then return FrameCap.DEFAULT end
  if value <= 0 then
    if FrameCap.loopSupportsPanelSync() then return FrameCap.DISPLAY end
    return FrameCap.DEFAULT
  end
  local best, bestDiff = FrameCap.DEFAULT, math.huge
  for _, step in ipairs(FrameCap.STEPS) do
    local diff = math.abs(step - value)
    if diff < bestDiff then best, bestDiff = step, diff end
  end
  return best
end

function FrameCap.label(value)
  local cap = FrameCap.normalize(value)
  local text = cap == FrameCap.DISPLAY and "DISPLAY" or tostring(cap)
  local ok, hz = pcall(function()
    return require("src.core.RefreshRate").mismatch()
  end)
  if ok and hz then text = string.format("%s (%dHZ)", text, math.floor(hz + 0.5)) end
  return text
end

function FrameCap.cycle(value, dir)
  local ring = FrameCap.CYCLE
  local snapped = FrameCap.normalize(value)
  local cur = 1
  for i, step in ipairs(ring) do
    if step == snapped then cur = i break end
  end
  local nextIdx = (cur - 1 + (dir or 1)) % #ring + 1
  return ring[nextIdx]
end

-- Store the chosen cap as the live value the run loop paces to.  Never
-- touches love.timer, so it is safe headless -- the loop just reads the
-- number back.  Returns the normalized value it stored.
function FrameCap.apply(value)
  FrameCap.current = FrameCap.normalize(value)
  return FrameCap.current
end

function FrameCap.applyOptions(opts)
  local cap = opts and opts.fpsCap
  -- Handheld / Android / iOS / UWP follow the panel through PresentSync; the
  -- stored default 60 would bypass DISPLAY pacing and force the software
  -- limiter (and on composed GLES nests that also prevents vsync locking).
  if (cap == nil or cap == FrameCap.DEFAULT) and FrameCap.prefersPanelSync() then
    cap = FrameCap.DISPLAY
  end
  return FrameCap.apply(cap)
end

-- Launcher / pre-save boot: same DISPLAY default before any save applies.
function FrameCap.bootPanelSync()
  if FrameCap.prefersPanelSync() and FrameCap.current == FrameCap.DEFAULT then
    return FrameCap.apply(FrameCap.DISPLAY)
  end
  return FrameCap.current
end

-- Alias kept for existing call sites / docs.
FrameCap.bootHandheld = FrameCap.bootPanelSync

-- Performance LOW tier caps extras; do not rewrite DISPLAY to numeric 60 when
-- the panel is already at or below the ceiling (that bypasses PresentSync).
function FrameCap.clampToPerformance(fpsMax)
  fpsMax = tonumber(fpsMax)
  if not fpsMax then return FrameCap.current end
  if FrameCap.current > fpsMax then
    return FrameCap.apply(fpsMax)
  end
  if FrameCap.current == FrameCap.DISPLAY then
    local ok, RR = pcall(require, "src.core.RefreshRate")
    local hz = ok and RR.hz()
    if hz and hz > fpsMax then
      return FrameCap.apply(fpsMax)
    end
  end
  return FrameCap.current
end

return FrameCap
