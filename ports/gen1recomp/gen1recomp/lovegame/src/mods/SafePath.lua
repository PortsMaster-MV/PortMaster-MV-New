-- One relative-path grammar for every path a mod supplies: a mod names files
-- inside its own directory and nowhere else.  love.filesystem (PhysFS) already
-- refuses "..", absolute paths and backslashes, but Loader.new takes an
-- injected fs that has no such floor, so the rule lives here and not in
-- whichever filesystem happens to be underneath.
local SafePath = {}

-- The normalized path, or nil when it could climb out of the root it is about
-- to be joined to.  "." segments are dropped rather than rejected so a
-- manifest that says "./main.lua" still loads.
function SafePath.safe(rel)
  if type(rel) ~= "string" or rel == "" then return nil end
  if rel:sub(1, 1) == "/" then return nil end
  if rel:find("\\", 1, true) then return nil end
  if rel:match("^%a:") then return nil end -- windows drive-relative
  local parts = {}
  for segment in rel:gmatch("[^/]+") do
    if segment == ".." then return nil end
    if segment ~= "." then parts[#parts + 1] = segment end
  end
  if #parts == 0 then return nil end
  return table.concat(parts, "/")
end

function SafePath.require(rel, what)
  local safe = SafePath.safe(rel)
  if not safe then
    error(("%s must stay inside its root, got %q"):format(what, tostring(rel)), 0)
  end
  return safe
end

-- root .. "/" .. rel, with the traversal check in between
function SafePath.join(root, rel, what)
  return root .. "/" .. SafePath.require(rel, what or "path")
end

return SafePath
