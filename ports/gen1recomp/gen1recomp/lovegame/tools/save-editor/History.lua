-- A bounded, session-only undo stack. Snapshots are made on user mutations,
-- never on draw. Deep copies preserve metadata the editor does not expose.
local Copy = require("src.mods.Merge").deepCopy
local H = { LIMIT = 8 }
function H.capture(S)
  return { save = Copy(S.save), dirty = S.dirty, token = S.historyToken or 0 }
end
function H.record(S, before)
  S.undoStack = S.undoStack or {}
  S.undoStack[#S.undoStack + 1] = before
  while #S.undoStack > H.LIMIT do
    table.remove(S.undoStack, 1)
  end
  S.redoStack = {}
end
local function restore(S, snapshot)
  S.save, S.historyToken = snapshot.save, snapshot.token
  S.dirty = snapshot.token ~= (S.historySavedToken or 0)
  S.editingMon, S.formMon, S.nicknameMon = nil, nil, nil
  S.monDrafts, S.trainerDrafts, S.walletDrafts = {}, {}, {}
  S.propertyChoice, S.itemMenu = nil, nil
  S.navPopup, S.editPopup = nil, nil
  S.speciesPicker, S.movePicker, S.itemPicker = nil, nil, nil
  S.revision = (S.revision or 0) + 1
  require("Gen").ensureBoxes(S.save)
  require("Kit").blur()
  S._quitArmed, S._openArmed = false, false
  S.armed = nil
end
function H.undo(S)
  if not S.undoStack or #S.undoStack == 0 then
    S.status = "Nothing to undo"
    return false
  end
  S.redoStack = S.redoStack or {}
  S.redoStack[#S.redoStack + 1] = H.capture(S)
  restore(S, table.remove(S.undoStack))
  S.status = "Undid the last edit"
  return true
end
function H.redo(S)
  if not S.redoStack or #S.redoStack == 0 then
    S.status = "Nothing to redo"
    return false
  end
  S.undoStack = S.undoStack or {}
  S.undoStack[#S.undoStack + 1] = H.capture(S)
  restore(S, table.remove(S.redoStack))
  S.status = "Redid the last edit"
  return true
end
return H
