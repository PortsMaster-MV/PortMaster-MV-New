local RseGroups = {}

RseGroups.byWire = {}

function RseGroups.register(wire, spec)
  assert(type(wire) == "string" and type(spec) == "table", "RseGroups.register(wire, spec)")
  RseGroups.byWire[wire] = spec
  return spec
end

function RseGroups.get(wire)
  return RseGroups.byWire[wire]
end

return RseGroups
