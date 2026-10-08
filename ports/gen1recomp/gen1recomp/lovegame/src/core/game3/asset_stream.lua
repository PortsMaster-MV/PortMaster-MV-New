-- One CPU worker, bounded decoded residency, and a shared upload budget.
local Decode = require("src.core.game3.asset_decode")
local Stream = {}
Stream.UPLOAD_BUDGET = .002
Stream.MAX_DECODED = 4
Stream.MAX_PENDING = 64
local queue, jobs, serial = {}, {}, 0
local thread, input, output, active
local function cancel(job)
  job.cancelled = true
  if job.cancelSignal then job.cancelSignal:push(true) end
end
local clock = function() return love and love.timer and love.timer.getTime() or os.clock() end
local function record(job, phase, seconds, route)
  if Stream.onTiming then Stream.onTiming(job.kind, job.key, phase, seconds, route) end
  if os.getenv("POKEPORT_ASSET_PROFILE") == "1" then
    print(string.format("[game3/asset] %s=%s %s=%.3fms route=%s", job.kind, job.key, phase, seconds * 1000, route))
  end
end
local function startWorker()
  if thread then return true end
  if not (love and love.thread and love.thread.newThread and love.thread.newChannel) then return false end
  local ok, value = pcall(love.thread.newThread, "src/core/game3/asset_worker.lua")
  if not ok then return false end
  input, output = love.thread.newChannel(), love.thread.newChannel()
  local started = pcall(value.start, value, input, output)
  if not started then return false end
  thread = value
  return true
end
function Stream.shutdown()
  Stream.cancelPending()
  if thread then
    input:clear(); input:push({ stop = true }); thread:wait()
  end
  thread, input, output, active = nil, nil, nil, nil
  queue, jobs = {}, {}
  Stream._uploadedThisFrame = false
  Stream.workerFailed = false
end
function Stream.cancelPending()
  for _, job in pairs(jobs) do
    cancel(job)
    job.owner.pending[job.key] = nil
  end
  jobs = {}
end
function Stream.frameComplete() Stream._uploadedThisFrame = false end
local Lifecycle = require("src.core.SessionLifecycle")
if not Lifecycle._game3AssetShutdownRegistered then
  Lifecycle._game3AssetShutdownRegistered = true
  Lifecycle.registerProcessShutdown(function()
    local current = package.loaded["src.core.game3.asset_stream"]
    if current then current.shutdown() end
  end)
end

