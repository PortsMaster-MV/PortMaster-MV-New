local Town = require("src.core.game3.rse.town_common")

local bit = require("bit")

local Bard = {}

-- pokeemerald/include/bard_music.h:5
Bard.MAX_SOUNDS = 6
Bard.NUM_PITCH_TABLES_PER_SIZE = 5
Bard.BASE_PITCH_TABLE_INDEX = Bard.NUM_PITCH_TABLES_PER_SIZE * Bard.MAX_SOUNDS
-- pokeemerald/include/constants/songs.h:554
Bard.PHONEME_ID_NONE = 0xFF
-- pokeemerald/src/mauville_old_man.c:470
Bard.BASE_VOLUME = 0x100
Bard.BASE_PITCH = 0x200
-- pokeemerald/include/constants/global.h:117
Bard.NUM_WORDS = 6

local STATE = { INIT = 0, WAIT_BGM = 1, GET_WORD = 2, HANDLE_WORD = 3, WAIT_WORD = 4, PAUSE = 5 }
local SOUND = { START = 0, PLAY = 1, SET_BASE = 2, END = 3, WAIT = 4 }
Bard.STATE, Bard.SOUND = STATE, SOUND

local function s16(v)
  v = bit.band(v, 0xFFFF)
  if v >= 0x8000 then v = v - 0x10000 end
  return v
end

local function nativePolicy()
  return require("src.core.game3.profile").forSession(Town.session()).oldMan
end

local function numPhonemeSongs()
  local policy = nativePolicy()
  if policy and policy.bardNumPhonemeSongs then return policy.bardNumPhonemeSongs end
  return require("src.core.game3.constants").of("emerald"):require("songs", "NUM_PHONEME_SONGS")
end

local function firstPhonemeSong()
  local policy = nativePolicy()
  if policy and policy.bardFirstPhonemeSong then return policy.bardFirstPhonemeSong end
  local C = require("src.core.game3.constants").of("emerald")
  return C:require("songs", "PH_TRAP_BLEND")
end

local function groupWords(groupId)
  local g = Town.group(groupId)
  return g and g.numWords or 0
end

local EMPTY = {}
for i = 1, Bard.MAX_SOUNDS do EMPTY[i] = { songId = Bard.PHONEME_ID_NONE, lengthAdjustment = 0, volume = 0 } end

local function readTemplates(tbl, index)
  local out = {}
  for s = 0, Bard.MAX_SOUNDS - 1 do
    local b = index * Bard.MAX_SOUNDS * 3 + s * 3
    out[s + 1] = { songId = tbl.t[b + 1], lengthAdjustment = tbl.t[b + 2], volume = tbl.t[b + 3] }
  end
  return out
end

-- pokeemerald/src/easy_chat.c:5172
function Bard.isWordInvalid(word)
  local G = Town.EC_GROUP
  local groupId = bit.rshift(bit.band(word, 0xFFFF), 9)
  local index = bit.band(word, 0x1FF)
  if groupId >= Town.EC_NUM_GROUPS then return true end
  local d = Town.data().bard
  local n
  local policy = nativePolicy()
  if policy and policy.bardNativeGroups then
    n = d.groups[groupId] and d.groups[groupId].words or 0
  elseif groupId == G.POKEMON or groupId == G.POKEMON_NATIONAL then
    n = d.pokemon.words
  elseif groupId == G.MOVE_1 or groupId == G.MOVE_2 then
    n = d.moves.words
  else
    n = groupWords(groupId)
  end
  return n <= index
end

-- pokeemerald/src/bard_music.c:192
function Bard.templatesFor(word)
  if Bard.isWordInvalid(word) then return EMPTY end
  local G = Town.EC_GROUP
  local groupId = bit.rshift(bit.band(word, 0xFFFF), 9)
  local index = bit.band(word, 0x1FF)
  local d = Town.data().bard
  local tbl
  local policy = nativePolicy()
  if policy and policy.bardNativeGroups then
    tbl = d.groups[groupId]
  elseif groupId == G.POKEMON or groupId == G.POKEMON_NATIONAL then
    tbl = d.pokemon
  elseif groupId == G.MOVE_1 or groupId == G.MOVE_2 then
    tbl = d.moves
  else
    tbl = d.groups[groupId]
  end
  if not tbl or index >= tbl.words then return EMPTY end
  return readTemplates(tbl, index)
end

-- pokeemerald/src/mauville_old_man.c:443
function Bard.pitchTableIndex(word)
  return (word % (Bard.NUM_PITCH_TABLES_PER_SIZE - 1)) + bit.band(bit.rshift(word, 3), 1)
