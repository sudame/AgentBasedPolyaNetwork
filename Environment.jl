mutable struct Environment
  id::Int
  generate_agent_callback::Function
  agents::Vector{Agent}
  history::Vector{Tuple{AgentId,AgentId}}
  next_agent_id::Int
end

function Environment(id::Int, generate_agent_callback::Function)
  return Environment(id, generate_agent_callback, AgentId[], Tuple{AgentId,AgentId}[], 0)
end

function find_agent_by_id(env::Environment, id::AgentId)
  return filter(a -> a.id == id, env.agents)[1]
end

function append_agents!(env::Environment, agents::Vector{Agent})
  return append!(env.agents, agents)
end

append_agents!(env::Environment, agent::Agent) = append_agents!(env, [agent])

function init!(env::Environment, init_agents::Vector{Agent})
  if length(init_agents) != 2
    throw(ErrorException("初期エージェントが2体ではありません($(length(init_agents))体います)"))
  end

  append_agents!(env, init_agents)
  env.next_agent_id = length(init_agents) + 1

  a1, a2 = init_agents
  append!(a1.urn, fill(a2.id, a1.rho))
  a1.size = a2.rho
  append!(a2.urn, fill(a1.id, a2.rho))
  a2.size = a1.rho

  @inbounds for agent in init_agents
    new_agents = [env.generate_agent_callback(env) for _ in 1:(agent.nu + 1)]
    new_agent_ids = map(a -> a.id, new_agents)
    append_agents!(env, new_agents)
    append!(agent.buffer, new_agent_ids)
  end

  return env
end

function interact!(env::Environment, caller::Agent, called::Agent)
  append!(env.history, [(caller.id, called.id)])
  append!(caller.history, [called.id])
  append!(called.history, [caller.id])

  # 初めてアクセスされるエージェントだった場合、バッファを埋めるだけの新しいエージェントを生成する
  if called.size == 0
    new_agents = [env.generate_agent_callback(env) for _ in 1:(called.nu + 1)]
    new_agent_ids = map(a -> a.id, new_agents)
    append_agents!(env, new_agents)
    append!(called.buffer, new_agent_ids)
    append!(called.urn, new_agent_ids)
    called.size += called.nu + 1
  end

  # 自身の交換とバッファの交換
  append!(caller.urn, [fill(called.id, caller.rho); called.buffer])
  caller.size += caller.rho + called.nu + 1
  append!(called.urn, [fill(caller.id, called.rho); caller.buffer])
  called.size += called.rho + caller.nu + 1

  # バッファの更新
  caller.buffer .= caller.strategy(caller)
  called.buffer .= called.strategy(called)

  return env.history[end]
end

function get_caller(env::Environment)
  return sample(env.agents, Weights(map(a -> a.size, env.agents)))
end

function get_called(env::Environment, caller::Agent)
  while true
    called_id = rand(caller.urn)
    if called_id != caller.id
      return find_agent_by_id(env, called_id)
    end
  end
end

function step!(env::Environment)
  caller = get_caller(env)
  called = get_called(env, caller)
  interact!(env, caller, called)
end