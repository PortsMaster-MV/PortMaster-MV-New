-- Shared copy: recipes/templates/includes/launcher/
-- Launcher config for HarbourMasters ports with Anchor online co-op (Lighthouse,
-- Ship of Harkinian). A port's launcher/config.lua is just:
--   return require("anchor")("Game Title", { fps = <original fps>, fpsDefault = <fps when unset> })
-- fpsDefault is only needed when the game's unset default differs from fps.
-- o2r = { "game.o2r", ... }: on <=1GB devices with none of these next to the game config
-- yet, warn to answer No after the rom conversion and start the game again.
--
-- Edits the game's JSON config line by line; the game writes it pretty-printed
-- (one key per line), so no JSON parser is needed:
--   CVars.gRemote.Anchor.Name / RoomId  - set (the section is created if missing)
--   CVars.gOpenWindows.Menu             - forced to 0 (menu closed at start)
--   CVars.gSettings.ControlNav          - forced to 1 (controller menu navigation)
--   CVars.gSettings.InterpolationFPS / MatchRefreshRate - frame rate ("Match display"
--                                         sets MatchRefreshRate 1, which ignores InterpolationFPS)
--   CVars.gSettings.LowResMode          - N64 low-res mode

return function(title, opts)
    opts = opts or {}
    local fps = opts.fps or 20
    local fpsDefault = opts.fpsDefault or fps

    local fpsChoices = { { 0, "Match display" }, { fps, fps .. " (original)" } }
    for _, n in ipairs({ 30, 60 }) do
        if n ~= fps then fpsChoices[#fpsChoices + 1] = { n, tostring(n) } end
    end

    local config = {
        title = title,
        subtitle = "Anchor online co-op setup",
        help = "Players with the same Room ID play together. The name is what other players see.",
        items = {
            { id = "name", label = "Player name", kind = "text", maxlen = 20 },
            { id = "room", label = "Room ID", kind = "text", maxlen = 20 },
            { id = "fps", label = "Frame rate", kind = "choice", choices = fpsChoices,
              help = "Higher is smoother but needs a faster device." },
            { id = "lowres", label = "N64 low-res mode", kind = "choice",
              choices = { { 0, "Off" }, { 1, "On" } },
              help = "Renders at the N64's original resolution. Helps on weaker devices." },
        },
    }

    local function readLines(path)
        local f = io.open(path, "r")
        if not f then return nil end
        local lines = {}
        for l in f:lines() do lines[#lines + 1] = l end
        f:close()
        return lines
    end

    -- Insert block (literal lines) after line i, an object's opening line, one
    -- indent level deeper; the last line gets a comma unless the object was empty.
    local function insertAfter(lines, i, block)
        local indent = lines[i]:match("^(%s*)") .. "    "
        local empty = (lines[i + 1] or ""):match("^%s*}")
        for n, e in ipairs(block) do
            local comma = (n == #block and not empty) and "," or ""
            table.insert(lines, i + n, indent .. e .. comma)
        end
    end

    -- Calls fn(line, inSection) for every line and stores the returned line.
    -- inSection is true only for keys directly inside the named object, so e.g.
    -- the renderer's "Name" under "Window" or gSettings.Mods.* are never touched.
    local function eachLine(lines, section, fn)
        local depth = 0
        for i, l in ipairs(lines) do
            lines[i] = fn(l, depth == 1)
            if depth > 0 then
                local _, open = l:gsub("{", "")
                local _, close = l:gsub("}", "")
                depth = depth + open - close
            elseif l:match('"' .. section .. '":%s*{') then
                depth = 1
            end
        end
    end

    local function find(lines, pattern)
        for i, l in ipairs(lines) do if l:match(pattern) then return i end end
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

    function config.load(path)
        if opts.o2r and (ramGB() or 2) <= 1 and not anyExists(path:match("^(.*)/") or ".", opts.o2r) then
            config.notice = "Select No after ROM conversion and start the game again to prevent memory issues"
        end
        local v = { name = "Player", room = "PORTMASTER" }
        local lines = readLines(path) or {}
        eachLine(lines, "Anchor", function(l, inAnchor)
            if inAnchor then
                v.name = l:match('"Name":%s*"([^"]*)"') or v.name
                v.room = l:match('"RoomId":%s*"([^"]*)"') or v.room
            end
            return l
        end)
        local s = {}
        eachLine(lines, "gSettings", function(l, inSettings)
            local k, n = l:match('^%s*"(%w+)":%s*(%-?%d+)')
            if inSettings and k then s[k] = tonumber(n) end
            return l
        end)
        v.fps = s.MatchRefreshRate == 1 and 0 or s.InterpolationFPS or fpsDefault
        v.lowres = s.LowResMode or 0

        -- a value set in game that the launcher doesn't offer (e.g. 45 fps) is kept as an extra choice
        for _, it in ipairs(config.items) do
            if it.choices then
                local ok = false
                for _, c in ipairs(it.choices) do if c[1] == v[it.id] then ok = true end end
                if not ok then table.insert(it.choices, { v[it.id], v[it.id] .. " (set in game)" }) end
            end
        end
        return v
    end

    -- Names are limited by the on-screen keyboard to [A-Za-z0-9_-], so they
    -- need no JSON escaping.
    function config.save(path, v)
        local lines = readLines(path)
        if not lines then return false, "cannot read " .. path end
        local name, room = '"Name": "' .. v.name .. '"', '"RoomId": "' .. v.room .. '"'

        local hasName, hasRoom = false, false
        eachLine(lines, "Anchor", function(l, inAnchor)
            if inAnchor then
                if l:match('"Name":') then hasName = true end
                if l:match('"RoomId":') then hasRoom = true end
                l = l:gsub('"Name":%s*"[^"]*"', name)
                l = l:gsub('"RoomId":%s*"[^"]*"', room)
            end
            return (l:gsub('("Menu":%s*)1(%s*,?%s*)$', '%10%2'))
        end)

        local missing = {}
        if not hasName then missing[#missing + 1] = name end
        if not hasRoom then missing[#missing + 1] = room end
        if #missing == 2 then missing[1] = missing[1] .. "," end
        if #missing > 0 then
            local anchor = find(lines, '"Anchor":%s*{%s*$')
            local remote = find(lines, '"gRemote":%s*{%s*$')
            local cvars = find(lines, '"CVars":%s*{%s*$')
            if anchor then
                insertAfter(lines, anchor, missing)
            elseif remote then
                insertAfter(lines, remote, { '"Anchor": {', "    " .. name .. ",", "    " .. room, "}" })
            elseif cvars then
                insertAfter(lines, cvars, { '"gRemote": {', '    "Anchor": {', "        " .. name .. ",",
                                            "        " .. room, "    }", "}" })
            end
        end

        -- gSettings ints; InterpolationFPS is left alone with "Match display"
        local set = { ControlNav = 1, LowResMode = v.lowres, MatchRefreshRate = v.fps == 0 and 1 or 0 }
        if v.fps ~= 0 then set.InterpolationFPS = v.fps end
        eachLine(lines, "gSettings", function(l, inSettings)
            local k = l:match('^%s*"(%w+)":%s*%-?%d+')
            if inSettings and k and set[k] then
                l = l:gsub('("' .. k .. '":%s*)%-?%d+', '%1' .. set[k])
                set[k] = nil
            end
            return l
        end)
        local add = {}
        for _, k in ipairs({ "ControlNav", "InterpolationFPS", "LowResMode", "MatchRefreshRate" }) do
            if set[k] then add[#add + 1] = '"' .. k .. '": ' .. set[k] end
        end
        if #add > 0 then
            for n = 1, #add - 1 do add[n] = add[n] .. "," end
            local settings = find(lines, '"gSettings":%s*{%s*$')
            local cvars = find(lines, '"CVars":%s*{%s*$')
            if settings then
                insertAfter(lines, settings, add)
            elseif cvars then
                for n, e in ipairs(add) do add[n] = "    " .. e end
                table.insert(add, 1, '"gSettings": {')
                add[#add + 1] = "}"
                insertAfter(lines, cvars, add)
            end
        end

        local tmp = path .. ".tmp"
        local f, err = io.open(tmp, "w")
        if not f then return false, err end
        f:write(table.concat(lines, "\n"), "\n")
        f:close()
        return os.rename(tmp, path)
    end

    return config
end
