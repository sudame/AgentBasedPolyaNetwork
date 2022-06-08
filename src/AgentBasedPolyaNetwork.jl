module AgentBasedPolyaNetwork

include("MyBase.jl")
include("Agent.jl")
include("Environment.jl")
include("Strategy.jl")
include("Util.jl")

export AgentId
export Agent
export Environment,
  find_agent_by_id, append_agents!, init!, interact!, get_caller, get_called, step!
export calc_youth_coefficient, calc_ginilike_coefficient
export wsw_strategy, ssw_strategy
export generate_agent_example, readable_history

end
