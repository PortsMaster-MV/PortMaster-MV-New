The MIDI instrument patches in timidity/ are the patch mix the official
ZQuest Classic web player uses, taken unchanged from the ZQuestClassic
repository (timidity/zc.cfg and the files it references):

- ultra/    original Gravis UltraSound patch set (Advanced Gravis Computer
            Technology; no license file of its own)
- ppl160/   Pro Patches Lite 1.60 by Eero Rasanen (no license file)
- Tone_000/ and Drum_000/  FreePats project patches (https://freepats.zenvoid.org)

timidity.cfg (in the game folder) is upstream's zc.cfg with a
"dir ./timidity" line added in front, so SDL_mixer finds it in the working
directory and the patches under timidity/.
