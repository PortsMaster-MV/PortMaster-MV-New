-- Starship launcher settings (shared logic in cvars.lua; Starship's CVars are top-level);
-- also forces gOpenMenuBar to 0 (menu closed) and gControlNav to 1
return require("cvars")({
    title = "Starship",
    subtitle = "Star Fox 64 settings",
    help = "In game: press Select, then X to access the menu bar.",
    items = {
        { id = "fps", label = "Frame rate", kind = "choice",
          choices = { { 30, "30 (original)" }, { 60, "60" } },
          help = "60 is smoother but needs a faster device." },
        { id = "lowres", label = "N64 low-res mode", kind = "choice",
          choices = { { 0, "Off" }, { 1, "On" } },
          help = "Renders at the N64's original resolution. Helps on weaker devices." },
        { id = "voice", label = "Voices", kind = "choice",
          choices = { { 0, "Original" }, { 1, "Lylat (EU)" } },
          help = "Lylat voices need an EU Star Fox 64 rom in baseroms/ when the game data is first built." },
        { id = "invert", label = "Invert Y axis", kind = "choice",
          choices = { { 0, "Off" }, { 1, "On" } } },
        "filter",       -- gTextureFilter
        "loglevel",
    },
    keys = {
        fps = { { "gInterpolationFPS" }, 60 },  -- the game's default
        lowres = { { "gLowResMode" }, 0 },
        voice = { { "gVoiceLanguage" }, 0 },
        invert = { { "gInvertYAxis" }, 0 },
    },
    forced = { { { "gOpenMenuBar" }, 0 }, { { "gControlNav" }, 1 } },
})
