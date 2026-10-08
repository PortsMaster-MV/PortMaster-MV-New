local Context = {}

function Context.isContest(vm)
  local ctx = vm and vm.ctx
  return not not (ctx and (ctx.isContest or ctx.contest))
end

return Context
