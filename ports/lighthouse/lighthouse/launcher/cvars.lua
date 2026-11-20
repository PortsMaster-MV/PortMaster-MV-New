-- Shared copy: recipes/templates/includes/launcher/
-- Launcher config for HarbourMasters ports whose settings are plain CVars (SpaghettiKart,
-- Ship of Harkinian 2). A port's launcher/config.lua is:
--   return require("cvars")({
--       title = "...", subtitle = "...", help = "...",
--       items = { { id = "fps", ... }, ..., "filter", "loglevel", "resolution" },
--                                   -- "filter": texture filter (default linear), "loglevel": log
--                                   -- level (gDeveloperTools.LogLevel, default warnings),
--                                   -- "resolution": aspect ratio items
--       keys = { fps = { { "gInterpolationFPS" }, 30 }, ... }, -- id -> CVar path below "CVars", default
--       forced = { { { "gControlNav" }, 1 }, ... },             -- always written on save
--       o2r = { "game.o2r", ... },  -- optional: on <=1GB devices with none of these next to
--                                   -- the config yet, warn to answer No after the rom conversion
--       resolution = { "gSettings", "AdvancedResolution" },  -- optional: where the aspect ratio
--                                   -- CVars live (default { "gAdvancedResolution" })
--       custom = { 720, 600 },      -- optional: default Custom aspect ratio (720 x 640 otherwise)
--       filter = { "gSettings", "TextureFilter" },  -- optional: texture filter CVar path
--                                   -- (default { "gTextureFilter" })
--   })
-- anchor.lua uses it too, for the items it doesn't handle itself.
-- Edits the game's JSON config line by line; the game writes it pretty-printed (one key per
-- line), so no JSON parser is needed.

-- Aspect ratio presets as in the game's Graphics menu (ResolutionEditor.cpp); the index is
-- gAdvancedResolution.UIComboItem.AspectRatio. "Off" sets X/Y to 0 (fill the screen);
-- Custom ([1]) uses the customX/customY items, 720 x 640 by default.
local ASPECTS = {
    [0] = { 0, 0 }, [1] = { 720, 640 }, [2] = { 4, 3 }, [3] = { 16, 9 }, [4] = { 5, 3 },
    [5] = { 16, 10 }, [6] = { 21, 9 },
}

local RESOLUTION_ITEMS = {
    { id = "advres", label = "Advanced resolution", kind = "choice",
      choices = { { 1, "On" }, { 0, "Off" } },
      help = "Enables the aspect ratio setting below (game menu: Graphics, Enable advanced settings)." },
    { id = "aspect", label = "Aspect ratio", kind = "choice",
      choices = { { 0, "Off" }, { 1, "Custom" }, { 2, "Original (4:3)" }, { 3, "Widescreen (16:9)" },
                  { 4, "Nintendo 3DS (5:3)" }, { 5, "16:10 (8:5)" }, { 6, "Ultrawide (21:9)" } },
      help = "Off fills the screen. Custom: set the ratio below (720 x 720 is square)." },
    { id = "customX", label = "   Custom X", kind = "number", min = 1, max = 9999,
      visible = function(v) return v.aspect == 1 end,
      help = "Width part of the custom aspect ratio, e.g. 720 for 720 x 720." },
    { id = "customY", label = "   Custom Y", kind = "number", min = 1, max = 9999,
      visible = function(v) return v.aspect == 1 end,
      help = "Height part of the custom aspect ratio, e.g. 720 for 720 x 720." },
}
-- Texture filter (libultraship FilteringMode: 0 three-point, 1 linear, 2 none). Linear is one
-- hardware texture read; three-point is done in the shader and costs more GPU.
local FILTER_ITEM = { id = "filter", label = "Texture filter", kind = "choice",
    choices = { { 1, "Linear" }, { 0, "Three-point" }, { 2, "None (pixelated)" } },
    help = "Linear is smooth and fast. Three-point looks like the N64 but costs more GPU." }
-- spdlog levels; the games default to info or debug, which fills log.txt
local LOGLEVEL_ITEM = { id = "loglevel", label = "Log level", kind = "choice",
    choices = { { 3, "Warnings" }, { 4, "Errors" }, { 2, "Info" }, { 1, "Debug" }, { 6, "Off" } },
    help = "How much the game writes to log.txt. Info or Debug help when reporting a problem." }

