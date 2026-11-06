-- Experience gain (engine/battle/experience.asm):
--   exp = floor(baseExp * enemyLevel / 7) for a single participant
--   (trainer battles multiply by 1.5 in Gen 1)
-- Stat experience: the defeated species' base stats are added to each
-- participant's stat exp.

local Growth = require("src.pokemon.Growth")
local Runtime = require("src.mods.Runtime")
local Stats = require("src.pokemon.Stats")

local Experience = {}

-- engine/battle/experience.asm order: baseExp is divided by the
-- participant count FIRST, then *level/7, then the traded x1.5
-- (BoostExp) and finally the trainer x1.5.
--
-- EXP.ALL (core.asm .halveExpDataLoop): the base values are halved,
-- GainExperience runs for the participants, then reruns for the whole
-- party -- and because DivideExpDataByNumMonsGainingExp divides the
-- base values IN PLACE, the second pass inherits the participant
-- division: each party member gets (base/2)/participants/partyCount.
-- Sequential floor divisions equal one floor division by the product,
-- so callers pass numParticipants = 2*participants for the first pass
-- and 2*participants*partyCount for the whole-party pass.
--
-- consts is Data.constants; a constants.exp record can retune the
-- divisor and the traded/trainer multipliers, with the values above as
-- the defaults.
function Experience.gainFor(defeatedDef, level, isTrainer, numParticipants,
                            traded, consts)
  local divisor, tradedMult, trainerMult = 7, nil, nil
  local tuning = consts and consts.exp
  if tuning then
    divisor = tuning.divisor or divisor
    tradedMult = tuning.tradedMult
    trainerMult = tuning.trainerMult
  end
  local base = math.floor(defeatedDef.baseExp / math.max(1, numParticipants or 1))
  local exp = math.floor(base * level / divisor)
  if traded then
    exp = math.floor(exp * (tradedMult or 1.5))
  end
  if isTrainer then
    exp = math.floor(exp * (trainerMult or 1.5))
  end
  return math.max(1, exp)
end

-- Applies exp/stat exp; returns the list of levels gained plus the raw
-- exp delta (wExpAmountGained, printed by _ExpPointsText -- captured
-- before the max-level cap, experience.asm:92-100), and the per-level
-- Experience.commit -- engine/battle/experience.asm:158-200
function Experience.apply(data, mon, defeatedDef, level, isTrainer,
                          numParticipants, traded, opts)
  local speciesDef = data.pokemon[mon.species]
  -- stat exp is divided among participants too
  -- (DivideExpDataByNumMonsGainingExp divides wEnemyMonBaseStats)
  local statShare = math.max(1, numParticipants or 1)
  for _, key in ipairs(Stats.ORDER) do
    local gain = math.floor(defeatedDef.baseStats[key] / statShare)
    mon.statExp[key] = math.min(65535, (mon.statExp[key] or 0) + gain)
  end
  local consts = data.constants
  local gained
  if Runtime.wantsHook("exp.gain") then
    gained = Runtime.call("exp.gain", function(c)
      return Experience.gainFor(c.defeatedDef, c.level, c.isTrainer,
                                c.participants, c.traded, consts)
    end, { defeatedDef = defeatedDef, level = level, isTrainer = isTrainer,
           participants = numParticipants, traded = traded, mon = mon })
  else
    gained = Experience.gainFor(defeatedDef, level, isTrainer,
                                numParticipants, traded, consts)
  end
  mon.exp = mon.exp + gained

  local cap = consts and consts.levelCap or 100
  local levels, steps = {}, {}
  local defer = opts and opts.defer
  local newLevel = Growth.levelForExp(speciesDef.growthRate, mon.exp, cap,
                                      data.growth_rates)
  local from = opts and opts.from
  local lv, stats, hp = mon.level, mon.stats, mon.hp
  if from then
    lv, stats, hp = from.level, from.stats, from.hp
  end
  while lv < math.min(newLevel, cap) do
    lv = lv + 1
    local old = stats
    stats = Stats.calc(speciesDef, lv, mon.dvs, mon.statExp)
    hp = math.min(stats.hp, hp + (stats.hp - old.hp))
    table.insert(levels, lv)
    table.insert(steps, { level = lv, stats = stats, hp = hp })
    if not defer then
      mon.level, mon.stats, mon.hp = lv, stats, hp
      if Runtime.wants("pokemon.level_up") then
        Runtime.emit("pokemon.level_up", {
          mon = mon, level = lv, prevLevel = lv - 1,
          learnable = Experience.movesLearnedAt(speciesDef, lv),
        })
      end
    end
  end
  return levels, gained, steps
end

-- engine/battle/experience.asm:168-200
function Experience.commit(data, mon, step)
  mon.level, mon.stats = step.level, step.stats
  mon.hp = math.min(step.stats.hp, step.hp)
  if Runtime.wants("pokemon.level_up") then
    Runtime.emit("pokemon.level_up", {
      mon = mon, level = step.level, prevLevel = step.level - 1,
      learnable = Experience.movesLearnedAt(data.pokemon[mon.species],
                                            step.level),
    })
  end
end

-- Moves learned when reaching exactly `level`.
function Experience.movesLearnedAt(speciesDef, level)
  local out = {}
  for _, entry in ipairs(speciesDef.learnset) do
    if entry.level == level then
      table.insert(out, entry.move)
    end
  end
  return out
end

return Experience
