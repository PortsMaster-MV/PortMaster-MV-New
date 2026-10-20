local EntryPic = {}

-- pokeemerald/src/contest_util.c:2589
EntryPic.LEFT, EntryPic.TOP = 10, 3

EntryPic.active = false
EntryPic._animation = nil

local function MonPic() return require("src.ui.game3.mon_pic") end

-- pokeemerald/src/contest_util.c:2577
function EntryPic.show(m)
  if EntryPic.active then return end
  local Pokemon = require("src.core.game3.pokemon")
  local MonAnim = require("src.core.game3.mon_anim")
  local species = tonumber(m.species) or 0
  local personality = tonumber(m.personality) or 0
  local shiny = Pokemon.isShiny({ personality = personality, otId = (tonumber(m.otId) or 0) % 65536,
    otSecretId = math.floor((tonumber(m.otId) or 0) / 65536) % 65536 })
  local picSpecies = Pokemon.picSpecies(species, personality)
  local pic = Pokemon.frontPic(Pokemon.picSpecies(species, m.personality), 0,
    shiny, personality)
  local mp = MonPic()
  mp.show(species, EntryPic.LEFT, EntryPic.TOP, { noCry = true })
  if pic and pic.image then
    mp._img, mp._w, mp._h = pic.image, pic.w or 64, pic.h or 64
  end
  EntryPic.active = true
  EntryPic.species = species
  if MonAnim.enabled() then
    local sprite = MonAnim.newSprite(species)
    sprite.data[0], sprite.data[2] = 1, species
    EntryPic._animation = sprite
    MonAnim.battleFront(sprite, species, false, 0)
    MonAnim.run(sprite, {
      onStep = function(s)
        if EntryPic._animation ~= s then return end
        mp._animTransform = MonAnim.transform(s)
        local frame = MonAnim.framePic(picSpecies, s.frame, shiny)
        mp._img = frame and frame.image or (pic and pic.image) or mp._img
      end,
      onDone = function(s)
        if EntryPic._animation == s then mp._animTransform = MonAnim.transform(s) end
      end,
    })
  end
end

-- pokeemerald/src/contest_util.c:2626
function EntryPic.hide()
  if not EntryPic.active then return end
  if EntryPic._animation then require("src.core.game3.mon_anim").stop(EntryPic._animation) end
  EntryPic._animation = nil
  EntryPic.active = false
  MonPic().hide()
end

function EntryPic.reset()
  if EntryPic._animation then require("src.core.game3.mon_anim").stop(EntryPic._animation) end
  EntryPic._animation = nil
  EntryPic.active = false
end

return EntryPic
