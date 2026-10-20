-- Shared button faces for launcher and save-editor input adapters.
-- The owner supplies fonts, pointer state and text drawing; this module only paints.
local Theme = require("src.ui.kit.Theme")
local PAL = Theme.PAL
local Icons = require("src.ui.kit.Icons")
local Button = {}
local KINDS = {
  primary = { fill = PAL.green, ink = PAL.inverse },
  good = { fill = PAL.green, ink = PAL.inverse },
  accent = { fill = PAL.buttonBlue, ink = PAL.heading },
  warn = { fill = PAL.yellow, ink = PAL.inverse },
  danger = { fill = PAL.surface, ink = PAL.red, stroke = PAL.red },
  ghost = { fill = PAL.surface, ink = PAL.text, stroke = PAL.line },
  disabled = { fill = PAL.surface, ink = PAL.muted, stroke = PAL.line },
}
Button.KINDS = KINDS

-- Complete labels wrap between words. The input adapter sizes the control
-- from these same metrics; the painter never substitutes an ellipsis.
function Button.labelLayout(Kit, w, h, label, opts)
  local name = opts.font or "button"
  local lineH = Kit.textHeight(name)
  local pad = Theme.BUTTON.labelInset * Kit.scale / 2
  local trailing = opts.trailingIcon and h * 0.65 or 0
  local available = w - 2 * pad - trailing
  local function wrap(width)
    local lines, line, widest = {}, "", 0
    for word in tostring(label):gmatch("%S+") do
      local nextLine = line == "" and word or (line .. " " .. word)
      if line ~= "" and Kit.textWidth(name, nextLine) > width then
        lines[#lines + 1] = line
        widest = math.max(widest, Kit.textWidth(name, line))
        line = word
      else
        line = nextLine
      end
    end
    if line ~= "" then
      lines[#lines + 1] = line
      widest = math.max(widest, Kit.textWidth(name, line))
    end
    return lines, widest
  end
  local lines, widest = wrap(available)
  local mode, size, gap
  if opts.icon then
    size = math.floor(math.min(w, h) * 0.42)
    gap = math.floor(7 * Kit.scale)
    local sideW = available - size - gap
    local sideLines, sideWidth = wrap(sideW)
    if not opts.iconStack and sideWidth <= sideW and #sideLines * lineH <= h - 4 * Kit.scale then
      lines, widest, available, mode = sideLines, sideWidth, sideW, "side"
    elseif size + math.max(2, 3 * Kit.scale) + #lines * lineH <= h - 4 * Kit.scale then
      mode, gap = "stack", math.max(2, 3 * Kit.scale)
    end
  end
  return {
    font = name,
    lines = lines,
    width = widest,
    available = available,
    pad = pad,
    trailing = trailing,
    lineH = lineH,
    height = #lines * lineH + (mode == "stack" and size + gap or 0),
    mode = mode,
    iconSize = size,
    gap = gap,
  }
end

function Button.draw(Kit, x, y, w, h, label, opts, hot, focused)
  local G = love and love.graphics
  local enabled = opts.enabled ~= false
  local face = opts.face or "fill"
  local B = Theme.BUTTON
  local radius = opts.radius or B.radius
  local segments = opts.segments
  local active = opts.active or opts.on
  local invert = false
  local fill, ink, stroke, strokeA, strokeWidth, doEmboss, doRing, glowA
  if face == "selection" then
    -- A selected control keeps its geometry, dark face and label layout.
    -- Selection is an inset accent outline, never a filled keycap.
    fill = PAL.surface
    ink = PAL.text
    stroke = (active or focused) and PAL.blue or PAL.line
    strokeA = (active or focused) and Theme.A.focus or (hot and Theme.A.hover or Theme.A.hairline)
    strokeWidth = (active or focused) and 2 or 1
    doRing = focused or hot
  elseif face == "invert" then
    invert = false
    fill = (hot or focused) and PAL.raised or (opts.fill or PAL.surface)
    ink = opts.ink or PAL.heading
    stroke = opts.stroke or PAL.line
    strokeA = (hot or focused) and Theme.A.focus or Theme.A.hairline
    doRing = focused or hot
  elseif face == "tab" then
    invert = active and true or false
    local tint = opts.color or opts.fill or PAL.ink
    fill = invert and tint or PAL.surface
    ink = invert and PAL.inverse or (opts.color or PAL.text)
    if not invert then
      stroke = tint
      strokeA = (focused or hot) and Theme.A.focus
        or (opts.color and Theme.A.hover or Theme.A.hairline)
    end
    doRing = focused or hot
  elseif face == "chip" then
    local c = opts.color or PAL.line
    invert = active and true or false
    if active then
      fill = c
      ink = PAL.inverse
      doEmboss = true
    else
      fill = PAL.bg
      ink = c
      stroke = c
      strokeA = (focused or hot) and Theme.A.focus or Theme.A.hover
    end
    doRing = focused or hot
  else
    local kind = KINDS[enabled and (opts.kind or "ghost") or "disabled"]
    fill = (enabled and opts.fill) or kind.fill
    ink = (enabled and opts.ink) or kind.ink
    doEmboss = (opts.kind == "primary" or opts.kind == "good" or opts.kind == "accent")
    stroke = kind.stroke
    strokeA = stroke and Theme.A.hover or nil
    doRing = hot or focused
    if opts.glow and enabled and not doRing then
      glowA = B.glowBase + B.glowAmp * (0.5 + 0.5 * math.sin(Kit.time * B.glowHz))
    end
  end
  if opts.emboss ~= nil then
    doEmboss = opts.emboss
  end
  if opts.ring ~= nil then
    doRing = opts.ring
  end
  if G then
    Theme.fillRounded(x, y, w, h, fill, enabled and 1 or B.disabledA, radius, segments)
    if doEmboss then
      local es = enabled and ((hot or focused) and B.embossHot or B.embossRest) or B.embossDisabled
      Theme.emboss(x, y, w, h, es)
    end
    if strokeA then
      Theme.strokeRounded(x, y, w, h, stroke, strokeA, strokeWidth or 1, radius, segments)
    end
    if doRing then
      Theme.fillRounded(
        x,
        y,
        w,
        h,
        PAL.ink,
        Kit.mouseDown and hot and 0.04 or 0.09,
        radius,
        segments
      )
      if face ~= "selection" then
        Theme.strokeRounded(
          x,
          y,
          w,
          h,
          PAL.ink,
          focused and 1 or 0.7,
          focused and 2 or 1,
          radius,
          segments
        )
      end
    elseif glowA then
      Theme.strokeRounded(
        x - B.ringPad,
        y - B.ringPad,
        w + 2 * B.ringPad,
        h + 2 * B.ringPad,
        PAL.lineStrong,
        glowA,
        B.ringWidth,
        radius + B.ringPad,
        segments
      )
    end
    local fname = opts.font or ((face == "chip") and "micro" or "button")
    local ty = y + (h - Kit.textHeight(fname)) / 2
    local image = opts.image
    local drawFn = opts.drawFn
    local letter = opts.letter
    local hasLabel = label and label ~= ""
    local bold = opts.bold
    if bold == nil then
      bold = face ~= "tab" and face ~= "selection"
    end
    if opts.fullLabel and hasLabel then
      local layout = opts.labelLayout or Button.labelLayout(Kit, w, h, label, opts)
      local lx, ly = x + layout.pad, y + (h - #layout.lines * layout.lineH) / 2
      if layout.mode == "side" then
        local groupW = layout.iconSize + layout.gap + layout.width
        local ix = opts.align == "left" and lx or x + (w - layout.trailing - groupW) / 2
        Icons.draw(
          opts.icon,
          ix,
          y + (h - layout.iconSize) / 2,
          layout.iconSize,
          ink,
          enabled and 1 or B.disabledA
        )
        lx = ix + layout.iconSize + layout.gap
      elseif layout.mode == "stack" then
        local top = y + (h - layout.height) / 2
        Icons.draw(
          opts.icon,
          x + (w - layout.trailing - layout.iconSize) / 2,
          top,
          layout.iconSize,
          ink,
          enabled and 1 or B.disabledA
        )
        ly = top + layout.iconSize + layout.gap
      end
      for i, line in ipairs(layout.lines) do
        local lineY = ly + (i - 1) * layout.lineH
        if layout.mode == "side" or opts.align == "left" then
          if bold then
            Kit.textBold(layout.font, line, lx, lineY, ink)
          else
            Kit.text(layout.font, line, lx, lineY, ink)
          end
        elseif bold then
          Kit.textCenterBold(layout.font, line, lx, lineY, layout.available, ink)
        else
          Kit.textCenter(layout.font, line, lx, lineY, layout.available, ink)
        end
      end
    elseif opts.icon and opts.iconStack then
      local size = math.floor(math.min(w * 0.5, h * 0.4))
      local labelH = Kit.textHeight(fname)
      local gap = math.max(2, math.floor(3 * Kit.scale))
      local top = y + (h - size - gap - labelH) / 2
      Icons.draw(opts.icon, x + (w - size) / 2, top, size, ink, enabled and 1 or B.disabledA)
      local shown = Kit.ellipsize(fname, label or "", w - B.labelInset * Kit.scale)
      Kit.textCenter(fname, shown, x, top + size + gap, w, ink)
    elseif opts.icon then
      local box = math.min(w, h)
      local size = math.floor(box * (hasLabel and 0.42 or 0.5))
      local gap = math.floor(7 * Kit.scale)
      local shown = hasLabel
          and Kit.ellipsize(
            fname,
            label,
            w - size - gap - 2 * B.labelPad * Kit.scale - (opts.trailingIcon and h * 0.65 or 0)
          )
        or ""
      local groupW = size + (hasLabel and gap + Kit.textWidth(fname, shown) or 0)
      local ix = opts.align == "left" and x + B.labelPad * Kit.scale or x + (w - groupW) / 2
      Icons.draw(opts.icon, ix, y + (h - size) / 2, size, ink, enabled and 1 or B.disabledA)
      if hasLabel then
        if bold then
          Kit.textBold(fname, shown, ix + size + gap, ty, ink)
        else
          Kit.text(fname, shown, ix + size + gap, ty, ink)
        end
      end
    elseif image then
      local box = h
      local boxX, boxY = x, y
      if not hasLabel then
        box = math.min(w, h)
        boxX = x + (w - box) / 2
        boxY = y + (h - box) / 2
      end
      local iw, ih = image:getDimensions()
      local pad = math.floor(box * (opts.iconPad or B.iconPad))
      local s = math.min((box - 2 * pad) / iw, (box - 2 * pad) / ih)
      Theme.col(ink, enabled and 1 or B.disabledA)
      G.draw(
        image,
        Theme.snap(boxX + (box - iw * s) / 2),
        Theme.snap(boxY + (box - ih * s) / 2),
        0,
        s,
        s
      )
      if hasLabel then
        local lx = x + h + B.letterGap * Kit.scale
        if bold then
          Kit.textBold(fname, label, lx, ty, ink)
        else
          Kit.text(fname, label, lx, ty, ink)
        end
      end
    elseif drawFn then
      drawFn(x, y, w, h, invert)
    elseif letter then
      if opts.letterBold then
        Kit.textCenterBold(fname, letter, x, ty, h, ink)
      else
        Kit.textCenter(fname, letter, x, ty, h, ink)
      end
      if hasLabel then
        local lx = x + h + B.letterGap * Kit.scale
        if bold then
          Kit.textBold(fname, label, lx, ty, ink)
        else
          Kit.text(fname, label, lx, ty, ink)
        end
      end
    elseif hasLabel then
      local shown = Kit.ellipsize(
        fname,
        label,
        w - B.labelInset * Kit.scale - (opts.trailingIcon and h * 0.65 or 0)
      )
      if opts.align == "left" then
        local lx = x + B.labelPad * Kit.scale
        if bold then
          Kit.textBold(fname, shown, lx, ty, ink)
        else
          Kit.text(fname, shown, lx, ty, ink)
        end
      elseif bold then
        Kit.textCenterBold(fname, shown, x, ty, w, ink)
      else
        Kit.textCenter(fname, shown, x, ty, w, ink)
      end
    end
  end
  if opts.trailingIcon and G then
    local size = math.floor(h * 0.4)
    Icons.draw(
      opts.trailingIcon,
      x + w - size - B.labelPad * Kit.scale,
      y + (h - size) / 2,
      size,
      ink,
      enabled and 1 or B.disabledA
    )
  end
end
return Button
