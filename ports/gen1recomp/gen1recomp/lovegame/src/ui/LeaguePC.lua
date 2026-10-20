-- PKMN LEAGUE hall-of-fame viewer (engine/menus/league_pc.asm:1)

local Font = require("src.render.Font")
local Strings = require("src.core.Strings")
local HallOfFame = require("src.ui.HallOfFame")

local LeaguePC = { isMenu = true }
LeaguePC.__index = LeaguePC
LeaguePC.isOpaque = true

-- constants/pokemon_data_constants.asm:65
local CAPACITY = 50

-- SGB: SET_PAL_POKEMON_WHOLE_SCREEN per mon (engine/menus/league_pc.asm:95)
function LeaguePC:sgbPalettes(game)
  local P = require("src.render.PaletteFX")
  local mon = self:currentMon()
  local c = mon and P.monPal(game.data, mon.species)
  if c then return { P.whole(c) } end
  return P.wholeNamed(game.data, "MEWMON")
end

function LeaguePC.new(game, onDone)
  local self = setmetatable({}, LeaguePC)
  self.game = game
  self.onDone = onDone
  self.teams = (game.save and game.save.hallOfFame) or {}
  self.teamIndex = math.max(1, #self.teams - CAPACITY + 1)
  self.monIndex = 1
  self.sprites = {}
  self.spriteTrueColor = {}
  self:loadMon()
  return self
end

function LeaguePC:currentMon()
  local team = self.teams[self.teamIndex]
  return team and team[self.monIndex] or nil
end

function LeaguePC:loadMon()
  local mon = self:currentMon()
  if not mon then return end
  local species = mon.species
  if self.sprites[species] == nil then
    local path, trueColor = require("src.pokemon.Sprites").path(
      self.game.data, species, "front", { kind = "hof" })
    local ok, img = false, nil
    if path then ok, img = pcall(love.graphics.newImage, path) end
    self.sprites[species] = ok and img or false
    self.spriteTrueColor[species] = (ok and img and trueColor) or false
  end
  require("src.core.Sound").playCry(self.game.data, species)
end

function LeaguePC:close()
  self.game.stack:pop()
  if self.onDone then self.onDone() end
end

function LeaguePC:update(dt)
  local input = self.game.input
  if input:wasPressed("b") then
    self:close()
    return
  end
  if input:wasPressed("a") then
    if not self:currentMon() then
      self:close()
      return
    end
    local team = self.teams[self.teamIndex]
    if self.monIndex < #team then
      self.monIndex = self.monIndex + 1
    elseif self.teamIndex < #self.teams then
      self.teamIndex = self.teamIndex + 1
      self.monIndex = 1
    else
      self:close()
      return
    end
    self:loadMon()
  end
end

function LeaguePC:draw()
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.rectangle("fill", 0, 0, 160, 144)
  local mon = self:currentMon()
  if not mon then return end
  local img = self.sprites[mon.species]
  if img then
    -- engine/menus/league_pc.asm:98 (hlcoord 12, 5)
    local w, h = img:getDimensions()
    local x = 96 + math.floor((8 - w / 8) / 2) * 8
    local y = 40 + (7 - h / 8) * 8
    love.graphics.draw(img, x, y)
    if self.spriteTrueColor[mon.species] then
      require("src.render.PaletteFX").markTrueColor(x, y, w, h)
    end
  end
  -- engine/movie/hall_of_fame.asm:159
  HallOfFame.drawMonInfo(self, mon)
  -- engine/menus/league_pc.asm:102
  Font.drawBox(0, 13, 20, 4)
  love.graphics.setColor(0, 0, 0, 1)
  Font.draw(Strings("HALL OF FAME No"), 1 * 8, 15 * 8)
  Font.draw(("%3d"):format(self.teamIndex), 16 * 8, 15 * 8)
  love.graphics.setColor(1, 1, 1, 1)
end

return LeaguePC
