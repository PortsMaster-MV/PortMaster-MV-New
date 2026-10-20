local Versions = require("src.import.gba.versions")

local MonAnimExtract = {}

MonAnimExtract.FORMAT_VERSION = 1
MonAnimExtract.FRONT_FILE = "pokemon/front_anims.lua"
MonAnimExtract.BACK_FILE = "pokemon/back_anims.lua"
MonAnimExtract.REQUIRED = { MonAnimExtract.FRONT_FILE, MonAnimExtract.BACK_FILE }
MonAnimExtract.MAX_CMDS = 64

local function need(key)
  local v = Versions[key]
  if v == nil then
    error("mon_anim_extract: Versions." .. key .. " is not set for " .. tostring(Versions.active()))
  end
  return v
end

local function syms()
  local S = Versions.SYMS
  if S == nil then
    S = require("src.import.gba.syms").of(Versions.active())
  end
  return S
end

local function named(S, off, prefix, obj)
  for _, n in ipairs(S.namesAt(off)) do
    local bare = n:match("[^:]+$")
    if bare:sub(1, #prefix) == prefix then
      local key = S.has(bare) and bare or (obj and obj .. ":" .. bare)
      if key and S.has(key) and S.off(key) == off then return bare, key end
    end
  end
  return nil
end

-- pokeemerald/include/sprite.h:74
function MonAnimExtract.decodeCmds(rom, off, maxCmds)
  local cmds = {}
  for i = 0, (maxCmds or MonAnimExtract.MAX_CMDS) - 1 do
    local lo = rom:u16(off + i * 4)
    local hi = rom:u16(off + i * 4 + 2)
    if lo == 0xFFFF then
      cmds[#cmds + 1] = { op = "end" }
      return cmds
    elseif lo == 0xFFFE then
      cmds[#cmds + 1] = { op = "jump", target = hi % 64 }
      return cmds
    elseif lo == 0xFFFD then
      cmds[#cmds + 1] = { op = "loop", count = hi % 64 }
    else
      cmds[#cmds + 1] = {
        frame = lo,
        duration = hi % 64,
        hFlip = math.floor(hi / 64) % 2 == 1,
        vFlip = math.floor(hi / 128) % 2 == 1,
      }
    end
  end
  error(string.format("mon_anim_extract: anim cmd list at 0x%X has no END/JUMP", off))
end

local function bytes(rom, base, count, first)
  local out = {}
  first = first or 0
  for i = 0, count - 1 do out[first + i] = rom:get(base + i) end
  return out
end

function MonAnimExtract.extract(rom)
  local S = syms()
  local tableOff = need("MON_FRONT_ANIMS_PTR_TABLE")
  local tableObj = Versions.MON_FRONT_ANIMS_OBJ
  local count = need("MON_FRONT_ANIMS_COUNT")
  local lists, listIndex, species = {}, {}, {}

  local function listId(off)
    local id = listIndex[off]
    if id then return id end
    id = #lists + 1
    listIndex[off] = id
    lists[id] = { name = named(S, off, "sAnim_", tableObj) or string.format("anim_%X", off),
      cmds = MonAnimExtract.decodeCmds(rom, off) }
    return id
  end

  for sp = 0, count - 1 do
    local arr = Versions.gbaToFile(rom:u32(tableOff + sp * 4))
    if arr then
      local name, full = named(S, arr, "sAnims_", tableObj)
      if not name then
        error(string.format("mon_anim_extract: species %d anim table at 0x%X has no sAnims_ symbol", sp, arr))
      end
      local n = S.size(full) / 4
      local ids = {}
      for i = 0, n - 1 do
        local cmdOff = Versions.gbaToFile(rom:u32(arr + i * 4))
        ids[i + 1] = cmdOff and listId(cmdOff) or 0
      end
      species[sp] = ids
    end
  end

  local fnCount = need("MON_ANIM_FUNCTIONS_COUNT")
  local fnBase = need("MON_ANIM_FUNCTIONS")
  local functions = {}
  for i = 0, fnCount - 1 do
    local ptr = rom:u32(fnBase + i * 4)
    local names = S.funcAt and S.funcAt(ptr)
    local fname = type(names) == "table" and names[1] or names
    functions[i] = fname or string.format("func_%X", ptr)
  end

  return {
    lists = lists,
    species = species,
    count = count,
    animIds = bytes(rom, need("MON_FRONT_ANIM_IDS"), need("MON_FRONT_ANIM_IDS_COUNT"), 1),
    animDelays = bytes(rom, need("MON_ANIMATION_DELAYS"), need("MON_ANIMATION_DELAYS_COUNT"), 1),
    functions = functions,
    backSets = bytes(rom, need("MON_BACK_ANIM_SETS"), need("MON_BACK_ANIM_SETS_COUNT")),
    backIds = bytes(rom, need("MON_BACK_ANIM_IDS"), need("MON_BACK_ANIM_IDS_COUNT")),
    backNatureMods = bytes(rom, need("MON_BACK_NATURE_MODS"), need("MON_BACK_NATURE_MODS_COUNT")),
  }
end

local function cmd_lua(c)
  if c.op == "end" then return "{ op = \"end\" }" end
  if c.op == "jump" then return string.format("{ op = \"jump\", target = %d }", c.target) end
  if c.op == "loop" then return string.format("{ op = \"loop\", count = %d }", c.count) end
  local flags = ""
  if c.hFlip then flags = flags .. ", hFlip = true" end
  if c.vFlip then flags = flags .. ", vFlip = true" end
  return string.format("{ frame = %d, duration = %d%s }", c.frame, c.duration, flags)
end

local function byte_list(lines, key, t, n, first)
  first = first or 0
  local row = {}
  for i = first, first + n - 1 do row[#row + 1] = tostring(t[i] or 0) end
  local head = first == 1 and "" or string.format("[%d] = ", first)
  lines[#lines + 1] = string.format("  %s = { %s%s },", key, head, table.concat(row, ", "))
end

function MonAnimExtract.frontLua(pack)
  local lines = {
    "return {",
    string.format("  format = %d,", MonAnimExtract.FORMAT_VERSION),
    string.format("  count = %d,", pack.count),
    "  lists = {",
  }
  for id, l in ipairs(pack.lists) do
    local cmds = {}
    for i, c in ipairs(l.cmds) do cmds[i] = cmd_lua(c) end
    lines[#lines + 1] = string.format("    [%d] = { name = %q, cmds = { %s } },", id, l.name, table.concat(cmds, ", "))
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "  species = {"
  for sp = 0, pack.count - 1 do
    if pack.species[sp] then
      lines[#lines + 1] = string.format("    [%d] = { %s },", sp, table.concat(pack.species[sp], ", "))
    end
  end
  lines[#lines + 1] = "  },"
  local n = 0
  for _ in pairs(pack.animIds) do n = n + 1 end
  byte_list(lines, "animIds", pack.animIds, n, 1)
  byte_list(lines, "animDelays", pack.animDelays, n, 1)
  lines[#lines + 1] = "  functions = {"
  for i = 0, #pack.functions do
    lines[#lines + 1] = string.format("    [%d] = %q,", i, pack.functions[i])
  end
  lines[#lines + 1] = "  },"
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

local function count_of(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

function MonAnimExtract.backLua(pack)
  local lines = {
    "return {",
    string.format("  format = %d,", MonAnimExtract.FORMAT_VERSION),
  }
  byte_list(lines, "sets", pack.backSets, count_of(pack.backSets))
  byte_list(lines, "ids", pack.backIds, count_of(pack.backIds))
  byte_list(lines, "natureMods", pack.backNatureMods, count_of(pack.backNatureMods))
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

function MonAnimExtract.run(rom, cache, opts)
  opts = opts or {}
  local root = opts.cacheRoot or "data/generated/gba"
  local pack = MonAnimExtract.extract(rom)
  for rel, body in pairs({ [MonAnimExtract.FRONT_FILE] = MonAnimExtract.frontLua(pack),
      [MonAnimExtract.BACK_FILE] = MonAnimExtract.backLua(pack) }) do
    local ok, err = cache:write(root .. "/" .. rel, body)
    if ok == false then error("mon_anim_extract: could not write " .. rel .. ": " .. tostring(err)) end
  end
  return { lists = #pack.lists, count = pack.count }
end

function MonAnimExtract.ready(cache, cacheRoot)
  if not (cache and cache.read) then return false end
  local root = cacheRoot or "data/generated/gba"
  for _, rel in ipairs(MonAnimExtract.REQUIRED) do
    local body = cache:read(root .. "/" .. rel)
    if type(body) ~= "string" or tonumber(body:match("format = (%d+)")) ~= MonAnimExtract.FORMAT_VERSION then
      return false
    end
  end
  return true
end

return MonAnimExtract
