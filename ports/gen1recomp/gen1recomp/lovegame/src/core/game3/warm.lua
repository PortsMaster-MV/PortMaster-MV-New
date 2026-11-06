local Warm = {}
Warm.BUDGET = 0.002

local jobs, order = {}, {}
local clock = function() return love and love.timer and love.timer.getTime() or os.clock() end

function Warm.add(key, fn, priority)
  if jobs[key] then
    if priority and priority < jobs[key].priority then jobs[key].priority = priority end
    return false
  end
  local job = { key = key, fn = fn, priority = priority or 5 }
  jobs[key] = job
  order[#order + 1] = job
  return true
end

function Warm.pending(key) return jobs[key] ~= nil end

local function finish(job)
  jobs[job.key] = nil
  for i = #order, 1, -1 do
    if order[i] == job then table.remove(order, i) break end
  end
end

local function resume(job)
  if not job.co then job.co = coroutine.create(job.fn) end
  local ok, err = coroutine.resume(job.co)
  if not ok then
    print("[game3/warm] " .. tostring(job.key) .. ": " .. tostring(err))
    finish(job)
  elseif coroutine.status(job.co) == "dead" then
    finish(job)
  end
end

function Warm.flush(key)
  local job = jobs[key]
  if not job or (job.co and job.co == coroutine.running()) then return false end
  job.flushing = true
  while jobs[key] == job do resume(job) end
  return true
end

function Warm.step(budget)
  if #order == 0 then return end
  local deadline = clock() + (budget or Warm.BUDGET)
  repeat
    local best
    for _, job in ipairs(order) do
      if not best or job.priority < best.priority then best = job end
    end
    if not best then return end
    resume(best)
  until clock() >= deadline
end

function Warm.require(names, priority)
  for _, name in ipairs(names) do
    if not package.loaded[name] then
      Warm.add("mod:" .. name, function() pcall(require, name) end, priority or 8)
    end
  end
end

function Warm.yield()
  local co, main = coroutine.running()
  if co and not main then
    for _, job in pairs(jobs) do
      if job.co == co then
        if not job.flushing then coroutine.yield() end
        return
      end
    end
  end
end

function Warm.reset()
  jobs, order = {}, {}
end

return Warm
