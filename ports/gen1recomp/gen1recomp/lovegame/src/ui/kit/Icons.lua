-- Lucide ISC/Feather MIT icons, rasterized offline into one shared texture.
local Icons = {}
local names = {
  "settings",
  "x",
  "arrow-left-right",
  "puzzle",
  "search",
  "globe",
  "paintbrush",
  "download",
  "pencil",
  "folder",
  "upload",
  "file-pen-line",
  "trash",
  "check",
  "chevron-right",
  "lock",
  "lock-open",
  "mail",
}
local editorNames = {
  "chevron-left",
  "chevron-up",
  "chevron-down",
  "plus",
  "minus",
  "undo-2",
  "redo-2",
  "save",
  "rotate-ccw",
  "ellipsis",
  "copy",
  "heart",
  "package",
  "backpack",
  "list-filter",
  "arrow-up",
  "arrow-down",
  "arrow-left",
  "arrow-right",
  "arrow-up-down",
  "eye",
  "award",
  "book-open",
  "shield-check",
  "map-pin",
  "grid-2x2",
  "sliders-horizontal",
  "expand",
  "chevrons-up",
  "users",
  "user-round",
  "wallet",
  "flag",
}
local atlases = {
  { path = "assets/launcher/lucide/icons.png", names = names },
  { path = "assets/launcher/lucide/editor.png", names = editorNames },
}
local cells = {}
Icons.NAMES = {}
for _, atlas in ipairs(atlases) do
  for i, name in ipairs(atlas.names) do
    Icons.NAMES[#Icons.NAMES + 1] = name
    cells[name] = { atlas = atlas, index = i }
  end
end

Icons.NAMES[#Icons.NAMES + 1] = "triangle-alert"
function Icons.has(name)
  return name == "triangle-alert" or cells[name] ~= nil
end

function Icons.draw(name, x, y, size, color, alpha)
  local g = love and love.graphics
  if g and name == "triangle-alert" then
    g.push("all")
    g.setColor(color[1] / 255, color[2] / 255, color[3] / 255, alpha or 1)
    g.setLineWidth(math.max(1, size * 0.075))
    g.polygon("line", x + size * 0.5, y + size * 0.1,
      x + size * 0.08, y + size * 0.88, x + size * 0.92, y + size * 0.88)
    g.line(x + size * 0.5, y + size * 0.35, x + size * 0.5, y + size * 0.59)
    g.circle("fill", x + size * 0.5, y + size * 0.74, size * 0.045)
    g.pop()
    return
  end
  if not g or not g.newQuad or not g.newImage then
    return
  end
  local cell = cells[name]
  if not cell then
    return
  end
  local atlas = cell.atlas
  if not atlas.image then
    atlas.image = g.newImage(atlas.path)
    if atlas.image.setFilter then
      atlas.image:setFilter("linear", "linear")
    end
    atlas.quads = {}
    for i, id in ipairs(atlas.names) do
      atlas.quads[id] = g.newQuad((i - 1) * 96, 0, 96, 96, #atlas.names * 96, 96)
    end
  end
  local quad = atlas.quads[name]
  if not quad then
    return
  end
  g.setColor(color[1] / 255, color[2] / 255, color[3] / 255, alpha or 1)
  g.draw(atlas.image, quad, x, y, 0, size / 96, size / 96)
end

return Icons
