local Ops = require("Ops")
local Gen = require("Gen")
local P = require("Properties")
local MonOps = require("MonOps")
local PAL = require("Theme").PAL
local Body = {}
local Motion = require("Motion")
local Chooser = require("Chooser")
local Touch = require("TouchEditor")
local Limits = require("ValueLimits")
local Named = require("NamedChoices")

local function drawSection(S, Kit, x, y, w, h, report, issues)
  local mon = S.editingMon
  if not mon then
    Kit.textWrapped(
      "button",
      "Select a Pokemon to edit its properties, stats, moves and origin.",
      x + 16,
      y + 24,
      w - 32,
      PAL.muted
    )
    return
  end
  local s, pad, gap = Kit.scale, 14 * Kit.scale, 10 * Kit.scale
  local row = Kit.controlH()
  local cx, inner = x + pad, w - 2 * pad
  local g = Gen.ofState(S)
  local sections = {
    { "main", "Main" },
    { "stats", "Stats" },
    { "moves", "Moves" },
    { "origin", "Origin" },
    { "extras", "Extras" },
    { "checks", "Checks" },
  }
  for _, entry in ipairs(sections) do
    entry.errors = issues.sections[entry[1]]
    entry.icon = entry.errors > 0 and "triangle-alert" or Kit.navigationIcon(entry[2])
  end
  S.monSection = S.monSection or "main"
  local navY = y + pad
  local navX = cx
  if S.inspectorBack then
    if Kit.iconButton(cx, navY, row, row, "chevron-left", "Back to party") then
      Motion.change(S, "mobileInspector", false, -1)
    end
    navX = cx + row + gap
  end
  Chooser.navigation(
    S,
    Kit,
    "monSection",
    "Pokemon section",
    sections,
    navX,
    navY,
    math.min(cx + inner - navX, 360 * s),
    row
  )
  local bodyY = navY + row + gap
  local bodyH = math.max(0, y + h - pad - bodyY)
  if S.formMon ~= mon then
    S.formMon, S.monDrafts, S.inspectorScroll = mon, {}, 0
    S._formHeight = 0
    S.propertyChoice = nil
    if Kit.focus and Kit.focus:match("^property%-") then
      Kit.blur()
    end
  end
  S.monDrafts = S.monDrafts or {}
  local layoutKey = tostring(Kit._fontKey) .. ":" .. w .. ":" .. h
  local resizedScroll
  if S._formLayoutKey ~= layoutKey then
    resizedScroll = S.inspectorScroll or 0
    local oldMax = math.max(0, (S._formHeight or 0) - (S._formViewHeight or bodyH))
    if resizedScroll > 0 and resizedScroll >= oldMax - 1 then resizedScroll = math.huge end
    S._formLayoutKey = layoutKey
  end
  S.inspectorScroll =
    Kit.scrollPixels(cx, bodyY, inner, bodyH, S.inspectorScroll or 0, S._formHeight or 0)
  Kit.pushClip(cx, bodyY, inner, bodyH)
  local cy = bodyY - S.inspectorScroll
  local start = cy
  local function text(str, color)
    cy = cy + Kit.textWrapped("small", str, cx, cy, inner, color or PAL.caption) + gap
  end
  local function hint(id)
    cy = cy + Touch.issue(Kit, issues.fields[id], cx, cy, inner)
  end
  if report.errors > 0 then
    text(report.errors .. " saved value errors. Check the red fields.", PAL.red)
  end
  local function button(label, fn, kind, help, id)
    local issue = id and issues.fields[id]
    local opts = { kind = kind, font = "small", invalid = issue ~= nil }
    local buttonH = Kit.buttonHeight(label, inner, opts)
    if help then
      buttonH = Touch.action(S, Kit, label, help, fn, cx, cy, inner, kind, issue)
    elseif Kit.button(cx, cy, inner, buttonH, label, opts) then
      fn()
    end
    cy = cy + buttonH + gap
    if issue and not help then hint(id) end
  end
  local numberX, numberW
  local function field(id, label, value, fn, sanitize)
    if type(value) == "number" then
      label = label:gsub(" %(.-%)", "")
      cy = cy
        + Touch.value(S, Kit, id, label, value, function()
          return Limits.mon(S, mon, id)
        end, numberX or cx, cy, numberW or inner, fn, issues.fields[id])
        + 2 * gap
      return
    end
    text(label, issues.fields[id] and PAL.red or PAL.text)
    local key = "property-" .. id
    local draft = S.monDrafts[id]
    if Kit.focus ~= key and draft == nil then
      draft = tostring(value or "")
    end
    local function apply(v)
      if type(value) == "number" then
        local n = tonumber(v)
        if not n or n ~= math.floor(n) then
          return Ops.say(S, "Enter a whole number")
        end
      end
      if fn(v) then
        S.monDrafts[id] = nil
      end
    end
    local applyW = math.max(row, Kit.textWidth("small", "Set") + 24 * s)
    S.monDrafts[id] = Kit.textfield(
      key,
      cx,
      cy,
      inner - applyW - gap,
      row,
      draft or tostring(value or ""),
      "value",
      { sanitize = sanitize, onSubmit = apply, invalid = issues.fields[id] ~= nil }
    )
    if
      Kit.button(cx + inner - applyW, cy, applyW, row, "Set", { kind = "accent", font = "small" })
    then
      apply(S.monDrafts[id])
      Kit.blur()
    end
    cy = cy + row + 2 * gap
    hint(id)
  end
  local function choice(id, label, value, options, apply)
    cy = cy + Touch.choice(S, Kit, id, label, value, options, cx, cy, inner, apply, nil, issues.fields[id]) + 2 * gap
  end
  local function props(list)
    for _, d in ipairs(list) do
      if d.toggle then
        local on = P.get(mon, d)
        on = on == true or on == 1
        local issue = issues.fields[d.key]
        local shown = issue and tostring(P.get(mon, d)) or (on and "ON" or "OFF")
        local label = d.label .. ": " .. shown
        local opts = { face = "selection", active = on, font = "small", invalid = issue ~= nil }
        local height = Kit.buttonHeight(label, inner, opts)
        if Kit.button(cx, cy, inner, height, label, opts) then
          Ops.setMonProperty(S, mon, d.key, not on)
        end
        cy = cy + height + gap
        hint(d.key)
      elseif Named.property(S, d) then
        choice(d.key, d.label, P.get(mon, d), Named.property(S, d), function(v)
          return Ops.setMonProperty(S, mon, d.key, v)
        end)
      else
        field(d.key, d.label, P.get(mon, d), function(v)
          return Ops.setMonProperty(S, mon, d.key, v)
        end)
      end
    end
  end
  local def = (S.data and S.data.pokemon and S.data.pokemon[mon.species or mon.speciesId]) or {}
  if S.monSection == "main" then
    text(def.name or tostring(mon.species or mon.speciesId), PAL.heading)
    button("Change species", function()
      Ops.openSpeciesPicker(S, Kit)
    end, "accent", nil, "species")
    if S.nicknameMon ~= mon then
      S.nicknameMon, S.nicknameDraft = mon, mon.nickname or ""
    end
    text("Nickname (up to 10 game characters)", PAL.text)
    local setW = math.max(row, 64 * s)
    S.nicknameDraft = Kit.textfield(
      "mon-nickname",
      cx,
      cy,
      inner - setW - gap,
      row,
      S.nicknameDraft or "",
      "no nickname",
      {
        invalid = issues.fields.nickname ~= nil,
        sanitize = function(v)
          return Ops.nicknameSanitize(S, v)
        end,
      }
    )
    if Kit.button(cx + inner - setW, cy, setW, row, "Set", { kind = "accent", font = "small" }) then
      Ops.setNickname(S, mon, S.nicknameDraft)
      Kit.blur()
    end
    cy = cy + row + gap
    hint("nickname")
    button("Clear nickname", function()
      Ops.clearNickname(S, mon)
      S.nicknameDraft = ""
    end, "danger")
    field("level", "Level (1-100)", mon.level, function(v)
      local n = tonumber(v)
      if not require("Legality").integer(n, 1, 100) then
        return Ops.say(S, "Level must be a whole number from 1 to 100")
      end
      return Ops.setLevel(S, mon, n)
    end)
    field("experience", "Experience", Gen.exp(mon), function(v)
      return Ops.setExperience(S, mon, v)
    end)
    field(
      "current-hp",
      "Current HP (max " .. tostring(mon.maxHp or (mon.stats and mon.stats.hp) or 0) .. ")",
      mon.hp or 0,
      function(v)
        return Ops.setCurrentHp(S, mon, v)
      end
    )
    local statuses = {
      { "healthy", "Healthy" },
      { "SLP", "Asleep" },
      { "PSN", "Poisoned" },
      { "BRN", "Burned" },
      { "FRZ", "Frozen" },
      { "PAR", "Paralyzed" },
    }
    if g >= 2 then
      statuses[#statuses + 1] = { "TOX", "Badly poisoned" }
    end
    local savedStatus = mon.status or "healthy"
    if type(savedStatus) == "number" then
      savedStatus = ({ [0]="healthy",[8]="PSN",[16]="BRN",[32]="FRZ",[64]="PAR",[128]="TOX" })[savedStatus]
        or (savedStatus >= 1 and savedStatus <= 7 and "SLP") or savedStatus
    end
    choice("status", "Status", savedStatus, statuses, function(v)
      return Ops.setMonStatus(S, mon, v ~= "healthy" and v or nil)
    end)
    if g >= 2 then
      local held = S.data.items and S.data.items[mon.heldItem or mon.item]
      button("Held item: " .. tostring(held and held.name or "None"), function()
        Ops.openItemPicker(S, Kit, "held")
      end, "accent", nil, "heldItem")
      button("Clear held item", function()
        Ops.setHeldItem(S, mon, nil)
      end, "danger")
      field("friendship", "Friendship (0-255)", mon.friendship or mon.happiness or 0, function(v)
        local n = tonumber(v)
        if not require("Legality").integer(n, 0, 255) then
          return Ops.say(S, "Friendship must be 0-255")
        end
        return Ops.setHappiness(S, mon, n)
      end)
    end
    if g == 3 then
      local Pokemon = require("src.core.game3.pokemon")
      local Summary = require("src.core.game3.summary_data")
      local nature = mon.nature or (tonumber(mon.personality) or 0) % 25
      local natures = {}
      for id = 0, 24 do
        local ok, name = pcall(function()
          return Summary.NATURES[id]
        end)
        natures[#natures + 1] = { id, ok and name or tostring(id) }
      end
      choice("nature", "Nature", nature, natures, function(v)
        return Ops.setNature(S, mon, v)
      end)
      local slot = mon.abilityNum or (tonumber(mon.personality) or 0) % 2
      local abilities = {}
      for i, id in ipairs(Pokemon.abilities(mon.species)) do
        if id and id ~= 0 then
          abilities[#abilities + 1] = { i - 1, Pokemon.abilityName(id) }
        end
      end
      choice("ability", "Ability", slot, abilities, function(v)
        return Ops.setAbility(S, mon, v)
      end)
      local gender = mon.gender or Pokemon.gender(mon.species, tonumber(mon.personality) or 0)
      local ratio = (Pokemon.speciesMeta(mon.species) or {}).genderRatio or 255
      local genders = ratio == 255 and { { "U", "Genderless" } }
        or ratio == 0 and { { "M", "Male" } }
        or ratio == 254 and { { "F", "Female" } }
        or { { "M", "Male" }, { "F", "Female" } }
      choice("gender", "Gender", gender, genders, function(v)
        return Ops.setMonGender(S, mon, v)
      end)
      local shiny = mon.isShiny
      if shiny == nil then shiny = Pokemon.isShiny(mon) end
      button("Shiny: " .. (shiny and "ON" or "OFF"), function()
        Ops.setShiny(S, mon, not shiny)
      end, "warn", "Changes shininess and personality. Review Checks after editing.", "shiny")
    elseif g == 2 then
      local d = P.find(S, "pokerus")
      choice("pokerus", "Pokérus", mon.pokerus or 0, Named.property(S, d), function(v)
        return Ops.setPokerus(S, mon, v)
      end)
      text("Gender, shininess and Unown form follow DVs.")
      for _, id in ipairs({ "gender", "shiny", "form" }) do hint(id) end
    end
    button("Fix all errors", function()
      Ops.fixMonErrors(S, mon)
    end, "good", "Fixes invalid values, stats and PP. Origin warnings still need checking.")
    button(
      "Randomize Pokémon",
      function()
        Ops.randomizeMon(S, mon)
      end,
      "accent",
      "Replaces this Pokémon with a wild one from this game. Real level range, normal moves. Undo brings yours back."
    )
    button(
      "Max out Pokémon",
      function()
        Ops.maxMon(S, mon)
      end,
      "good",
      "Level 100, max IVs or DVs, friendship and PP. Spare EVs go to the strongest stats. Fully heals."
    )
    button("Full heal", function()
      Ops.healMon(S, mon)
    end, "good")
    button("Clone to a box", function()
      Ops.cloneMonToBox(S, mon)
    end, "accent")
  elseif S.monSection == "stats" then
    local keys = g == 3 and { "hp", "atk", "def", "spa", "spd", "spe" }
      or { "hp", "attack", "defense", "speed", "special" }
    local stats = mon.stats or {}
    text(
      ("Calculated: HP %s / Atk %s / Def %s / Spe %s"):format(
        tostring(stats.hp or mon.maxHp or "?"),
        tostring(stats.attack or mon.attack or "?"),
        tostring(stats.defense or mon.defense or "?"),
        tostring(stats.speed or mon.speed or "?")
      ),
      issues.fields.calculated and PAL.red or PAL.heading
    )
    text(
      g == 1 and ("Special: " .. tostring(stats.special or "?"))
        or (
          "Sp. Atk: "
          .. tostring(stats.specialAttack or stats.spAtk or mon.spAtk or "?")
          .. " / Sp. Def: "
          .. tostring(stats.specialDefense or stats.spDef or mon.spDef or "?")
        ),
      issues.fields.calculated and PAL.red or PAL.heading
    )
    hint("calculated")
    text(
      g == 3 and "IVs 0-31. EVs 0-255 with a total limit of 510."
        or "DVs 0-15. HP DV follows the other DVs. Stat experience 0-65535."
    )
    if g == 3 then
      button("Max all IVs", function()
        Ops.maxIvs(S, mon)
      end, "good", "Sets all six IVs to 31. Origin checks may still need review.")
      button("Clear EVs", function()
        Ops.clearEvs(S, mon)
      end, "danger")
      local total = 0
      for _, k in ipairs(keys) do
        total = total + (mon.evs and mon.evs[k] or 0)
      end
      text(
        "EVs: " .. total .. " / 510  ·  " .. math.max(0, 510 - total) .. " free",
        total > 510 and PAL.red or PAL.green
      )
    else
      button("Max all DVs", function()
        Ops.maxDvs(S, mon)
      end, "good", "Sets DVs to 15. In Gen 2 this can change gender and shininess.")
      button("Max stat training", function()
        Ops.maxStatExp(S, mon)
      end, "good", "Fills stat experience for every stat.")
      text("HP DV: " .. tostring(mon.dvs and mon.dvs.hp or 0) .. " / 15 · follows the other DVs", issues.fields["dv-hp"] and PAL.red)
      hint("dv-hp")
    end
    for _, k in ipairs(keys) do
      local paired = Kit.desktop and inner >= 640 * s and (g == 3 or k ~= "hp")
      local startY, leftEnd = cy, cy
      if paired then numberX, numberW = cx, (inner - gap) / 2 end
      local function nextColumn()
        if paired then
          leftEnd, cy = cy, startY
          numberX = cx + numberW + gap
        end
      end
      if g == 3 then
        field(
          "iv-" .. k,
          (
            { hp = "HP", atk = "Attack", def = "Defense", spa = "Sp. Atk", spd = "Sp. Def", spe = "Speed" }
          )[k] .. " IV",
          mon.ivs and mon.ivs[k] or 0,
          function(v)
            return Ops.setIv(S, mon, k, tonumber(v) or 0)
          end
        )
        nextColumn()
        field(
          "ev-" .. k,
          (
            { hp = "HP", atk = "Attack", def = "Defense", spa = "Sp. Atk", spd = "Sp. Def", spe = "Speed" }
          )[k] .. " EV",
          mon.evs and mon.evs[k] or 0,
          function(v)
            return Ops.setEv(S, mon, k, tonumber(v) or 0)
          end
        )
      else
        if k ~= "hp" then
          field("dv-" .. k, k:upper() .. " DV", mon.dvs and mon.dvs[k] or 0, function(v)
            return Ops.setDv(S, mon, k, tonumber(v) or 0)
          end)
          nextColumn()
        end
        field(
          "se-" .. k,
          k:upper() .. " stat experience",
          mon.statExp and mon.statExp[k] or 0,
          function(v)
            return Ops.setStatExp(S, mon, k, v)
          end
        )
      end
      if paired then cy = math.max(cy, leftEnd) end
      numberX, numberW = nil, nil
    end
  elseif S.monSection == "moves" then
    for slot = 1, 4 do
      local mv = mon.moves and mon.moves[slot]
      local id = type(mv) == "table" and (mv.moveId or mv.id) or mv
      local md = id and S.data.moves and S.data.moves[id]
      button("Slot " .. slot .. ": " .. tostring(md and md.name or id or "empty"), function()
        Ops.openMovePicker(S, Kit, slot)
      end, "accent", nil, "move" .. slot)
      if id and id ~= 0 then
        local pp = type(mv) == "table" and mv.pp or mon.pp and mon.pp[slot] or 0
        local ups = MonOps.getPpUps(mon, slot)
        local max = MonOps.calcMaxPp(MonOps.getBasePp(S.data, mon, slot), ups, g)
        field("pp-" .. slot, "Current PP (max " .. max .. ")", pp, function(v)
          return Ops.setPp(S, mon, slot, tonumber(v) or 0)
        end)
        field("ppup-" .. slot, "PP Ups (0-3)", ups, function(v)
          return Ops.setPpUps(S, mon, slot, tonumber(v) or 0)
        end)
        button("Clear slot " .. slot, function()
          Ops.clearMove(S, mon, slot)
        end, "danger")
      end
    end
    button("Reset to learnset", function()
      Ops.resetMoves(S, mon)
    end)
    button("Max all PP", function()
      Ops.maxAllPpUps(S, mon)
    end, "good")
  elseif S.monSection == "origin" then
    props(P.identity(S))
    if g == 2 and Gen.hasCaughtData(S.save, S.version) then
      button("Caught by: " .. tostring(mon.caughtByGender or "none"), function()
        Ops.setCaughtByGender(S, mon, mon.caughtByGender == "boy" and "girl" or "boy")
      end)
    end
  elseif S.monSection == "extras" then
    if g == 3 then
      text("Contest conditions", issues.fields.contest and PAL.red)
      hint("contest")
      props(P.contest)
      text("Ribbons: setting a ribbon does not establish award or event eligibility.", issues.fields.ribbons and PAL.red)
      hint("ribbons")
      props(P.ribbons)
    else
      text("This generation has no contest conditions or ribbons.")
    end
  else
    button("Fix all errors", function()
      Ops.fixMonErrors(S, mon)
    end, "good", "Fixes invalid values, stats and PP. Does not invent encounter or event history.")
    text(
      report.errors > 0 and (report.errors .. " property errors")
        or "Values pass. Origin still needs checking.",
      report.errors > 0 and PAL.red or PAL.yellow
    )
    for _, check in ipairs(report.checks) do
      text(
        check.kind:upper() .. ": " .. check.message,
        check.kind == "error" and PAL.red or check.kind == "pass" and PAL.green or PAL.yellow
      )
    end
  end
  S._formHeight = cy - start
  S._formViewHeight = bodyH
  if resizedScroll then
    S.inspectorScroll = Ops.clamp(resizedScroll, 0, math.max(0, S._formHeight - bodyH))
  end
  Kit.popClip()
  Kit.scrollbar(cx, bodyY, inner, bodyH, S.inspectorScroll, S._formHeight, bodyH)
end
function Body.draw(S, Kit, x, y, w, h)
  local report = require("Legality").mon(S, S.editingMon)
  local issues = require("Legality").highlights(report, S.editingMon)
  Motion.pages(S, Kit, "monSection", x, y, w, h, function(state, kit, px, py, pw, ph)
    drawSection(state, kit, px, py, pw, ph, report, issues)
  end)
end
return Body