function Stream.new(kind, cache, root, upload, publish)
  local s = { kind = kind, cache = cache, root = root, upload = upload, publish = publish, pending = {} }
  function s:cancel()
    self.cancelled = true
    for _, job in pairs(self.pending) do cancel(job); jobs[job.id] = nil end
    self.pending = {}
  end
  function s:decoded(key)
    local job = self.pending[key]
    return job and job.data ~= nil
  end
  function s:retain(wanted)
    for key, job in pairs(self.pending) do
      if not wanted[key] then
        cancel(job); jobs[job.id], self.pending[key] = nil, nil
      end
    end
  end
  function s:prefetch(key, priority)
    if self.cancelled then return end
    if self.pending[key] then self.pending[key].priority = priority or self.pending[key].priority; return end
    local count = 0
    for _ in pairs(self.pending) do count = count + 1 end
    if count >= Stream.MAX_PENDING then return end
    serial = serial + 1
    local spec = self.cache and self.cache.assetWorkerSpec and self.cache:assetWorkerSpec(root, kind, key)
    local job = { id = serial, kind = kind, key = key, root = root, owner = self, spec = spec, priority = priority or 1 }
    self.pending[key], jobs[serial] = job, job
    queue[#queue + 1] = job
  end
  function s:get(key)
    Stream.poll()
    local job = self.pending[key]
    local data = job and job.data
    if not data then
      if job and job.cancelSignal then job.cancelSignal:push(true) end
      local start = clock()
      local err
      data, err = Decode[kind](cache, root, key)
      record({ kind = kind, key = key }, "decode", clock() - start, "sync")
      if not data then return nil, err end
    end
    local start = clock()
    local co = job and job.co or coroutine.create(function() return upload(data) end)
    local value
    repeat
      local ok, res = coroutine.resume(co)
      if not ok then
        if job then job.cancelled = true; jobs[job.id] = nil; self.pending[key] = nil end
        return nil, tostring(res)
      end
      value = res
    until coroutine.status(co) == "dead"
    if job then job.cancelled = true; jobs[job.id] = nil; self.pending[key] = nil end
    publish(key, value)
    record({ kind = kind, key = key }, "upload", clock() - start, data == (job and job.data) and "decoded" or "sync")
    return value
  end
  return s
end

-- CPU results are published on receipt, without consuming a graphics slice.
function Stream.newTask(kind, publish)
  local payloads = {}
  local cache = { assetWorkerSpec = function(_, _, _, key)
    return { task = true, payload = payloads[key] }
  end }
  local s = Stream.new(kind, cache, "", nil, function(key, data, err)
    payloads[key] = nil
    publish(key, data, err)
  end)
  function s:submit(key, payload, priority)
    payloads[key] = payload
    self:prefetch(key, priority)
    payloads[key] = nil
  end
  return s
end

function Stream.poll()
  if output then
    local result = output:pop()
    if result then
      if result.fatal then
        if active then active.spec, active.sent = nil, false end
        Stream.workerFailed, active = true, nil
        print("[game3/asset] worker unavailable: " .. tostring(result.fatal))
      end
      local job = jobs[result.id]
      if active and active.id == result.id then active = nil end
      if job and not job.cancelled then
        job.data, job.error, job.done = result.data, result.error, true
        record(job, "decode", result.seconds, "worker")
        if job.spec.task then
          job.owner.publish(job.key, job.data, job.error)
          job.owner.pending[job.key], jobs[job.id], job.cancelled = nil, nil, true
        end
      end
    end
  end
  if thread and thread:getError() then
    if active then active.spec, active.sent = nil, false end
    thread, input, output, active = nil, nil, nil, nil
    Stream.workerFailed = true
  end
  if active then return end
  local decoded = 0
  for _, job in ipairs(queue) do if not job.cancelled and job.data then decoded = decoded + 1 end end
  local nextJob
  for _, job in ipairs(queue) do
    if not job.cancelled and not job.done and job ~= active and not job.sent then
      if job.spec and (job.spec.task or decoded < Stream.MAX_DECODED)
          and (not nextJob or job.priority < nextJob.priority) then nextJob = job end
    end
  end
  if nextJob and not Stream.workerFailed and startWorker() then
    nextJob.sent, active = true, nextJob
    nextJob.cancelSignal = love.thread.newChannel()
    input:push({ id = nextJob.id, kind = nextJob.kind, key = nextJob.key, root = nextJob.root,
      spec = nextJob.spec, cancelSignal = nextJob.cancelSignal })
  end
  -- Unknown/custom caches prepare synchronously only when explicitly consumed.
end

function Stream.update()
  Stream.poll()
  if Stream._uploadedThisFrame then return end
  local start = clock()
  for i = #queue, 1, -1 do if queue[i].cancelled then table.remove(queue, i) end end
  local nextJob
  for _, job in ipairs(queue) do
    if job.data and (not nextJob or job.priority < nextJob.priority) then nextJob = job end
  end
  local job = nextJob
  if job then
      Stream._uploadedThisFrame = true
      if not job.co then job.co = coroutine.create(function() return job.owner.upload(job.data) end) end
      local t = clock()
      local ok, value = coroutine.resume(job.co)
      if not ok then
        job.error, job.done, job.data = tostring(value), true, nil
        job.co = nil
      elseif coroutine.status(job.co) == "dead" then
        job.owner.publish(job.key, value)
        job.owner.pending[job.key], jobs[job.id], job.cancelled = nil, nil, true
      end
      record(job, "upload_step", clock() - t, "warm")
      -- A texture upload (including animation catch-up on publication) is
      -- atomic. One coroutine slice per render frame prevents catch-up ticks
      -- and a second ready asset from silently exceeding the upload budget.
      if clock() - start > Stream.UPLOAD_BUDGET then Stream.lastOverBudget = clock() - start end
  end
end
return Stream
