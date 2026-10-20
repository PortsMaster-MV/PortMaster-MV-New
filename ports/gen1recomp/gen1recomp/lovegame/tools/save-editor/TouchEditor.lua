local Theme = require("Theme")
local Chrome = require("PickerChrome")
local PAL = Theme.PAL
local E = {}
local function limits(p)
	local l = type(p.limits) == "function" and p.limits() or p.limits
	return l or { lo = 0, hi = 255 }
end
function E.close(S, Kit)
	S.editPopup = nil
	Kit.blur()
	Kit.mouseClicked, Kit.wheelY, Kit._dragDelta = false, 0, 0
end
function E.open(S, Kit, p)
	Kit.blur()
	p.opened, p.scroll, p.query = true, 0, ""
	S.editPopup, Kit.blockClicks = p, true
end
function E.help(S, Kit, title, message, x, y)
	local tap, size = Kit.tapMin(), 22 * Kit.scale
	if Kit.press(x, y, tap, tap) then
		E.open(S, Kit, { mode = "help", title = title, help = message })
	end
	Theme.col(PAL.cardBorder, 0.8)
	love.graphics.circle("line", x + tap / 2, y + tap / 2, size / 2)
	Kit.textCenter("small", "?", x, y + (tap - Kit.textHeight("small")) / 2, tap, PAL.caption)
end
function E.issue(Kit, message, x, y, w)
	if not message then return 0 end
	local size, gap = 14 * Kit.scale, 6 * Kit.scale
	Kit.icon("triangle-alert", x, y + 2 * Kit.scale, size, PAL.red)
	return math.max(size, Kit.textWrapped("tiny", message, x + size + gap, y, w - size - gap, PAL.red)) + gap
end
function E.action(S, Kit, label, help, fn, x, y, w, kind, issue)
	local gap, tap = 8 * Kit.scale, Kit.tapMin()
	local opts = { kind = kind, font = "small", invalid = issue ~= nil }
	local h = Kit.buttonHeight(label, w - tap - gap, opts)
	if Kit.button(x, y, w - tap - gap, h, label, opts) then
		fn()
	end
	E.help(S, Kit, label, help, x + w - tap, y + (h - tap) / 2)
	return h + (issue and gap + E.issue(Kit, issue, x, y + h + gap, w) or 0)
end
function E.value(S, Kit, id, title, value, getLimits, x, y, w, apply, issue)
	local l = type(getLimits) == "function" and getLimits() or getLimits
	if not require("Legality").integer(value, l.lo, l.hi) then
		issue = issue or "Saved value must be a whole number from " .. l.lo .. " to " .. l.hi
	end
	local tap, gap = Kit.tapMin(), 8 * Kit.scale
	local opts = {
		font = "small",
		align = "left",
		trailingIcon = "pencil",
		face = "invert",
		id = "value-" .. id,
		invalid = issue ~= nil,
	}
	local label = title .. ": " .. tostring(value)
	local h = Kit.buttonHeight(label, w - tap - gap, opts)
	if Kit.button(x, y, w - tap - gap, h, label, opts) then
		E.open(S, Kit, { mode = "number", id = id, title = title, value = value, savedValue = value,
			issue = issue, limits = getLimits, apply = apply })
	end
	E.help(S, Kit, title, l.help, x + w - tap, y + (h - tap) / 2)
	local n = tonumber(value)
	local ratio = n and n == n and Theme.clamp((n - l.lo) / math.max(1, l.hi - l.lo), 0, 1) or 0
	local color = issue and PAL.red or PAL.blue
	local trackY, trackH = y + h + 6 * Kit.scale, 5 * Kit.scale
	Theme.fillRounded(x, trackY, w, trackH, PAL.cardBorder, 0.3, trackH / 2)
	if ratio > 0 then
		Theme.fillRounded(x, trackY, w * ratio, trackH, color, 0.9, trackH / 2)
	end
	local caption = l.lo .. " to " .. l.hi
	if l.remaining ~= nil then
		caption = caption .. "  ·  " .. l.remaining .. " points free"
	end
	local ch = Kit.textWrapped("tiny", caption, x, trackY + trackH + 4 * Kit.scale, w, issue and PAL.red or PAL.caption)
	local height = h + 15 * Kit.scale + ch
	return height + (issue and gap + E.issue(Kit, issue, x, y + height + gap, w) or 0)
