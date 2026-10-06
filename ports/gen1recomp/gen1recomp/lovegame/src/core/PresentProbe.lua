-- Present sync: probe whether presents are actually paced, then pick a
-- strategy.  Fail closed to FrameCap whenever the signal is ambiguous.
--
-- PROBE SIGNAL = inter-present cadence (wall time between present ends),
-- with FrameCap OFF for the whole calibration.  present()-block alone is
-- not portable:
--
--   wayland   SDL sets EGL swapinterval 0 and waits on wl_surface.frame
--             (often around swap).  Block timing alone false-failed here.
--   windows   DWM / flip-model / VRR can return from Present early; the
--             pacing shows up in the gap between presents (Ally X class).
--   macos     Compositor / CVDisplayLink similarly; cadence is authoritative.
--   android/ios  SurfaceFlinger BufferQueue back-pressure via eglSwapBuffers
--             (LOVE/SDL does not use Choreographer).  Swap returns fast until
--             the queue is full, then blocks on VSYNC.  Fail-closed must also
--             silence driver vsync: sleeping under FrameCap while swapinterval
--             stays 1 keeps the queue from staying full, so vsync never locks.
--   uwp       Xbox (and other LOVE UWP) builds: ANGLE → D3D11 under the
--             console compositor (Dev Mode sits in Hyper-V).  Not desktop
--             DWM.  Same fail-closed rule as BufferQueue: soft-cap alone
--             while swapinterval stays 1 prevents a clean lock.
--   x11       GLX swapinterval often blocks in swap, but compositors
--             (Picom, etc.) can defer — cadence still correct.  If ungated,
--             try OML/SGI wait (native X11 only).
--   xwayland/gamescope  Never bind GLX waits (WaitForMsc can hard-hang when
--             the MSC ticks on a soft clock).  Ungated → FrameCap only.
--   kmsdrm    Page-flip wait is SDL's; we never call drmWaitVBlank.  Ungated
--             → FrameCap.
--
-- FrameCap sleep must never run during the probe or cadence grades our
-- own limiter again.

local PresentProbe = {}

-- Cadence samples between presents while FrameCap is disabled.
local PROBE_FRAMES = 45
local PROBE_SKIP = 5          -- drop first samples (startup hitch)
-- Android/iOS/UWP: early swaps return near-instant while the composed
-- swapchain / BufferQueue fills before back-pressure engages.
local PROBE_SKIP_COMPOSITED = 12
local INSTANT_MS = 0.0005
local BLOCK_MS = 0.002
local WAIT_ABORT_S = 0.1

-- Hot-path: a single cached closure, no ffi.C / string work inside it.
local waitFn = nil

local state = {
  osLinux = false,
  ready = false,
  driver = nil,       -- "wayland" | "x11" | "kmsdrm" | ...
  nest = nil,         -- platform nest string (see platformNest / detectNest)
  gamescope = false,
  gated = nil,        -- nil while probing, then true/false
  strategy = "none",  -- "none" | "sdl" | "oml" | "sgi"
  needsSoftwareCap = false,
  -- Composited GLES nests: drop swapinterval when soft-capping so FrameCap
  -- is the sole pacer (android / ios / uwp).
  silenceDriver = false,
  probeCount = 0,
  lastPresent = nil,  -- love.timer time of previous present end (cadence)
  intervals = nil,    -- inter-present cadence while probing
  glxGen = 0,
  bindGen = -1,
}

local ffi = nil
local sdlLib = nil
local x11Lib = nil
local glLib = nil

local function isLinux()
  if not love or not love.system or not love.system.getOS then return false end
  return love.system.getOS() == "Linux"
end

local function envTruthy(name)
  local v = os.getenv(name)
  return v ~= nil and v ~= ""
end

