return {
  tasks = {
    {
      id = "audio",
      run = "steps",
      weight = 0.10,
      steps = {
        { name = "extract_audio", label = "Music & Sound Streams" },
      },
    },
  },
  sequential = { "audio" },
  dirs = { "/audio/songs" },
}
