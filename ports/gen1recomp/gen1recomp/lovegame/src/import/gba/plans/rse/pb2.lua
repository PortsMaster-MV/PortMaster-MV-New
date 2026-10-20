return {
  tasks = {
    {
      id = "berry_blender_pb2",
      run = "steps",
      weight = 0.01,
      steps = {
        { name = "src.import.gba.rse.berry_blender_extract", label = "Berry Blender" },
      },
    },
  },
  sequential = { "berry_blender_pb2" },
  dirs = { "/rse/berry_blender" },
}
