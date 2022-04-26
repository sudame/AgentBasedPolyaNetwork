mutable struct Agent
  id::AgentId
  rho::Int
  nu::Int
  strategy::Function
  urn::Vector{AgentId}
  buffer::Vector{AgentId}
  history::Vector{AgentId}
  size::Int
end

function Agent(id::Int, rho::Int, nu::Int, strategy::Function)
  return Agent(id, rho, nu, strategy, AgentId[], AgentId[], AgentId[], 0)
end