local RefreshRate = {}

local DECLS = {
  "typedef struct SDL_Window SDL_Window;",
  "SDL_Window *SDL_GL_GetCurrentWindow(void);",
  "typedef struct { uint32_t format; int w; int h; int refresh_rate;" ..
    " void *driverdata; } SDL_DisplayMode;",
  "int SDL_GetWindowDisplayIndex(SDL_Window *window);",
  "int SDL_GetCurrentDisplayMode(int displayIndex, SDL_DisplayMode *mode);",
}

local ffiState = nil

local function sdlFfi()
  if ffiState ~= nil then return ffiState or nil end
  if not (love and love.window) then return nil end
  local okFfi, ffi = pcall(require, "ffi")
  if not okFfi then ffiState = false return nil end
  for _, decl in ipairs(DECLS) do pcall(ffi.cdef, decl) end
  local ok = pcall(ffi.new, "SDL_DisplayMode")
  ffiState = ok and ffi or false
  return ffiState or nil
end

local function sdlHz()
  local ffi = sdlFfi()
  if not ffi then return nil end
  local ok, hz = pcall(function()
    local index = 0
    local window = ffi.C.SDL_GL_GetCurrentWindow()
    if window ~= nil then
      local got = ffi.C.SDL_GetWindowDisplayIndex(window)
      if got >= 0 then index = got end
    end
    local mode = ffi.new("SDL_DisplayMode")
    if ffi.C.SDL_GetCurrentDisplayMode(index, mode) ~= 0 then return nil end
    return tonumber(mode.refresh_rate)
  end)
  if not ok or not hz or hz <= 0 then return nil end
  return hz
end

local SAMPLES = 31
local ring, cursor, filled = {}, 0, 0
local measured = nil

local function quantize(hz)
  if not hz or hz <= 0 then return nil end
  local whole = math.floor(hz + 0.5)
  local nearest = math.floor(whole / 60 + 0.5) * 60
  if nearest > 0 and math.abs(whole - nearest) <= 1 then return nearest end
  return whole
end

local function median(values)
  local sorted = {}
  for i = 1, #values do sorted[i] = values[i] end
  table.sort(sorted)
  local mid = sorted[math.floor(#sorted / 2) + 1]
  local lo = sorted[math.floor(#sorted * 0.25) + 1]
  local hi = sorted[math.floor(#sorted * 0.75) + 1]
  if not mid or mid <= 0 or (hi - lo) > mid * 0.1 then return nil end
  return mid
end

function RefreshRate.sample(dt)
  if type(dt) ~= "number" or dt <= 0 or dt > 0.2 then return false end
  cursor = cursor % SAMPLES + 1
  ring[cursor] = dt
  filled = math.min(filled + 1, SAMPLES)
  if filled < SAMPLES or cursor ~= SAMPLES then return false end
  local period = median(ring)
  if not period then return false end
  local hz = quantize(1 / period)
  if not hz or measured == hz then return false end
  measured = hz
  return true
end

local queried, queriedAt = nil, nil

local function now()
  if love and love.timer and love.timer.getTime then return love.timer.getTime() end
  return nil
end

function RefreshRate.hz()
  local time = now()
  if queried == nil or not time or not queriedAt or time - queriedAt > 1 then
    queried = sdlHz() or false
    queriedAt = time or 0
  end
  local hz = quantize(queried or measured)
  if not hz or hz <= 20 or hz >= 1000 then return nil end
  return hz
end

function RefreshRate.period()
  local hz = RefreshRate.hz()
  return hz and 1 / hz or nil
end

function RefreshRate.mismatch()
  local hz = RefreshRate.hz()
  if not hz then return nil end
  local nearest = math.floor(hz / 60 + 0.5) * 60
  if math.abs(hz - nearest) <= 1 then return nil end
  return hz
end

function RefreshRate.reset()
  ffiState, queried, queriedAt, measured = nil, nil, nil, nil
  ring, cursor, filled = {}, 0, 0
end

return RefreshRate
