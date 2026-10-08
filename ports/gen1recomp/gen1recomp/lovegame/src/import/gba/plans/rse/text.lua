return {
  tasks = {
    {
      id = "text_chrome",
      run = "steps",
      weight = 0.03,
      steps = {
        { name = "src.import.gba.rse.text_chrome_extract", label = "Fonts & Text Windows" },
        { name = "text_placeholders_extract", label = "Text Placeholders" },
      },
    },
  },
  sequential = { "text_chrome" },
  dirs = { "/chrome", "/chrome/fonts", "/text" },
}
