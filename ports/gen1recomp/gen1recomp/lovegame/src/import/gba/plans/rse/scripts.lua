return {
  tasks = {
    {
      id = "scripts_bfs",
      run = "steps",
      weight = 0.05,
      steps = {
        { name = "extract_scripts", label = "Scripts & Text" },
      },
    },
  },
  sequential = { "scripts_bfs" },
  dirs = { "/scripts", "/trainers" },
}
