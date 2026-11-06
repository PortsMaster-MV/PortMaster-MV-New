-- Complete Pokédex labels, a popup for bulk tools, and species cards with
-- separate Seen / Owned controls. Owning implies seen; un-seeing clears owned.
local Theme = require("Theme")
local Ops = require("Ops")
local Gen = require("Gen")
local Chooser = require("Chooser")
local MonEditor = require("MonEditor")
local PAL = Theme.PAL
local M = {}

function M.draw(S, Kit, x, y, w, h)
  local s, pad, gap = Kit.scale, 20 * Kit.scale, 8 * Kit.scale
  local cx, inner = x + pad, w - 2 * pad
  local dex, species = Ops.dex(S), Ops.dexList(S)
  local seen, owned, total = Ops.dexCounts(S)
  local row = Kit.controlH()
  Kit.card(x, y, w, h)
  Kit.caption(cx, y + pad, "POKEDEX")
  local headlineY = y + pad + Kit.textHeight("caption") + 4 * s
  Kit.text("headline", ("%d / %d owned"):format(owned, total), cx, headlineY, PAL.heading)
  local cy = headlineY + Kit.textHeight("headline") + 12 * s
  local actions = {
    { id = "stamp", label = "Own party + boxes", icon = "check", fn = Ops.dexStamp },
    { id = "see", label = "See all", icon = "eye", fn = Ops.dexSeeAll },
    { id = "own", label = "Own all", icon = "check", fn = Ops.dexOwnAll },
    {
      id = "wipe",
      label = Ops.armLabel(S, "dex-clear", "Wipe Pokédex"),
      icon = "trash",
      fn = Ops.dexClear,
    },
    {
      id = "number",
      label = "Sort by Pokédex number",
      icon = "list-filter",
      active = S.dexSort ~= "name",
      fn = function(state)
        Ops.dexSort(state, "dex")
      end,
    },
    {
      id = "name",
      label = "Sort by name",
      icon = "arrow-up-down",
      active = S.dexSort == "name",
      fn = function(state)
        Ops.dexSort(state, "name")
      end,
    },
  }
  if Gen.ofState(S) == 3 then
    local national = dex.national == true
    table.insert(actions, 1, {
      id = "national",
      label = "National Pokédex: " .. (national and "On" or "Off"),
      icon = "book-open",
      active = national,
      fn = Ops.toggleNationalDex,
    })
  end
  Chooser.actions(
    S,
    Kit,
    "dexActions",
    "Pokédex actions",
    actions,
    cx,
    cy,
    math.min(inner, 360 * s),
    row
  )
  cy = cy + row + 12 * s
  -- Counters and meters retain their space instead of competing with tools.
  local meterGap = 16 * s
  local meterW = (inner - meterGap) / 2
  for i, meter in ipairs({ { "Seen", seen, PAL.blue }, { "Owned", owned, PAL.green } }) do
    local mx = cx + (i - 1) * (meterW + meterGap)
    Kit.text("small", meter[1], mx, cy, PAL.caption)
    Kit.textRight("small", tostring(meter[2]) .. "/" .. total, mx + meterW, cy, PAL.caption)
    Kit.meter(
      mx,
      cy + Kit.textHeight("small") + 4 * s,
      meterW,
      6 * s,
      meter[2] / math.max(total, 1) * 100,
      meter[3]
    )
  end
  local gridTop = cy + Kit.textHeight("small") + 6 * s + 16 * s
  local cols = math.max(1, math.min(4, math.floor((inner + gap) / (250 * s + gap))))
  local colW = (inner - gap * (cols - 1)) / cols
  local cardPad = 10 * s
  local spriteS = 28 * s
  local nameX = cardPad + Kit.textWidth("micro", "000") + 8 * s + spriteS + 8 * s
  local nameW = colW - cardPad - nameX
  local titleH = math.max(spriteS, 2 * Kit.textHeight("small"))
  local cardH = 2 * cardPad + titleH + gap + row
  local pagerY = y + h - pad - row
  local gridH = math.max(0, pagerY - 12 * s - gridTop)
  local perCol = math.max(1, math.floor((gridH + gap) / (cardH + gap)))
  local perPage = perCol * cols
  local drawn, shift = Kit.list(S, "dexOffset", cx, gridTop, inner, gridH, #species, cardH + gap, cols)
  local chipW = (colW - 2 * cardPad - gap) / 2
  local ownedKey = Gen.dexOwnedKey(S.save)
  Kit.pushClip(cx, gridTop, inner, gridH)
  for i = 1, drawn do
    local id = species[S.dexOffset + i]
    local ci, ri = (i - 1) % cols, math.floor((i - 1) / cols)
    local rx, ry = cx + ci * (colW + gap), gridTop + ri * (cardH + gap) - shift
    local def = S.data.pokemon[id]
    local spId = def and (def.speciesId or def.dex)
    local isSeen = dex.seen[id] == true or (spId and dex.seen[spId] == true)
    local isOwned = (
      dex[ownedKey] and (dex[ownedKey][id] == true or (spId and dex[ownedKey][spId] == true))
    )
      or (dex.caught and (dex.caught[id] == true or (spId and dex.caught[spId] == true)))
    Theme.row(rx, ry, colW, cardH, 9 * s, 0.6)
    local titleY = ry + cardPad
    local dexText = ("%03d"):format(def and def.dex or 0)
    Kit.text(
      "micro",
      dexText,
      rx + cardPad,
      titleY + (titleH - Kit.textHeight("micro")) / 2,
      PAL.faint
    )
    local spriteX = rx + cardPad + Kit.textWidth("micro", "000") + 8 * s
    MonEditor.drawSprite(S, Kit, id, spriteX, titleY + (titleH - spriteS) / 2, spriteS)
    local name = tostring(def and def.name or id)
    Kit.textWrapped(
      "small",
      name,
      rx + nameX,
      titleY,
      nameW,
      isOwned and PAL.text or (isSeen and PAL.muted or PAL.faint)
    )
    local chipY = titleY + titleH + gap
    if Kit.chip(rx + cardPad, chipY, chipW, row, "Seen", isSeen) then
      Ops.dexSeen(S, id, not isSeen)
    end
    if Kit.chip(rx + cardPad + chipW + gap, chipY, chipW, row, "Owned", isOwned) then
      Ops.dexOwned(S, id, not isOwned)
    end
  end
  Kit.popClip()
  Kit.listScrollbar(S, "dexOffset", cx, gridTop, inner, gridH)
  S.dexOffset = Kit.pager(cx, pagerY, inner, S.dexOffset, #species, perPage)
end
return M
