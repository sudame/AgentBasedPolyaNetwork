using GLM
using Plots

include("MyBase.jl")
include("Agent.jl")
include("Environment.jl")
include("Strategy.jl")
include("Util.jl")
include("Analysis.jl")

function strategies_plot(strategy)
  env = Environment(1, generate_agent_example)

  init_agents = [Agent(1, 10, 10, strategy), Agent(2, 5, 5, strategy)]

  init!(env, init_agents)

  for _ in 1:10000
    step!(env)
  end

  calc_youth_coefficient(env, 1000)
end

function rhos_plot(rho::Int)
  env = Environment(1, generate_agent_example)

  init_agents = [Agent(1, rho, 10, wsw_strategy), Agent(2, rho, 5, ssw_strategy)]

  init!(env, init_agents)

  for _ in 1:10000
    step!(env)
  end

  calc_youth_coefficient(env, 1000)
end

@time ycs = asyncmap(rhos_plot, [1, 5, 10, 20]; ntasks=4)

plot(ycs)

# fitted = glm(collect(1:1000)[:, :], ycs[1], Normal())
# coef(fitted)

# plot(1:1000, ycs[1])
# plot!(1:1000, collect(1:1000) .* coef(fitted); linewidth=2)

env = Environment(1, generate_agent_example)

init_agents = [Agent(1, 20, 5, wsw_strategy), Agent(2, 20, 5, ssw_strategy)]

init!(env, init_agents)

for _ in 1:10000
  step!(env)
end

x, y = ginilike_coefficient(env)
plot(x, y)