end
function E.choice(S, Kit, id, title, value, options, x, y, w, apply, help, issue)
	local shown = (issue and "Invalid saved value " or "Unknown saved value ") .. tostring(value)
	for _, o in ipairs(options) do
		if o[1] == value then
			shown = o[2]
		end
	end
	local opts = {
		face = "invert",
		font = "small",
		align = "left",
		trailingIcon = "chevron-down",
		id = "choice-" .. id,
		invalid = issue ~= nil,
	}
	local label = title .. ": " .. shown
	local h = Kit.buttonHeight(label, w, opts)
	if Kit.button(x, y, w, h, label, opts) then
		E.open(S, Kit, {
			mode = "choice",
			id = id,
			title = title,
			value = value,
			options = options,
			apply = apply,
			help = help,
			issue = issue,
		})
	end
	return h + (issue and 8 * Kit.scale + E.issue(Kit, issue, x, y + h + 8 * Kit.scale, w) or 0)
end
function E.results(p)
	local rows, query = {}, (p.query or ""):lower()
	for _, o in ipairs(p.options or {}) do
		if (o[2] .. " " .. tostring(o[1])):lower():find(query, 1, true) then
			rows[#rows + 1] = o
		end
	end
	return rows
end
function E.commit(S, Kit)
	local p = S.editPopup
	if not p then
		return false
	end
	local value = p.value
	if p.mode == "number" then
		local l = limits(p)
		if p.typing then
			value = tonumber(Kit.flushText("touch-exact", p.draft))
		end
		if not value or value ~= math.floor(value) or value < l.lo or value > l.hi then
			p.error = "Choose a whole number from " .. l.lo .. " to " .. l.hi
			return false
		end
	elseif p.mode == "choice" then
		local rows = E.results(p)
		local first = rows[p.index or 1] or rows[1]
		if not first then
			return false
		end
		value = first[1]
	end
	if p.apply then
		p.apply(value)
	end
	E.close(S, Kit)
	return true
end
function E.keypressed(S, Kit, key)
	local p = S.editPopup
	if not p then
		return false
	end
	if key == "escape" then
		E.close(S, Kit)
	elseif key == "return" or key == "kpenter" then
		if p.mode == "choice" then
			p.query = Kit.flushText("touch-search", p.query)
		end
		E.commit(S, Kit)
	elseif p.mode == "number" and not p.typing then
		local l = limits(p)
		local delta = ({ left = -1, right = 1, down = -5, up = 5 })[key]
		if delta then
			p.value = Theme.clamp(p.value + delta, l.lo, l.hi)
		end
		if key == "home" then
			p.value = l.lo
		elseif key == "end" then
			p.value = l.hi
		end
	elseif p.mode == "choice" and (key == "up" or key == "down" or key == "home" or key == "end") then
		local n = #E.results(p)
		if n > 0 then
			if key == "home" then
				p.index = 1
			elseif key == "end" then
				p.index = n
			else
				p.index = Theme.clamp((p.index or 1) + (key == "up" and -1 or 1), 1, n)
			end
			p.reveal, p.keyboard = true, true
		end
	else
		Kit.keypressed(key)
	end
	return true
end
function E.draw(S, Kit, width, height)
	local p = S.editPopup
	if not p then
		return
	end
	Kit.resetClip()
	Kit.blockClicks, p.opened = p.opened == true, nil
	local x, y, w, h, pad = Chrome.card(Kit, width, height)
	local row, gap, s = Kit.controlH(), 8 * Kit.scale, Kit.scale
	if p.mode == "help" then
		local oldH = h
		local _, lines = Kit.fonts.small:getWrap(p.help or "", w - 2 * pad)
		h = math.min(h, row + 2 * pad + gap + #lines * Kit.textHeight("small"))
		y = y + (oldH - h) / 2
	end
	p.rect = { x = x, y = y, w = w, h = h }
	Theme.col(PAL.bgBot, 0.78)
	love.graphics.rectangle("fill", 0, 0, width, height)
	if Kit.press(0, 0, width, height) and not Kit.hit(x, y, w, h) then
		E.close(S, Kit)
		return
	end
	Kit.card(x, y, w, h)
	local cx, inner, cy = x + pad, w - 2 * pad, y + pad
	Kit.textWrapped("small", p.title, cx, cy + 6 * s, inner - row - gap, PAL.heading)
	if Kit.iconButton(cx + inner - row, cy, row, row, "x", "Close") then
		E.close(S, Kit)
		return
	end
	cy = cy + row + gap
	if p.issue then
		local message = p.savedValue ~= nil and ("Saved: " .. tostring(p.savedValue) .. ". " .. p.issue) or p.issue
		cy = cy + E.issue(Kit, message, cx, cy, inner) + gap
	end
	if p.mode == "help" then
		Kit.textWrapped("small", p.help or "", cx, cy, inner, PAL.text)
		return
	end
	if p.mode == "choice" then
		p.query = Kit.textfield("touch-search", cx, cy, inner, row, p.query, "Search by name")
		cy = cy + row + gap
		if p.lastQuery ~= p.query then
			p.index, p.lastQuery, p.scroll = 1, p.query, 0
		end
		local bodyH, rows = y + h - pad - cy, E.results(p)
		local heights, total = {}, 0
		for i, o in ipairs(rows) do
			heights[i] = {
				top = total,
				h = Kit.buttonHeight(o[2], inner, { font = "small", align = "left", trailingIcon = "check" }),
			}
			total = total + heights[i].h + gap
		end
		if p.reveal and heights[p.index] then
			local selected = heights[p.index]
			p.scroll = Theme.clamp(
				math.max(selected.top + selected.h - bodyH, math.min(p.scroll, selected.top)),
				0,
				math.max(0, total - bodyH)
			)
			p.reveal = nil
		end
		p.scroll = Kit.scrollPixels(cx, cy, inner, bodyH, p.scroll, total)
		Kit.pushClip(cx, cy, inner, bodyH)
		for i, o in ipairs(rows) do
			local r = heights[i]
			if r.top + r.h >= p.scroll and r.top <= p.scroll + bodyH then
				if
					Kit.button(cx, cy + r.top - p.scroll, inner, r.h, o[2], {
						font = "small",
						align = "left",
						face = "selection",
						active = o[1] == p.value,
						trailingIcon = o[1] == p.value and "check" or nil,
						ring = p.keyboard and p.index == i or nil,
					})
				then
					p.apply(o[1])
					Kit.popClip()
					E.close(S, Kit)
					return
				end
			end
		end
		if #rows == 0 then
			Kit.textWrapped("small", "Nothing matches that.", cx, cy + gap, inner, PAL.caption)
		end
		Kit.popClip()
		Kit.scrollbar(cx, cy, inner, bodyH, p.scroll, total, bodyH)
		return
	end
	local l = limits(p)
	p.value = Theme.clamp(tonumber(p.value) or l.lo, l.lo, l.hi)
	local function setValue(value)
		p.value = Theme.clamp(value, l.lo, l.hi)
		p.typing, p.draft, p.error = nil, nil, nil
		Kit.blur()
	end
	local function spinWheel()
		p.wheelDelta = (p.wheelDelta or 0) + Kit.wheelY
		local delta = p.wheelDelta >= 0 and math.floor(p.wheelDelta) or math.ceil(p.wheelDelta)
		if delta ~= 0 then
			setValue(p.value + delta)
			p.wheelDelta = p.wheelDelta - delta
		end
		Kit.wheelY = 0
	end
	local helpH = Kit.textWrapped("tiny", l.help or "", cx, cy, inner, PAL.caption)
	cy = cy + helpH + gap
	local bodyY, bodyH = cy, math.max(0, y + h - pad - row - gap - cy)
	if p.roll and math.abs(Kit.mouseY - p.roll.y) > math.abs(Kit.mouseX - p.roll.x) + 8 * s then
		p.roll = nil
		p.verticalRoll = true
	end
	if not Kit.mouseDown then
		p.verticalRoll = nil
	end
	if p.slider or p.roll then
		Kit._dragDelta = 0
	end
	if
		p.wheelRect
		and not Kit.blockClicks
		and Kit.hit(p.wheelRect.x, p.wheelRect.y, p.wheelRect.w, p.wheelRect.h)
		and Kit.wheelY ~= 0
	then
		spinWheel()
	end
	p.scroll = Kit.scrollPixels(
		cx,
		bodyY,
		inner,
		bodyH,
		p.scroll,
		p.contentH or (6 * row + 7 * gap + 2 * Kit.textHeight("tiny"))
	)
	Kit.pushClip(cx, bodyY, inner, bodyH)
	cy = cy - p.scroll
	local contentStart = cy
	Kit.textCenter("title", tostring(p.value), cx, cy + gap, inner, PAL.heading)
	cy = cy + row + gap
	local ratio = (p.value - l.lo) / math.max(1, l.hi - l.lo)
	local trackX, trackW = cx + 12 * s, inner - 24 * s
	p.sliderRect = { x = cx, y = cy, w = inner, h = row }
	local trackY = cy + row / 2
	Theme.fillRounded(trackX, trackY - 4 * s, trackW, 8 * s, PAL.cardBorder, 0.4, 4 * s)
	if ratio > 0 then
		Theme.fillRounded(trackX, trackY - 4 * s, trackW * ratio, 8 * s, PAL.blue, 1, 4 * s)
	end
	Theme.col(PAL.blue)
	love.graphics.circle("fill", trackX + trackW * ratio, trackY, 11 * s)
	if Kit.press(cx, cy, inner, row) then
		setValue(math.floor(l.lo + Theme.clamp((Kit.mouseX - trackX) / trackW, 0, 1) * (l.hi - l.lo) + 0.5))
	end
	if not Kit.blockClicks and Kit.mouseDown and Kit.hit(cx, cy, inner, row) then
		p.slider = true
	end
	if p.slider and Kit.mouseDown then
		setValue(math.floor(l.lo + Theme.clamp((Kit.mouseX - trackX) / trackW, 0, 1) * (l.hi - l.lo) + 0.5))
	else
		p.slider = nil
	end
	cy = cy + row
	Kit.text("tiny", tostring(l.lo), cx, cy, PAL.caption)
	Kit.textRight("tiny", "Max " .. l.hi, cx + inner, cy, PAL.caption)
	cy = cy + Kit.textHeight("tiny") + gap
	-- A horizontal number wheel: one tick per value, with a stable centre.
	local tick = math.max(30 * s, Kit.textWidth("small", tostring(l.hi)) + 16 * s)
	p.wheelRect = { x = cx, y = cy, w = inner, h = row }
	Theme.fillRounded(cx, cy, inner, row, PAL.rowBg, 0.6, 12 * s)
	Theme.fillRounded(cx + (inner - tick) / 2, cy + 4 * s, tick, row - 8 * s, PAL.blue, 0.12, 8 * s)
	Kit.pushClip(cx, cy, inner, row)
	for i = -5, 5 do
		local n = p.value + i
		if n >= l.lo and n <= l.hi then
			Kit.textCenter(
				"small",
				tostring(n),
				cx + inner / 2 + i * tick - tick / 2,
				cy + (row - Kit.textHeight("small")) / 2,
				tick,
				i == 0 and PAL.blueInk or PAL.faint
			)
		end
	end
	Kit.popClip()
	if not Kit.blockClicks and Kit.mouseDown and Kit.hit(cx, cy, inner, row) and not p.roll and not p.verticalRoll then
		p.roll = { x = Kit.mouseX, y = Kit.mouseY, value = p.value }
	end
	if p.roll and Kit.mouseDown then
		setValue(p.roll.value + math.floor((p.roll.x - Kit.mouseX) / (tick / 2) + 0.5))
	else
		p.roll = nil
	end
	if Kit.hit(cx, cy, inner, row) and not Kit.blockClicks and Kit.wheelY ~= 0 then
		spinWheel()
	end
	cy = cy + row + gap
	Kit.textCenter("tiny", "Roll the numbers to fine-tune", cx, cy, inner, PAL.caption)
	cy = cy + Kit.textHeight("tiny") + gap
	local bw = (inner - 3 * gap) / 4
	for i, d in ipairs({ -5, -1, 1, 5 }) do
		local label = (d > 0 and "+" or "") .. d
		if
			Kit.button(
				cx + (i - 1) * (bw + gap),
				cy,
				bw,
				row,
				label,
				{ font = "small", enabled = p.value + d >= l.lo and p.value + d <= l.hi }
			)
		then
			setValue(p.value + d)
		end
	end
	cy = cy + row + gap
	local half = (inner - gap) / 2
	if Kit.button(cx, cy, half, row, "Min", { font = "small" }) then
		setValue(l.lo)
	end
	if Kit.button(cx + half + gap, cy, half, row, "Max", { font = "small", kind = "good" }) then
		setValue(l.hi)
	end
	cy = cy + row + gap
	if p.typing then
		p.draft = Kit.textfield("touch-exact", cx, cy, inner, row, p.draft, "Exact value")
	elseif Kit.button(cx, cy, inner, row, "Type a value", { font = "small", icon = "pencil" }) then
		p.typing, p.draft = true, tostring(p.value)
	end
	cy = cy + row + gap
	if p.error then
		cy = cy + Kit.textWrapped("tiny", p.error, cx, cy, inner, PAL.red) + gap
	end
	p.contentH = cy - contentStart
	Kit.popClip()
	if Kit.button(cx, y + h - pad - row, inner, row, "Apply", { kind = "good", font = "small", icon = "check" }) then
		E.commit(S, Kit)
	end
end
return E