local function loadSdl()
  if sdlLib ~= nil then return sdlLib or nil end
  if not ffi then
    local ok, f = pcall(require, "ffi")
    if not ok then sdlLib = false return nil end
    ffi = f
  end
  pcall(ffi.cdef, [[
    const char *SDL_GetCurrentVideoDriver(void);
    typedef struct SDL_Window SDL_Window;
    SDL_Window *SDL_GL_GetCurrentWindow(void);
  ]])
  local okLoad, lib = pcall(ffi.load, "SDL2")
  lib = okLoad and lib or ffi.C
  local okSym = pcall(function() return lib.SDL_GetCurrentVideoDriver end)
  sdlLib = okSym and lib or false
  return sdlLib or nil
end

local function videoDriver()
  local lib = loadSdl()
  if not lib then return nil end
  local ok, name = pcall(function()
    local p = lib.SDL_GetCurrentVideoDriver()
    if p == nil then return nil end
    return ffi.string(p)
  end)
  if not ok or not name or name == "" then return nil end
  return name
end

-- Prefer XQueryExtension("XWAYLAND") when we have a Display*; fall back to
-- session env heuristics when GLX is not up yet.
local function detectXWayland(dpy)
  if dpy ~= nil and x11Lib then
    local major = ffi.new("int[1]")
    local event = ffi.new("int[1]")
    local errCode = ffi.new("int[1]")
    local ok, present = pcall(x11Lib.XQueryExtension, dpy, "XWAYLAND",
      major, event, errCode)
    if ok and present ~= 0 then return true end
    if ok and present == 0 then return false end
  end
  -- SDL x11 driver under a Wayland session is almost always XWayland.
  return envTruthy("WAYLAND_DISPLAY") or envTruthy("WAYLAND_SOCKET")
    or envTruthy("GAMESCOPE_WAYLAND_DISPLAY")
end

local function detectNest(driver)
  if not driver then return "unknown" end
  if driver == "wayland" then return "wayland" end
  if driver == "kmsdrm" or driver == "rpi" then return "kmsdrm" end
  if driver == "x11" then
    return detectXWayland(nil) and "xwayland" or "x11"
  end
  return "unknown"
end

-- Classify from inter-present cadence (probe runs with FrameCap off).
-- Fail closed on ambiguity / jitter.  Prefer FrameCap over a false trust.
local COMMON_HZ = { 60, 75, 90, 100, 120, 144, 165, 240 }

local function resolveExpect(mid)
  local hz = nil
  local okRR, RR = pcall(require, "src.core.RefreshRate")
  if okRR then hz = RR.hz() end
  if hz and hz > 0 then return 1 / hz, hz end
  -- SDL often reports refresh_rate=0 on some paths; infer a panel period
  -- from the cadence itself against common rates so a working desktop is
  -- not forced to UNAVAILABLE.
  if not mid or mid <= 0 then return nil, nil end
  for i = 1, #COMMON_HZ do
    local c = COMMON_HZ[i]
    local e = 1 / c
    if mid >= e * 0.85 and mid <= e * 1.15 then return e, c end
  end
  for i = 1, #COMMON_HZ do
    local c = COMMON_HZ[i]
    local e = 1 / c
    if mid >= e * 1.85 and mid <= e * 2.15 then return e, c end
  end
  return nil, nil
end

