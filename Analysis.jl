import Base.findfirst
using ThreadedIterables
include("Environment.jl")

function findfirst(env::Environment, agent_num::Int)
  findfirst(hr -> (hr[1] == agent_num) || (hr[2] == agent_num), env.history)
end

# thanks: https://discourse.julialang.org/t/split-vector-into-n-potentially-unequal-length-subvectors/73548/3
function makechunks(X::AbstractVector{T}, n::Int) where {T}
  L = length(X)
  c = L ÷ n
  Y = Vector{Vector{T}}(undef, n)
  idx = 1
  for i in 1:(n - 1)
    Y[i] = X[idx:(idx + c - 1)]
    idx += c
  end
  Y[end] = X[idx:end]
  return Y
end

function calc_youth_coefficient(env::Environment, n::Int)
  function mean_birthstep_in_chunk(env::Environment, chunk::Vector{Tuple{Int,Int}})
    agent_nums = unique(vcat(collect.(chunk)...))
    mean(map(agent_num -> findfirst(env, agent_num), agent_nums))
  end

  chunks = makechunks(env.history, n)

  map(chunk -> mean_birthstep_in_chunk(env, chunk), chunks)
end

function ginilike_coefficient(env::Environment)
  elements = vcat(collect.(env.history)...)
  r_i = tmap(i -> findfirst(ue -> ue == elements[i], unique(elements)), 1:length(elements))
  x_i = r_i ./ length(unique(elements))
  f_element = element::Int -> sum(elements .== element) / length(elements)

  y_i = tmap(i -> sum(tmap(f_element, unique(elements)[1:r_i[i]])), 1:length(elements))

  sorted = sort(collect(zip(x_i, y_i)); by=first)
  first.(sorted), last.(sorted)
end