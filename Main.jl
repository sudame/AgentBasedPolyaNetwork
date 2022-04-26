using StatsBase

AgentId = Int

include("Agent.jl")
include("Environment.jl")
include("Strategy.jl")

"""最初のエージェントと同じパラメータで新しいエージェントを作る"""
function generate_agent_example(env::Environment)
  first_agent::Agent = env.agents[1]
  agent = Agent(env.next_agent_id, first_agent.rho, first_agent.nu, first_agent.strategy)
  env.next_agent_id += 1
  return agent
end

function readable_history(raw::Vector{Tuple{Agent,Agent}})
  return map((agents) -> (agents[1].id, agents[2].id), raw)
end
