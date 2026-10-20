-- Extractor for GBA Multichoice list strings and tables (gMultichoiceLists).

local Versions = require("src.import.gba.versions")
local TextIR = require("src.core.game3.scripting.text_ir")

local MultichoiceExtract = {}

local ROM_BASE, ROM_END = 0x08000000, 0x0A000000
local MAX_LABEL_BYTES = 64

local function read_label_bytes(rom, off)
  local bytes = {}
  for i = 0, MAX_LABEL_BYTES - 1 do
    local b = rom:get(off + i)
    bytes[#bytes + 1] = b
    if b == 0xFF then break end
  end
  return bytes
end

local SEG_TEXT = {
  nl = " ", para = " ", scroll = " ",
  player = "{PLAYER}", rival = "{RIVAL}",
}

function MultichoiceExtract.label(bytes, dialect)
  local parts = {}
  for _, seg in ipairs(TextIR.decode(bytes, { dialect = dialect })) do
    if seg.t == "eos" then break end
    if seg.t == "text" then
      parts[#parts + 1] = seg.s
    elseif seg.t == "tag" then
      parts[#parts + 1] = seg.tag
    elseif seg.t == "strvar" then
      parts[#parts + 1] = "{STR_VAR_" .. seg.n .. "}"
    elseif seg.t == "ext" and seg.cmd == 0x13 then
      parts[#parts + 1] = "  "
    elseif SEG_TEXT[seg.t] then
      parts[#parts + 1] = SEG_TEXT[seg.t]
    end
  end
  return (table.concat(parts):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function rom_off(ptr)
  if ptr >= ROM_BASE and ptr < ROM_END then return ptr - ROM_BASE end
  return nil
end

function MultichoiceExtract.extract(rom, opts)
  opts = opts or {}
  local base = assert(opts.base or Versions.MULTICHOICE_LISTS, "multichoice: no MULTICHOICE_LISTS for this ROM")
  local totalCount = assert(opts.count or Versions.MULTICHOICE_COUNT, "multichoice: no MULTICHOICE_COUNT for this ROM")
  local dialect = opts.dialect or TextIR.dialectOf()

  local lists = {}
  for i = 0, totalCount - 1 do
    local off = base + i * 8
    local listOff = rom_off(rom:u32(off))
    local count = rom:get(off + 4)
    local labels = {}
    if listOff and count > 0 and count <= 30 then
      for a = 0, count - 1 do
        local textOff = rom_off(rom:u32(listOff + a * 8))
        local s = ""
        if textOff then
          s = MultichoiceExtract.label(read_label_bytes(rom, textOff), dialect)
        end
        table.insert(labels, s)
      end
    end
    lists[i] = { count = #labels, labels = labels }
  end
  return lists
end

local function source_label()
  local F = require("src.import.gba.family").active()
  if F.aliases then return "FRLG" end
  return require("src.core.game3.profile").of(F.game).label
end

function MultichoiceExtract.formatLua(lists)
  local lines = {
    "-- Auto-generated " .. source_label() .. " Multichoice Lists from ROM gMultichoiceLists. DO NOT EDIT DIRECTLY.",
    "return {",
  }
  for i = 0, #lists do
    local item = lists[i]
    if item and item.labels then
      local quoted = {}
      for _, s in ipairs(item.labels) do
        table.insert(quoted, string.format("%q", s))
      end
      lines[#lines + 1] = string.format("  [%d] = { count = %d, labels = { %s } },", i, #item.labels, table.concat(quoted, ", "))
    end
  end
  lines[#lines + 1] = "}"
  lines[#lines + 1] = ""
  return table.concat(lines, "\n")
end

MultichoiceExtract.CACHE_REL = "scripts/multichoice.lua"
MultichoiceExtract.REQUIRED = { MultichoiceExtract.CACHE_REL }

local function multichoice_path(cacheRoot)
  return (cacheRoot or "data/generated/gba") .. "/" .. MultichoiceExtract.CACHE_REL
end

function MultichoiceExtract.ready(cache, cacheRoot)
  local rel = multichoice_path(cacheRoot)
  if cache and cache.read then
    local data = cache:read(rel)
    return (data ~= nil and #data > 40 and data:find("labels", 1, true) ~= nil)
  end
  if cache and cache.exists then
    return cache:exists(rel) and true or false
  end
  return false
end

function MultichoiceExtract.run(rom, cache, opts)
  opts = opts or {}
  local lists = MultichoiceExtract.extract(rom)
  local content = MultichoiceExtract.formatLua(lists)
  local rel = multichoice_path(opts.cacheRoot)

  local wrote, err = false, nil
  if cache and cache.write then
    local ok, werr = cache:write(rel, content)
    if ok == false then err = werr else wrote = true end
  end
  if not wrote then
    local okC, CacheFs = pcall(require, "src.import.CacheFs")
    if okC and CacheFs and CacheFs.write then
      local ok, werr = pcall(CacheFs.write, rel, content)
      if ok then wrote = true else err = err or werr end
    end
  end
  if not wrote and love and love.filesystem and love.filesystem.write then
    local ok, werr = pcall(love.filesystem.write, rel, content)
    if ok then wrote = true else err = err or werr end
  end
  if not wrote then
    error("multichoice: could not write " .. rel .. ": " .. tostring(err))
  end

  local n = 0
  for _, entry in pairs(lists) do
    if entry and entry.count and entry.count > 0 then n = n + 1 end
  end
  return { path = rel, listCount = n }
end

return MultichoiceExtract
