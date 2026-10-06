-- Game state stack.  The top state updates; all states draw bottom-up
-- (so a text box can overlay the overworld, a battle replaces it, etc).
-- States are tables with optional enter/exit/update/draw/isOpaque.

local Runtime = require("src.mods.Runtime")

local StateStack = {}

function StateStack:init()
  self.states = {}
end

-- screen.pushed/popped fire after enter/exit so listeners observe the
-- settled state; the wants guard keeps the no-listener path allocation-free

-- enter/exit are OPTIONAL callbacks, so the test is "is it callable", not "is
-- it there".  A state is an ordinary table and `exit` is an ordinary word: the
-- Gen 2 GameFreak screen counts its 16-frame exit tail in a field, and under a
-- truthiness test the stack called into a number and took the process down at
-- a screen hand-off.  Reserving the names is still the contract (see
-- src/ui/gen2/GameFreakPresents.lua's exitTail), but the stack does not need
-- to be the thing that enforces it by crashing.
local function callback(state, name)
  local fn = state and state[name]
  return type(fn) == "function" and fn or nil
end

function StateStack:push(state, ...)
  table.insert(self.states, state)
  local enter = callback(state, "enter")
  if enter then enter(state, ...) end
  if Runtime.wants("screen.pushed") then
    Runtime.emit("screen.pushed", { state = state })
  end
end

function StateStack:pop()
  local state = table.remove(self.states)
  local exit = callback(state, "exit")
  if exit then exit(state) end
  if state and Runtime.wants("screen.popped") then
    Runtime.emit("screen.popped", { state = state })
  end
  return state
end

function StateStack:top()
  return self.states[#self.states]
end

-- Tear the whole stack down top-first, so every state still gets its exit and
-- every listener still sees screen.popped in the order it would have on a
-- hand-written unwind.  Gold's boot cinema hands off between screens this way
-- (title -> intro menu -> Oak) and the Gen 1 paths that did
-- `while self.stack:top() do self.stack:pop() end` mean exactly this.
function StateStack:clear()
  while self:top() do self:pop() end
end

function StateStack:update(dt)
  local top = self:top()
  if top and top.update then top:update(dt) end
end

local function visibleByDefault() return true end

-- A mod may mirror a state elsewhere and hide only its main-screen render.
-- The state stays on the stack, so update and input ownership do not move.
function StateStack:renderVisible(state)
  if not state then return false end
  if not Runtime.wantsHook("screen.render_visible") then return true end
  return Runtime.call("screen.render_visible", visibleByDefault, state) ~= false
end

-- index of the lowest state drawn this frame (highest opaque, else 1)
function StateStack:visibleBase()
  for i = #self.states, 1, -1 do
    local state = self.states[i]
    if self:renderVisible(state) and state.isOpaque then return i end
  end
  return 1
end

function StateStack:draw()
  for i = self:visibleBase(), #self.states do
    local state = self.states[i]
    if self:renderVisible(state) and state.draw then state:draw() end
  end
end

return StateStack