end

-- pokeemerald/src/bard_music.c:223
function Bard.calcWordSounds(song, pitchTableIndex)
  local d = Town.data().bard
  local pitches = d.pitchTables[pitchTableIndex + Bard.BASE_PITCH_TABLE_INDEX]
  song.length = 0
  for i = 1, Bard.MAX_SOUNDS do
    local t = song.soundTemplates[i]
    if t.songId ~= Bard.PHONEME_ID_NONE then
      local len = t.lengthAdjustment + (d.phonemeLengths[t.songId] or 0)
      song.sounds[i] = { length = len, pitch = pitches[i] or 0 }
      song.length = song.length + len
    end
  end
  song.soundIndex = 0
  song.voiceInflection = 0
end

local UTF8 = "[%z\1-\127\194-\244][\128-\191]*"

-- pokeemerald/src/mauville_old_man.c:176
function Bard.songText(lyrics)
  local tokens = {}
  local function word(w)
    local text = Town.word(w)
    for ch in text:gmatch(UTF8) do
      tokens[#tokens + 1] = ch == " " and { k = "delim" } or { k = "char", c = ch }
    end
  end
  local li = 1
  for para = 0, 1 do
    word(lyrics[li]); li = li + 1
    tokens[#tokens + 1] = { k = "space" }
    word(lyrics[li]); li = li + 1
    tokens[#tokens + 1] = { k = "newline" }
    word(lyrics[li]); li = li + 1
    if para == 0 then tokens[#tokens + 1] = { k = "ctrl" } end
  end
  tokens[#tokens + 1] = { k = "eos" }
  return tokens
end

local function renderText(tokens, from, to)
  local out = {}
  for i = from, to do
    local t = tokens[i]
    if t.k == "char" then out[#out + 1] = t.c
    elseif t.k == "space" or t.k == "delim" then out[#out + 1] = " "
    elseif t.k == "newline" then out[#out + 1] = "\n" end
  end
  return table.concat(out)
end

-- pokeemerald/src/mauville_old_man.c:482
local function bardSing(task, song, emit)
  local st = task.state
  if st == STATE.INIT then
    song.lyrics = {}
    for i = 1, Bard.NUM_WORDS do song.lyrics[i] = task.lyrics[i] end
    song.lyricsIndex = 0
  elseif st == STATE.GET_WORD then
    local w = song.lyrics[song.lyricsIndex + 1] or 0xFFFF
    song.soundTemplates = Bard.templatesFor(w)
    Bard.calcWordSounds(song, Bard.pitchTableIndex(w))
    song.lyricsIndex = song.lyricsIndex + 1
    if song.soundTemplates[1].songId ~= Bard.PHONEME_ID_NONE then
      song.state = SOUND.START
    else
      song.state = SOUND.END
      song.timer = 2
    end
  elseif st == STATE.HANDLE_WORD or st == STATE.WAIT_WORD then
    local tpl = song.soundTemplates[song.soundIndex + 1]
    if song.state == SOUND.START then
      song.timer = song.sounds[song.soundIndex + 1].length
      if tpl.songId < numPhonemeSongs() then
        emit({ op = "start", phoneme = math.floor(tpl.songId / 3) })
      end
      song.state = SOUND.SET_BASE
      song.timer = song.timer - 1
    elseif song.state == SOUND.SET_BASE then
      song.state = SOUND.PLAY
      if tpl.songId < numPhonemeSongs() then
        song.volume = bit.band(Bard.BASE_VOLUME + tpl.volume * 16, 0xFFFF)
        emit({ op = "volume", value = song.volume })
        song.pitch = s16(Bard.BASE_PITCH + song.sounds[song.soundIndex + 1].pitch)
        emit({ op = "pitch", value = song.pitch })
      end
    elseif song.state == SOUND.PLAY then
      if song.voiceInflection > 10 then song.volume = bit.band(song.volume - 2, 0xFFFF) end
      if bit.band(song.voiceInflection, 1) == 1 then
        song.pitch = s16(song.pitch + 64)
      else
        song.pitch = s16(song.pitch - 64)
      end
      emit({ op = "volume", value = song.volume })
      emit({ op = "pitch", value = song.pitch })
      song.voiceInflection = song.voiceInflection + 1
      song.timer = song.timer - 1
      if song.timer == 0 then
        song.soundIndex = song.soundIndex + 1
        local nextT = song.soundTemplates[song.soundIndex + 1]
        if song.soundIndex ~= Bard.MAX_SOUNDS and nextT.songId ~= Bard.PHONEME_ID_NONE then
          song.state = SOUND.START
        else
          song.state = SOUND.END
          song.timer = 2
        end
      end
    elseif song.state == SOUND.END then
      song.timer = song.timer - 1
      if song.timer == 0 then
        emit({ op = "stop" })
        song.state = SOUND.WAIT
      end
    end
  end
end

-- pokeemerald/src/mauville_old_man.c:604
function Bard.simulate(lyrics, opts)
  opts = opts or {}
  local bgmFrames = opts.bgmFrames or 64
  local tokens = Bard.songText(lyrics)
  local task = { state = STATE.INIT, lyrics = lyrics, wordState = 0, delay = 0, charIndex = 1, lyricsIndex = 0 }
  local song = { sounds = {}, soundTemplates = EMPTY, length = 0, state = SOUND.WAIT, timer = 0,
    volume = 0, pitch = 0, voiceInflection = 0, soundIndex = 0 }
  local frames, events = {}, {}
  local paraStart, printed, enabled, waitBgm = 1, 0, false, 0
  local f = 0
  local done = false
  while not done and f < 20000 do
    local ev = {}
    local function emit(e) ev[#ev + 1] = e end
    bardSing(task, song, emit)
    local st = task.state
    if st == STATE.INIT then
      task.wordState, task.delay, task.charIndex, task.lyricsIndex = 0, 0, 1, 0
      emit({ op = "bgmFadeOut", speed = 4 })
      task.state = STATE.WAIT_BGM
    elseif st == STATE.WAIT_BGM then
      waitBgm = waitBgm + 1
      if waitBgm >= bgmFrames then task.state = STATE.GET_WORD end
    elseif st == STATE.GET_WORD then
      local wordLen, i = 0, task.charIndex
      while tokens[i] and (tokens[i].k == "char" or tokens[i].k == "delim") do
        wordLen = wordLen + 1
        i = i + 1
      end
      if wordLen == 0 then wordLen = 1 end
      local q = song.length / wordLen
      song.length = q >= 0 and math.floor(q) or math.ceil(q)
      if song.length <= 0 then song.length = 1 end
      task.lyricsIndex = task.lyricsIndex + 1
      task.wordState = 0
      task.state = task.delay == 0 and STATE.HANDLE_WORD or STATE.PAUSE
    elseif st == STATE.PAUSE then
      if task.delay == 0 then task.state = STATE.HANDLE_WORD else task.delay = task.delay - 1 end
    elseif st == STATE.HANDLE_WORD then
      local t = tokens[task.charIndex]
      if t.k == "eos" then
        emit({ op = "end" })
        done = true
      elseif t.k == "space" then
        enabled = true
        task.charIndex = task.charIndex + 1
        task.state = STATE.GET_WORD
        task.delay = 0
      elseif t.k == "newline" then
        task.charIndex = task.charIndex + 1
        task.state = STATE.GET_WORD
        task.delay = 0
      elseif t.k == "ctrl" then
        task.charIndex = task.charIndex + 1
        paraStart, printed = task.charIndex, task.charIndex - 1
        task.state = STATE.GET_WORD
        task.delay = 8
      elseif t.k == "delim" then
        enabled = true
        task.charIndex = task.charIndex + 1
        task.delay = 0
      else
        if task.wordState == 0 then
          enabled = true
          task.wordState = 1
        elseif task.wordState == 1 then
          task.wordState = 2
        else
          task.charIndex = task.charIndex + 1
          task.wordState = 0
          task.delay = song.length
          task.state = STATE.WAIT_WORD
        end
      end
    elseif st == STATE.WAIT_WORD then
      task.delay = task.delay - 1
      if task.delay == 0 then task.state = STATE.HANDLE_WORD end
    end
    if enabled and printed < #tokens then
      local j = printed + 1
      while tokens[j] and tokens[j].k == "newline" do j = j + 1 end
      if tokens[j] and (tokens[j].k == "char" or tokens[j].k == "space" or tokens[j].k == "delim") then
        printed = j
      end
      enabled = false
    end
    f = f + 1
    frames[f] = renderText(tokens, paraStart, math.max(paraStart - 1, printed))
    events[f] = ev
  end
  return { frames = frames, events = events, count = f, tokens = tokens, singStart = bgmFrames + 1 }
end

local function audioPack()
  local Audio = require("src.core.game3.audio")
  if Audio._pack then return Audio._pack, Audio._cache end
  local Player = require("src.core.game3.m4a_player")
  local cache = require("src.core.game3.dataset").cache()
  local pack = assert(Player.loadPack(cache, "data/generated/gba/audio"))
  return pack, cache
end

local function applyControl(slot, ctl)
  local seq = slot.seq
  if not seq then return end
  for _, tr in ipairs(seq.tracks or {}) do
    local base = tr._bard
    if not base then
      base = { volume = tr.volume or 100, keyShift = tr.keyShift or 0, tune = tr.tune or 0 }
      tr._bard = base
    else
      if tr.volume ~= base.setVolume then base.volume = tr.volume end
      if tr.keyShift ~= base.setKeyShift then base.keyShift = tr.keyShift end
      if tr.tune ~= base.setTune then base.tune = tr.tune end
    end
    -- pokeemerald/src/m4a.c:1266
    local volX = math.floor(ctl.volume / 4)
    tr.volume = base.volume * volX / 64
    -- pokeemerald/src/m4a.c:1300
    local shiftX = math.floor(ctl.pitch / 256)
    local pitX = ctl.pitch - shiftX * 256
    tr.keyShift = base.keyShift + shiftX
    tr.tune = base.tune + pitX / 4
    base.setVolume, base.setKeyShift, base.setTune = tr.volume, tr.keyShift, tr.tune
    tr._volDirty, tr._pitchDirty = true, true
  end
end

-- pokeemerald/src/mauville_old_man.c:482
function Bard.bake(sim, opts)
  opts = opts or {}
  local Player = require("src.core.game3.m4a_player")
  local Mix = require("src.core.game3.m4a_mix")
  local pack, cache = audioPack()
  local rate = Mix.SAMPLE_RATE
  local first = firstPhonemeSong()
  local slot = { voices = {} }
  local ctl = { volume = Bard.BASE_VOLUME, pitch = 0 }
  local L, R = {}, {}
  local carry, peak, songs = 0, 0, 0
  local fade = nil
  local startFrame = sim.singStart
  for f = startFrame, sim.count + 34 do
    for _, e in ipairs(sim.events[f] or {}) do
      if e.op == "start" then
        slot = { voices = {} }
        Player.start(pack, cache, slot, first + 1 + e.phoneme * 3, { forceSeq = true })
        ctl = { volume = Bard.BASE_VOLUME, pitch = 0 }
        songs = songs + 1
      elseif e.op == "volume" then
        ctl.volume = e.value
      elseif e.op == "pitch" then
        ctl.pitch = e.value
      elseif e.op == "stop" then
        slot = { voices = {} }
      elseif e.op == "end" then
        -- pokeemerald/src/mauville_old_man.c:678
        fade = { frames = 32, left = 32 }
      end
    end
    applyControl(slot, ctl)
    Player.updateSlot(slot, 1)
    local exact = rate / Mix.GBA_VBLANK_HZ + carry
    local n = math.floor(exact)
    carry = exact - n
    slot.hpfState = slot.hpfState or { l = 0, r = 0 }
    slot.reverbState = slot.reverbState or Mix.newReverb(0)
    local outL, outR, alive = Mix.render(slot.voices or {}, n, {
      raw = true, master = 1, sampleRate = rate,
      hpfCapL = slot.hpfState.l, hpfCapR = slot.hpfState.r, hpfState = slot.hpfState,
      reverbState = slot.reverbState,
    })
    slot.voices = alive or slot.voices
    if slot.seq then slot.seq.voices = slot.voices end
    local gain = 1
    if fade then
      gain = math.max(0, fade.left / fade.frames)
      fade.left = fade.left - 1
    end
    for i = 1, n do
      local l, r = (outL[i] or 0) * gain, (outR[i] or 0) * gain
      L[#L + 1], R[#R + 1] = l, r
      local a = math.max(math.abs(l), math.abs(r))
      if a > peak then peak = a end
    end
    if fade and fade.left < 0 then break end
  end
  return { L = L, R = R, samples = #L, seconds = #L / rate, peak = peak, songs = songs, rate = rate }
end

Bard.active = nil

function Bard.stop()
  local a = Bard.active
  Bard.active = nil
  if a and a.source then pcall(function() a.source:stop() end) end
end

function Bard.play(pcm)
  local Audio = require("src.core.game3.audio")
  if not (love and love.audio and love.audio.newSource) then return nil end
  local sd = Audio._buildSeSoundData(pcm.L, pcm.R, Audio._sfxVolume or 1, 0, Audio._mono)
  if not sd then return nil end
  local src = love.audio.newSource(sd, "static")
  src:play()
  return src
end

return Bard
