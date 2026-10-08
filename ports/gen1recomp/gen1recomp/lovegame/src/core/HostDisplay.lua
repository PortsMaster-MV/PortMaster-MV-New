-- Optional native-host display lifecycle.
--
-- The engine always owns simulation and drawing. A packaged host may install
-- one backend to observe per-frame updates and prepare/finalize a render target
-- around an otherwise unchanged draw. With no backend installed every method
-- is a no-op, which is the normal desktop and mobile path.
--
-- Backend methods are optional:
--   backend:update(dt)
--   backend:beginFrame(kind, subject)
--   backend:endFrame(kind, subject)
--
-- `kind` is "editor", "touch_editor", "launcher", or "game". `subject` is
-- the object whose existing draw method runs between beginFrame and endFrame.
local HostDisplay = {}

local backend

function HostDisplay.setBackend(value)
  if value ~= nil and type(value) ~= "table" then
    error("host display backend must be a table or nil", 2)
  end
  backend = value
end

function HostDisplay.update(dt)
  local fn = backend and backend.update
  if fn then return fn(backend, dt) end
end

function HostDisplay.beginFrame(kind, subject)
  local fn = backend and backend.beginFrame
  if fn then return fn(backend, kind, subject) end
end

function HostDisplay.endFrame(kind, subject)
  local fn = backend and backend.endFrame
  if fn then return fn(backend, kind, subject) end
end

return HostDisplay
