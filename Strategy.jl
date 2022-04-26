function wsw_strategy(agent::Agent)::Vector{AgentId}
  cm::Dict = countmap(agent.urn)
  p = collect(keys(cm))
  w = weights(collect(values(cm)))
  return sample(p, w, agent.nu + 1; replace=false)
end

function ssw_strategy(agent::Agent)::Vector{AgentId}
  # もしすでにバッファの中に今インタラクションしたエージェントが入っているならバッファの更新はしない
  if agent.history[end] in agent.buffer
    return agent.buffer
  end

  # 入っていなければFIFOでバッファを更新
  popfirst!(agent.buffer)
  push!(agent.buffer, agent.history[end])
  return agent.buffer
end