-- CVar path below "CVars": base .. rest
local function path(base, ...)
    local p = {}
    for _, k in ipairs(base) do p[#p + 1] = k end
    for _, k in ipairs({ ... }) do p[#p + 1] = k end
    return p
end

local function readLines(path)
    local f = io.open(path, "r")
    if not f then return nil end
    local lines = {}
    for l in f:lines() do lines[#lines + 1] = l end
    f:close()
    return lines
end

-- RAM in GB, rounded like PortMaster's DEVICE_RAM
local function ramGB()
    local f = io.open("/proc/meminfo", "r")
    if not f then return nil end
    local kb = tonumber(f:read("*a"):match("MemTotal:%s*(%d+)"))
    f:close()
    return kb and math.floor(kb / 1048576 + 0.5)
end

local function anyExists(dir, files)
    for _, name in ipairs(files) do
        local f = io.open(dir .. "/" .. name, "r")
        if f then f:close() return true end
    end
    return false
end

local function braces(l)
    local _, open = l:gsub("{", "")
    local _, close = l:gsub("}", "")
    return open - close
end

-- Line of the direct child "key" of the object opened on line s (nil if missing), and the
-- line closing that object
local function child(lines, s, key)
    local depth, found = 0, nil
    for i = s + 1, #lines do
        if depth == 0 then
            if lines[i]:match("^%s*}") then return found, i end
            if lines[i]:match('^%s*"' .. key .. '":') then found = found or i end
        end
        depth = depth + braces(lines[i])
    end
end

-- Insert "key": text as the first child of the object opened on line s
local function insert(lines, s, key, text)
    local indent = lines[s]:match("^(%s*)") .. "    "
    local empty = (lines[s + 1] or ""):match("^%s*}")
    table.insert(lines, s + 1, indent .. '"' .. key .. '": ' .. text .. (empty and "" or ","))
end

local function cvarsLine(lines)
    for i, l in ipairs(lines) do if l:match('^%s*"CVars":%s*{%s*$') then return i end end
end

-- Line of a CVar path; with create, missing objects are added and a missing value is
-- inserted as "0"
local function locate(lines, path, create)
    local s = cvarsLine(lines)
    if not s then return nil end
    for n, key in ipairs(path) do
        local i = child(lines, s, key)
        if not i then
            if not create then return nil end
            if n < #path then
                insert(lines, s, key, "{")
                table.insert(lines, s + 2, lines[s + 1]:match("^(%s*)") .. "}" .. (lines[s + 1]:match(",$") and "," or ""))
                lines[s + 1] = lines[s + 1]:gsub(",$", "")
            else
                insert(lines, s, key, "0")
            end
            i = s + 1
        end
        s = i
    end
    return s
end

local function get(lines, path)
    local i = locate(lines, path)
    return i and tonumber(lines[i]:match(':%s*([%d%.%-]+)'))
end

-- Floats keep a decimal point: the game reads 720 as an integer CVar, and CVarGetFloat
-- ignores integer CVars
local function set(lines, path, value, float)
    local i = locate(lines, path, true)
    if not i then return end
    local text = float and string.format("%.1f", value) or tostring(math.floor(value))
    lines[i] = lines[i]:gsub('(":%s*)[%d%.%-]+', "%1" .. text, 1)
end

return function(spec)
    local res = spec.resolution or { "gAdvancedResolution" }
    local ASPECT_X, ASPECT_Y = path(res, "AspectRatioX"), path(res, "AspectRatioY")
    local RESOLUTION_KEYS = {
        advres = { path(res, "Enabled"), 1 },
        aspect = { path(res, "UIComboItem", "AspectRatio"), 0 },
    }
    local config = { title = spec.title, subtitle = spec.subtitle, help = spec.help, items = {} }
    local keys, forced = {}, spec.forced or {}
    for id, k in pairs(spec.keys or {}) do keys[id] = k end
    local resolution = false
    for _, it in ipairs(spec.items) do
        if it == "filter" then
            config.items[#config.items + 1] = FILTER_ITEM
            keys.filter = { spec.filter or { "gTextureFilter" }, 1 }
        elseif it == "loglevel" then
            config.items[#config.items + 1] = LOGLEVEL_ITEM
            keys.loglevel = { { "gDeveloperTools", "LogLevel" }, 3 }
        elseif it == "resolution" then
            resolution = true
            for _, r in ipairs(RESOLUTION_ITEMS) do config.items[#config.items + 1] = r end
            for id, k in pairs(RESOLUTION_KEYS) do keys[id] = k end
        else
            config.items[#config.items + 1] = it
        end
    end

    function config.load(path)
        if spec.o2r and (ramGB() or 2) <= 1 and not anyExists(path:match("^(.*)/") or ".", spec.o2r) then
            config.notice = "Select No after ROM conversion and start the game again to prevent memory issues"
        end
        local lines = readLines(path) or {}
        local v = {}
        for id, k in pairs(keys) do v[id] = get(lines, k[1]) or k[2] end
        if resolution then
            -- custom ratio: the one in the file when Custom is selected there, else the default
            local x, y = get(lines, ASPECT_X), get(lines, ASPECT_Y)
            local custom = v.aspect == 1 and (x or 0) > 0 and (y or 0) > 0
            local def = spec.custom or ASPECTS[1]
            v.customX, v.customY = custom and x or def[1], custom and y or def[2]
        end
        -- a value set in game that the launcher doesn't offer (e.g. 75 fps) is kept as an extra choice
        for _, it in ipairs(config.items) do
            local ok = not it.choices
            for _, c in ipairs(it.choices or {}) do if c[1] == v[it.id] then ok = true end end
            if not ok then table.insert(it.choices, { v[it.id], tostring(v[it.id]) .. " (set in game)" }) end
        end
        return v
    end

    function config.save(path, v)
        local lines = readLines(path)
        if not lines then return false, "cannot read " .. path end
        -- sorted, so CVars missing from the file are always added in the same order
        local ids = {}
        for id in pairs(keys) do ids[#ids + 1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do set(lines, keys[id][1], v[id]) end
        if resolution then
            local xy = v.aspect == 1 and { v.customX, v.customY } or ASPECTS[v.aspect]
            if xy then
                set(lines, ASPECT_X, xy[1], true)
                set(lines, ASPECT_Y, xy[2], true)
            end
        end
        for _, f in ipairs(forced) do set(lines, f[1], f[2]) end
        local tmp = path .. ".tmp"
        local f, err = io.open(tmp, "w")
        if not f then return false, err end
        f:write(table.concat(lines, "\n"), "\n")
        f:close()
        return os.rename(tmp, path)
    end

    return config
end
