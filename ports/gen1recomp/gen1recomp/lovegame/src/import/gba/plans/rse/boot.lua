local R = "src.import.gba.rse."

return {
  tasks = {
    {
      id = "em_boot_intro",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = R .. "intro_credits_gfx_extract", label = "Intro: Bike Ride Scenery" },
        { name = R .. "extract_intro_emerald", label = "Intro: Cutscene Graphics" },
        { name = R .. "extract_intro_extra_emerald", label = "Intro: Cutscene Animations" },
      },
    },
    {
      id = "em_boot_screens",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = R .. "extract_title_rse", label = "Title Screen" },
        { name = R .. "extract_birch_rse", label = "Professor Birch" },
        { name = R .. "extract_naming_rse", label = "Naming Screen" },
        { name = R .. "extract_wallclock_rse", label = "Wall Clock" },
        { name = R .. "reset_rtc_extract", label = "Reset RTC" },
      },
    },
  },
  sequential = { "em_boot_intro", "em_boot_screens" },
  dirs = { "/intro/rse", "/intro/rse/scenery", "/intro/rse_extra", "/title", "/birch", "/naming", "/wallclock", "/reset_rtc" },
}