local function classifyGated(intervals)
  if not intervals or #intervals < 10 then return nil end
  local sorted = {}
  for i = 1, #intervals do sorted[i] = intervals[i] end
  table.sort(sorted)
  local mid = sorted[math.floor(#sorted / 2) + 1]
  if not mid or mid <= 0 then return false end

  local expect = resolveExpect(mid)
  if not expect then return false end

  local q1 = sorted[math.floor(#sorted * 0.25) + 1]
  local q3 = sorted[math.floor(#sorted * 0.75) + 1]
  if not q1 or not q3 or (q3 - q1) > mid * 0.2 then return false end

  if mid < expect * 0.5 then return false end
  if mid >= expect * 0.85 and mid <= expect * 1.15 then return true end
  if mid >= expect * 1.85 and mid <= expect * 2.15 then return true end
  return false
end

local function loadGlx()
  if glLib ~= nil then return glLib or nil end
  if not ffi then return nil end
  pcall(ffi.cdef, [[
    typedef unsigned long LPS_GLXDrawable;
    typedef struct LPS_XDisplay LPS_Display;
    typedef int LPS_Bool;
    void *glXGetProcAddress(const unsigned char *name);
    void *glXGetProcAddressARB(const unsigned char *name);
    LPS_Display *glXGetCurrentDisplay(void);
    LPS_GLXDrawable glXGetCurrentDrawable(void);
    LPS_Bool XQueryExtension(LPS_Display *display, const char *name,
      int *major_opcode, int *first_event, int *first_error);
  ]])
  local function tryLoad(name)
    local ok, lib = pcall(ffi.load, name)
    return ok and lib or nil
  end
  glLib = tryLoad("GL") or tryLoad("libGL.so.1") or tryLoad("libGLX.so.0") or false
  if x11Lib == nil then
    x11Lib = tryLoad("X11") or tryLoad("libX11.so.6") or false
  end
  return glLib or nil
end

local function procAddress(gl, name)
  local cname = ffi.cast("const unsigned char *", name)
  local p = nil
  if gl.glXGetProcAddress then
    p = gl.glXGetProcAddress(cname)
  end
  if (p == nil or p == ffi.NULL) and gl.glXGetProcAddressARB then
    p = gl.glXGetProcAddressARB(cname)
  end
  if p == nil or p == ffi.NULL then return nil end
  return p
end

local function verifyBlocks(fn)
  if not love or not love.timer or not love.timer.getTime then return false end
  local t0 = love.timer.getTime()
  local ok = pcall(fn)
  local dt = love.timer.getTime() - t0
  if not ok then return false end
  if dt < INSTANT_MS then return false end
  return dt >= BLOCK_MS or dt >= INSTANT_MS * 2
end

-- WaitForMsc / WaitVideoSync hang forever when the counter never advances
-- (vblank_mode=0, frozen CRTC).  Probe the counter with a short sleep first.
local function omlClockAlive(getSync, getDisplay, getDrawable)
  if not love or not love.timer or not love.timer.sleep then return false end
  local ust = ffi.new("long long[1]")
  local msc = ffi.new("long long[1]")
  local sbc = ffi.new("long long[1]")
  local d = getDisplay()
  if d == nil then return false end
  local drawable = getDrawable()
  if drawable == 0 then return false end
  if getSync(d, drawable, ust, msc, sbc) == 0 then return false end
  local first = msc[0]
  love.timer.sleep(0.05)
  if getSync(d, drawable, ust, msc, sbc) == 0 then return false end
  return msc[0] ~= first
end

local function sgiClockAlive(getVS)
  if not love or not love.timer or not love.timer.sleep then return false end
  local count = ffi.new("unsigned int[1]")
  count[0] = 0
  if getVS(count) ~= 0 then return false end
  local first = count[0]
  love.timer.sleep(0.05)
  if getVS(count) ~= 0 then return false end
  return count[0] ~= first
end

local function bindGlxWait(nest)
  local gl = loadGlx()
  if not gl then return nil, nil end

  local getDisplay = gl.glXGetCurrentDisplay
  local getDrawable = gl.glXGetCurrentDrawable
  if not getDisplay or not getDrawable then return nil, nil end

  local dpy = getDisplay()
  if dpy == nil then return nil, nil end
  -- Refine nest now that we have a Display*.
  if nest == "x11" or nest == "xwayland" then
    local refined = detectXWayland(dpy) and "xwayland" or "x11"
    nest = refined
    state.nest = refined
  end

  -- OML first.
  local pGetSync = procAddress(gl, "glXGetSyncValuesOML")
  local pWaitMsc = procAddress(gl, "glXWaitForMscOML")
  if pGetSync and pWaitMsc then
    local getSync = ffi.cast(
      "LPS_Bool (*)(LPS_Display *, LPS_GLXDrawable, long long *, long long *, long long *)",
      pGetSync)
    local waitMsc = ffi.cast(
      "LPS_Bool (*)(LPS_Display *, LPS_GLXDrawable, long long, long long, long long, long long *, long long *, long long *)",
      pWaitMsc)
    if omlClockAlive(getSync, getDisplay, getDrawable) then
      local ust = ffi.new("long long[1]")
      local msc = ffi.new("long long[1]")
      local sbc = ffi.new("long long[1]")
      local target = ffi.new("long long[1]")
      local zero = ffi.new("long long", 0)
      local one = ffi.new("long long", 1)
      ust[0], msc[0], sbc[0], target[0] = 0, 0, 0, 0
      -- Locals only — hot path must not touch ffi.C or string tables.
      local gd, gdrw, gs, wm = getDisplay, getDrawable, getSync, waitMsc
      local fn = function()
        local d = gd()
        if d == nil then return end
        local drawable = gdrw()
        if drawable == 0 then return end
        if gs(d, drawable, ust, msc, sbc) == 0 then return end
        -- Keep MSC arithmetic in 64-bit cdata; Lua numbers lose integers > 2^53.
        target[0] = msc[0] + one
        wm(d, drawable, target[0], zero, zero, ust, msc, sbc)
      end
      if verifyBlocks(fn) then return "oml", fn end
    end
  end

  -- SGI fallback.
  local pGet = procAddress(gl, "glXGetVideoSyncSGI")
  local pWait = procAddress(gl, "glXWaitVideoSyncSGI")
  if pGet and pWait then
    local getVS = ffi.cast("int (*)(unsigned int *)", pGet)
    local waitVS = ffi.cast("int (*)(int, int, unsigned int *)", pWait)
    if sgiClockAlive(getVS) then
      local count = ffi.new("unsigned int[1]")
      count[0] = 0
      local gv, wv = getVS, waitVS
      local divisor = 2
      local fn = function()
        count[0] = 0
        if gv(count) ~= 0 then return end
        -- Wait for the opposite parity of the current counter (next vblank).
        -- remainder must stay in [0, divisor); count is seeded before gv.
        local nextRem = (tonumber(count[0]) + 1) % divisor
        wv(divisor, nextRem, count)
      end
      if verifyBlocks(fn) then return "sgi", fn end
    end
  end

  return nil, nil
end

local function isCompositedGlesNest(nest)
  return nest == "android" or nest == "ios" or nest == "uwp"
end

local function silenceDriverIfNeeded()
  if not state.silenceDriver then return end
  local okV, VSync = pcall(require, "src.core.VSync")
  if okV and VSync.silenceDriver then pcall(VSync.silenceDriver) end
end

local function pickStrategy()
  -- Always drop any prior wait first.  While gated is nil we are probing
  -- unassisted present intervals — never re-bind mid-probe or the sample
  -- measures our own wait instead of the driver's raw behaviour.
  waitFn = nil
  state.needsSoftwareCap = false
  state.silenceDriver = false
  state.strategy = "none"

  local vsyncOn = true
  local okV, VSync = pcall(require, "src.core.VSync")
  if okV and VSync.isOn then vsyncOn = VSync.isOn() end
  if not vsyncOn then
    state.strategy = "none"
    return
  end

  local nest = state.nest
  if isCompositedGlesNest(nest) then
    -- Android/iOS BufferQueue or Xbox UWP ANGLE→D3D11 composition.
    -- Never bind GLX.  Fail-closed silences driver vsync so FrameCap alone
    -- paces (soft-cap + swapinterval 1 prevents the composed swapchain
    -- from locking cleanly).
    if state.gated == true then
      state.strategy = "sdl"
    elseif state.gated == false then
      state.needsSoftwareCap = true
      state.silenceDriver = true
      state.strategy = "none"
      silenceDriverIfNeeded()
    else
      state.strategy = "sdl"
    end
    return
  end

  if not state.osLinux then
    -- windows / macos: never bind GLX.  Cadence probe is the authority
    -- (DWM / Cocoa compositor can defer the wait past present() return).
    -- Ungated → FrameCap only.  Desktop does not silence driver vsync.
    if state.gated == true then
      state.strategy = "sdl"
    elseif state.gated == false then
      state.needsSoftwareCap = true
      state.strategy = "none"
    else
      state.strategy = "sdl"
    end
    return
  end

  if nest == "wayland" then
    -- SDL owns wl_surface.frame.  Never duplicate it.
    state.strategy = "sdl"
    if state.gated == false then
      -- Vsync option is on but presents are ungated: thermal net only.
      state.needsSoftwareCap = true
      state.strategy = "none"
    end
    return
  end

  if nest == "kmsdrm" then
    state.strategy = "none"
    if state.gated == false then state.needsSoftwareCap = true end
    return
  end

  if nest == "x11" or nest == "xwayland" then
    if state.gated == true then
      state.strategy = "sdl"
      return
    end
    if state.gated == nil then
      -- Probing: leave waitFn nil so notePresent sees bare swap timing.
      state.strategy = "sdl"
      return
    end
    -- gated == false: SDL swap-interval is a no-op.
    --
    -- XWayland (and Gamescope-on-XWayland): GLX OML/SGI MSC can tick on a
    -- soft timer while WaitForMsc / WaitVideoSync block forever on a signal
    -- that never fires (reproduced with vblank_mode=0).  Never bind those
    -- waits here — FrameCap is the thermal net.
    if nest == "xwayland" then
      state.needsSoftwareCap = true
      state.strategy = "none"
      state.bindGen = state.glxGen
      return
    end
    -- Native X11 only: try a real GLX wait after confirming the counter moves.
    local kind, fn = bindGlxWait(nest)
    state.bindGen = state.glxGen
    if kind and fn then
      state.strategy = kind
      waitFn = fn
      state.needsSoftwareCap = false
      return
    end
    state.needsSoftwareCap = true
    state.strategy = "none"
    return
  end

  if state.gated == false then state.needsSoftwareCap = true end
  state.strategy = "none"
end

local function platformNest()
  if not love or not love.system or not love.system.getOS then return "unknown" end
  local osName = love.system.getOS()
  if osName == "Windows" then return "windows" end
  if osName == "OS X" or osName == "macOS" then return "macos" end
  if osName == "Android" then return "android" end
  if osName == "iOS" then return "ios" end
  -- LOVE_WINDOWS_UWP (Xbox package): not desktop DWM.
  if osName == "UWP" then return "uwp" end
  if osName == "Linux" then return detectNest(state.driver) end
  return osName:lower()
end

local function ensureDetected()
  if state.ready then return end
  state.osLinux = isLinux()
  state.driver = videoDriver()
  state.gamescope = false
  if state.osLinux then
    state.gamescope = envTruthy("GAMESCOPE_WAYLAND_DISPLAY")
      or (os.getenv("XDG_CURRENT_DESKTOP") or ""):lower():find("gamescope", 1, true) ~= nil
    state.nest = detectNest(state.driver)
    if state.gamescope and state.nest == "x11" then
      state.nest = "xwayland"
    end
  else
    state.nest = platformNest()
  end
  state.ready = true
  state.intervals = {}
  state.probeCount = 0
  state.gated = nil
  pickStrategy()
end

function PresentProbe.reset()
  waitFn = nil
  state.ready = false
  state.driver = nil
  state.nest = nil
  state.gamescope = false
  state.gated = nil
  state.strategy = "none"
  state.needsSoftwareCap = false
  state.silenceDriver = false
  state.probeCount = 0
  state.lastPresent = nil
  state.intervals = nil
  state.glxGen = state.glxGen + 1
  state.bindGen = -1
  sdlLib, x11Lib, glLib = nil, nil, nil
end

-- Fullscreen / resize / context loss: drop cached GLX entry points.
function PresentProbe.onDisplayChange()
  if not state.ready then ensureDetected() end
  waitFn = nil
  state.glxGen = state.glxGen + 1
  state.bindGen = -1
  state.gated = nil
  state.probeCount = 0
  state.intervals = {}
  state.lastPresent = nil
  state.strategy = "none"
  state.needsSoftwareCap = false
  state.silenceDriver = false
  glLib = nil
  -- Keep driver/nest; re-probe effectiveness and rebind on next presents.
  pickStrategy()
end

function PresentProbe.reprobe()
  ensureDetected()
  state.gated = nil
  state.probeCount = 0
  state.intervals = {}
  state.lastPresent = nil
  waitFn = nil
  state.glxGen = state.glxGen + 1
  state.bindGen = -1
  state.silenceDriver = false
  glLib = nil
  pickStrategy()
end

local function abandonWait()
  waitFn = nil
  state.strategy = "none"
  state.needsSoftwareCap = true
  state.gated = false
  state.bindGen = state.glxGen
  if isCompositedGlesNest(state.nest) then
    state.silenceDriver = true
    silenceDriverIfNeeded()
  end
end

-- Hot path: must stay allocation-free and avoid ffi.C / require.
-- Cadence probe: wall time between present ends.  Safe only while FrameCap
-- is off (PresentSync probe isolation).  present()-block alone is not enough
-- on Wayland, where the wait often lands on the next frame callback.
function PresentProbe.waitBeforePresent()
  local fn = waitFn
  if fn then
    local t0 = love.timer and love.timer.getTime and love.timer.getTime()
    local ok = pcall(fn)
    local t1 = love.timer and love.timer.getTime and love.timer.getTime()
    if not ok or (t0 and t1 and (t1 - t0) > WAIT_ABORT_S) then
      abandonWait()
    end
  end
end

function PresentProbe.notePresent()
  if not state.ready then ensureDetected() end

  if state.gated ~= nil then
    if state.gated == false
       and waitFn == nil
       and state.bindGen ~= state.glxGen
       and (state.nest == "x11" or state.nest == "xwayland") then
      pickStrategy()
    end
    return
  end

  local now = love.timer and love.timer.getTime and love.timer.getTime()
  if not now then return end
  local last = state.lastPresent
  state.lastPresent = now
  if not last then return end
  local gap = now - last
  -- Discard hitches / timer glitches; keep sampling until we have clean ones.
  if gap <= 0 or gap > 0.25 then return end
  -- Skip early presents so window/map boot (and composed-swapchain /
  -- BufferQueue fill on Android/iOS/UWP) does not widen IQR.
  state.probeCount = (state.probeCount or 0) + 1
  local skip = isCompositedGlesNest(state.nest) and PROBE_SKIP_COMPOSITED or PROBE_SKIP
  if state.probeCount <= skip then return end
  local intervals = state.intervals
  if not intervals then
    intervals = {}
    state.intervals = intervals
  end
  intervals[#intervals + 1] = gap
  if #intervals < PROBE_FRAMES then return end

  state.gated = classifyGated(intervals)
  pickStrategy()
end

function PresentProbe.needsSoftwareCap()
  return state.needsSoftwareCap == true
end

function PresentProbe.status()
  ensureDetected()
  return {
    linux = state.osLinux,
    driver = state.driver,
    nest = state.nest,
    gamescope = state.gamescope,
    gated = state.gated,
    strategy = state.strategy,
    needsSoftwareCap = state.needsSoftwareCap,
    silenceDriver = state.silenceDriver,
    probeCount = state.probeCount,
  }
end

-- Test seams ---------------------------------------------------------------

function PresentProbe._testSetState(fields)
  fields = fields or {}
  for k, v in pairs(fields) do
    if k ~= "waitFn" and k ~= "clearGated" then state[k] = v end
  end
  -- pairs() skips nil values, so gated=nil alone cannot clear a prior probe.
  if fields.clearGated then state.gated = nil end
  if fields.waitFn ~= nil then
    waitFn = (fields.waitFn ~= false) and fields.waitFn or nil
  end
end

function PresentProbe._testClassifyGated(intervals)
  return classifyGated(intervals)
end

function PresentProbe._testPickStrategy()
  pickStrategy()
  return state.strategy, state.needsSoftwareCap, waitFn ~= nil
end

return PresentProbe
