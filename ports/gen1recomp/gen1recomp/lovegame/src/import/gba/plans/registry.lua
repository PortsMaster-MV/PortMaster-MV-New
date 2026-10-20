local GameVersion = require("src.core.GameVersion")

local Plans = {}

function Plans.of(version)
  if version == "ruby" or version == "sapphire" then
    return require("src.import.gba.plans.rs")
  end
  local layout = GameVersion.layout(version)
  if type(layout) ~= "string" then
    error("import plan: '" .. tostring(version) .. "' has no gba layout", 2)
  end
  return require("src.import.gba.plans." .. layout)
end

local function add(list, seen, module)
  if type(module) == "string" and module ~= "" and not seen[module] then
    seen[module] = true
    list[#list + 1] = module
  end
end

function Plans.moduleFor(name)
  if name:find(".", 1, true) then return name end
  return "src.import.gba." .. name
end

function Plans.modules(plan)
  local list, seen = {}, {}
  for _, task in ipairs(plan.tasks or {}) do
    for _, step in ipairs(task.steps or {}) do
      add(list, seen, Plans.moduleFor(step.name or step.module))
    end
  end
  for _, module in ipairs(plan.pokemonAfter or {}) do add(list, seen, Plans.moduleFor(module)) end
  for _, entry in ipairs(plan.aux or {}) do add(list, seen, Plans.moduleFor(entry.name)) end
  return list
end

function Plans.required(plan, cacheRoot)
  local out, seen = {}, {}
  for _, module in ipairs(Plans.modules(plan)) do
    local mod = require(module)
    local required = type(mod) == "table" and
      (mod.requiredForPlan and mod.requiredForPlan(plan.id) or mod.REQUIRED) or {}
    for _, rel in ipairs(required or {}) do
      local path = rel
      if not (rel:match("^data/") or rel:match("^assets/")) then
        path = cacheRoot .. "/" .. rel
      end
      if not seen[path] then
        seen[path] = true
        out[#out + 1] = path
      end
    end
  end
  return out
end

return Plans
