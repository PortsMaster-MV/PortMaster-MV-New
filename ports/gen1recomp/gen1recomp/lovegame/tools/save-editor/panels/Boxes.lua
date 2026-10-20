local Ops = require("Ops")
local Gen = require("Gen")
local PAL = require("Theme").PAL
local M = {}
local Motion = require("Motion")
local Chooser = require("Chooser")
local function drawView(S, Kit, x, y, w, h)
  local s, pad, gap, row = Kit.scale, 12 * Kit.scale, 8 * Kit.scale, Kit.controlH()
  Kit.card(x, y, w, h)
  local cx, cy, inner = x + pad, y + pad, w - 2 * pad
  S.boxView = S.boxView or "storage"
  local compact = h < 300 * s
  local boxes = Ops.boxes(S)
  S.selectedBox = Ops.clamp(S.selectedBox or 1, 1, Ops.boxCount(S))
  local box = boxes[S.selectedBox]
  local views = { { "storage", "Boxes" }, { "party", "Deposit" } }
  if compact and inner >= 360 * s then
    local modeW = math.max(row, inner * 0.28)
    Chooser.navigation(S, Kit, "boxView", "Storage view", views, cx, cy, modeW, row)
    local left = cx + modeW + gap
    if Kit.stepper(left, cy, row, row, "previous") then
      Ops.stepBox(S, -1)
    end
    if Kit.stepper(cx + inner - row, cy, row, row, "next") then
      Ops.stepBox(S, 1)
    end
    Kit.textCenter(
      "small",
      "Box " .. S.selectedBox .. "/" .. Ops.boxCount(S),
      left + row + gap,
      cy + (row - Kit.textHeight("small")) / 2,
      inner - modeW - 2 * row - 3 * gap,
      PAL.text
    )
    cy = cy + row + gap
  else
    Chooser.navigation(
      S,
      Kit,
      "boxView",
      "Storage view",
      views,
      cx,
      cy,
      math.min(inner, 360 * s),
      row
    )
    cy = cy + row + gap
    if Kit.stepper(cx, cy, row, row, "previous") then
      Ops.stepBox(S, -1)
    end
    if Kit.stepper(cx + inner - row, cy, row, row, "next") then
      Ops.stepBox(S, 1)
    end
    Kit.textCenter(
      "small",
      ("Box %d / %d (%d/%d)"):format(
        S.selectedBox,
        Ops.boxCount(S),
        Ops.boxSize(S, box),
        Ops.boxCapacity(S)
      ),
      cx + row + gap,
      cy + (row - Kit.textHeight("small")) / 2,
      inner - 2 * (row + gap),
      PAL.text
    )
    cy = cy + row + gap
  end
  local actions
  if S.boxView == "party" then
    actions = {
      {
        "Deposit selected",
        function()
          Ops.deposit(S)
        end,
        "accent",
      },
      {
        "Inspect",
        function()
          Motion.change(S, "tab", "party", -1)
          S.mobileInspector = true
        end,
        "ghost",
      },
    }
  else
    actions = {
      {
        "Withdraw",
        function()
          Ops.withdraw(S)
        end,
        "accent",
      },
      {
        "Add",
        function()
          Ops.openBoxAddPicker(S, Kit)
        end,
        "good",
      },
      {
        Ops.armLabel(S, "box-release", "Release"),
        function()
          Ops.release(S)
        end,
        "danger",
      },
      {
        "Inspect",
        function()
          Motion.change(S, "tab", "party", -1)
          S.mobileInspector = true
        end,
        "ghost",
      },
    }
  end
  local widest = Kit.buttonWidth("Confirm?", { font = "small", icon = "check" }, row)
  for _, action in ipairs(actions) do
    widest = math.max(widest, Kit.buttonWidth(action[1], { font = "small" }, row))
  end
  local cols = inner >= #actions * widest + (#actions - 1) * gap and #actions or 2
  local bw = (inner - (cols - 1) * gap) / cols
  local rows = math.ceil(#actions / cols)
  local footer = y + h - pad - rows * (row + gap)
  for i, a in ipairs(actions) do
    if
      Kit.button(
        cx + (i - 1) % cols * (bw + gap),
        footer + math.floor((i - 1) / cols) * (row + gap),
        bw,
        row,
        a[1],
        { kind = a[3], font = "small" }
      )
    then
      a[2]()
    end
  end
  local bodyH = math.max(0, footer - gap - cy)
  if S.boxView == "party" then
    local drawn, shift = Kit.list(S, "dockOffset", cx, cy, inner, bodyH, #S.save.party, row + gap)
    Kit.pushClip(cx, cy, inner, bodyH)
    for i = 1, drawn do
      local slot = S.dockOffset + i
      local mon = S.save.party[slot]
      if not mon then
        break
      end
      if
        Kit.button(
          cx,
          cy + (i - 1) * (row + gap) - shift,
          inner,
          row,
          tostring(slot)
            .. " / "
            .. require("Ops").monName(S, mon)
            .. " / Lv"
            .. tostring(mon.level),
          { face = "tab", active = S.editingMon == mon, font = "small" }
        )
      then
        Ops.selectParty(S, slot)
      end
    end
    Kit.popClip()
  else
    local cellWMin = math.max(Kit.tapMin(), 82 * s)
    local gridCols = math.max(2, math.floor((inner + gap) / (cellWMin + gap)))
    local cw = (inner - (gridCols - 1) * gap) / gridCols
    local cellH = math.max(row, 76 * s)
    if bodyH >= 60 * s then
      cellH = math.min(cellH, bodyH)
    end
    local gridRows = math.ceil(Ops.boxCapacity(S) / gridCols)
    S.boxGridScroll =
      Kit.scrollPixels(cx, cy, inner, bodyH, S.boxGridScroll or 0, gridRows * (cellH + gap))
    Kit.pushClip(cx, cy, inner, bodyH)
    for i = 1, Ops.boxCapacity(S) do
      local bx = cx + (i - 1) % gridCols * (cw + gap)
      local by = cy + math.floor((i - 1) / gridCols) * (cellH + gap) - S.boxGridScroll
      local mon = box[i]
      if Kit.row(bx, by, cw, cellH, i == S.selectedBoxSlot, PAL.green) then
        if mon then
          Ops.selectBoxSlot(S, i)
        else
          S.selectedBoxSlot = Gen.ofState(S) == 3 and i or math.min(i, Ops.boxSize(S, box) + 1)
          Ops.openBoxAddPicker(S, Kit)
        end
      end
      Kit.text("tiny", tostring(i), bx + 6 * s, by + 6 * s, PAL.caption)
      if mon then
        Kit.textCenter(
          "small",
          Kit.ellipsize("small", Ops.monName(S, mon), cw - 8 * s),
          bx,
          by + 26 * s,
          cw,
          PAL.text
        )
        Kit.textCenter(
          "tiny",
          "Lv" .. tostring(mon.level),
          bx,
          by + cellH - Kit.textHeight("tiny") - 6 * s,
          cw,
          PAL.caption
        )
      else
        local icon = math.min(row * 0.5, cw * 0.5)
        Kit.icon("plus", bx + (cw - icon) / 2, by + (cellH - icon) / 2, icon, PAL.muted)
      end
    end
    Kit.popClip()
  end
end
function M.draw(S, Kit, x, y, w, h)
  Motion.pages(S, Kit, "boxView", x, y, w, h, drawView)
end
return M
