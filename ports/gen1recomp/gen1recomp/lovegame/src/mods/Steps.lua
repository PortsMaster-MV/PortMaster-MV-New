-- The scoped seam for the native step bridge (#1186).
--
-- The iOS/Android builds count the player's real-world steps natively
-- (#452, #489) and deliver them by writing steps_pending.json into the
-- save-directory root.  Before the sandbox, the Pokéwalker mod called
-- love.system.syncHealthSteps() and consumed that file itself; the sandbox
-- blocks both, which is correct -- love.system launches URLs and the file
-- API names paths -- but it left the bridge with no consumer at all.
--
-- This module is the narrow replacement, gated by the "steps" permission
-- in manifest.json (the network model: a permission the player sees that
-- genuinely gates a capability).  The engine owns the file: mods never
-- learn its name or location, they receive only the three contract fields
-- ({ steps, from, to }), each permissioned mod gets its own copy, and the
-- merge-don't-overwrite anchor semantics stay on the native side where
-- they always lived.
--
-- No frame pump: the file is looked for lazily when a mod polls, so a
-- build with no permissioned mod installed never touches the bridge or
-- the disk.

local Json = require("src.link.Json")

local Steps = {}

-- The native contract's drop point, in the save-directory root (see
-- mobile/ios and mobile/android step bridges).
Steps.PENDING = "steps_pending.json"

local function bridge()
  return _G.love and _G.love.system and _G.love.system.syncHealthSteps
end

-- Whether this build carries the native bridge.  Desktop builds do not;
-- a mod uses this to stay dormant without probing love.system.
function Steps.available()
  return bridge() ~= nil
end

-- Ask the native side to refresh its count.  Async: the result lands in
-- the pending file and comes back through a later poll.  The platform's
-- own consent sheet (HealthKit / ACTIVITY_RECOGNITION) still appears on
-- first use, exactly as it did pre-sandbox.  false when there is no
-- bridge to ask.
function Steps.sync()
  local fn = bridge()
  if not fn then return false end
  fn()
  return true
end

-- Consume the pending file, if one has appeared, and fan its payload out
-- to every permissioned mod's queue.  Only the contract fields travel;
-- anything else in the file stays in the file's grave.  A malformed or
-- empty delivery is dropped whole -- the native anchor only advances on a
-- successful sync, so nothing is lost to a bad write.
function Steps.pump(loader)
  local fs = _G.love and _G.love.filesystem
  if not (fs and fs.getInfo(Steps.PENDING, "file")) then return end
  local raw = fs.read(Steps.PENDING)
  fs.remove(Steps.PENDING)
  if not raw then return end
  local ok, decoded = pcall(Json.decode, raw)
  if not ok or type(decoded) ~= "table" then return end
  local steps = tonumber(decoded.steps)
  if not steps or steps <= 0 then return end
  local payload = { steps = steps, from = decoded.from, to = decoded.to }
  for _, queue in pairs(loader.stepsQueues) do
    queue[#queue + 1] = { steps = payload.steps, from = payload.from,
                          to = payload.to }
  end
end

-- The next delivery for this mod, or nil.  Each permissioned mod consumes
-- its own queue, so two mods both see the same walk (pre-sandbox, whoever
-- read the file first won).
function Steps.poll(loader, modId)
  Steps.pump(loader)
  local queue = loader.stepsQueues[modId]
  if not queue then return nil end
  return table.remove(queue, 1)
end

return Steps
