include("MyBase.jl")
include("Agent.jl")

const WhoUpdateBuffer = Set([:player, :caller, :called])

"""
    Environment(id::Int, generate_agent_callback::Function, [agents:::Vector{Agent}, history::Vector{Tuple{AgentId,AgentId}}, next_agent_id::Int])

エージェントがインタラクションする環境を生成する。

## Properties
- `id::Int` 任意のID
- `generate_agent_callback::Function` エージェント生成時に実行されるコールバック。Environmentを引数に取り、Agentを返す。
- `agents::Vector{Agent}` 環境に存在するエージェント
- `history::Vector{Tuple{AgentId,AgentId}}` 環境で実行されたインタラクションの履歴
- `next_agent_id::Int` 次に生成されるエージェントのID
- `who_update_buffer` インタラクション時に誰がバッファを更新するのか (:both or :caller or :called, default: :both)
"""
mutable struct Environment
  id::Int
  generate_agent_callback::Function
  agents::Vector{Agent}
  history::Vector{Tuple{AgentId,AgentId}}
  next_agent_id::Int
  who_update_buffer::Symbol
end

function Environment(
  id::Int, generate_agent_callback::Function; who_update_buffer::Symbol=:both
)
  Environment(
    id, generate_agent_callback, AgentId[], Tuple{AgentId,AgentId}[], 0, who_update_buffer
  )
end

"""
    find_agent_by_id(env, id)

環境`env`からエージェントID`id`を持つエージェントを検索し、返す。
"""
function find_agent_by_id(env::Environment, id::AgentId)
  return filter(a -> a.id == id, env.agents)[1]
end

"""
    append_agents!(env, agents)

環境`env`に複数のエージェント`agents`を追加する。

    append_agents!(env, agent)

環境`env`に単一のエージェント`agent`を追加する。
"""
function append_agents!(env::Environment, agents::Vector{Agent})
  return append!(env.agents, agents)
end

append_agents!(env::Environment, agent::Agent) = append_agents!(env, [agent])

"""
    init!(env::Environment, init_agents::Vector{Agent})

環境`env`を初期エージェント2つ`init_agents`で初期化する。
"""
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
    agent.birthstep = 1
  end

  return env
end

"""
    function interact!(env::Environment, caller::Agent, called::Agent)

環境`env`上で、インタラクションの起点エージェント`caller`と対象エージェント`called`の間でインタラクションを行う。 \\
インタラクション履歴`env.history`に履歴が追加される。また、必要な場合`env`に新しいエージェントが追加され、壺のサイズなどが更新される。
"""
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
    # append!(called.urn, new_agent_ids)
    called.size += called.nu + 1
    called.birthstep = length(env.history)
  end

  # 自身の交換とバッファの交換
  append!(caller.urn, [fill(called.id, caller.rho); called.buffer])
  caller.size += caller.rho + called.nu + 1
  append!(called.urn, [fill(caller.id, called.rho); caller.buffer])
  called.size += called.rho + caller.nu + 1

  # バッファの更新
  if (env.who_update_buffer ∈ [:caller, :both])
    caller.buffer .= caller.strategy(caller)
  end
  if (env.who_update_buffer ∈ [:called, :both])
    called.buffer .= called.strategy(called)
  end

  return env.history[end]
end

"""
    get_caller(env::Environment)

環境`env`から、エージェントが持つ壺の大きさを重みとしてランダムにエージェントを選択し、返す。
"""
function get_caller(env::Environment)
  return sample(env.agents, Weights(map(a -> a.size, env.agents)))
end

"""
    get_called(env::Environment, caller::Agent)

環境`env`上のエージェント`caller`の壺の中からランダムにインタラクションするエージェントを選択し、返す。
"""
function get_called(env::Environment, caller::Agent)
  while true
    called_id = rand(caller.urn)
    if called_id != caller.id
      return find_agent_by_id(env, called_id)
    end
  end
end

"""
    step!(env::Environment)

環境`env`上でインタラクションを1回行う。

1. インタラクションの起点エージェントを選択する
2. インタラクションの終点エージェントを選択する
3. インタラクションを行う
"""
function step!(env::Environment)
  caller = get_caller(env)
  called = get_called(env, caller)
  interact!(env, caller, called)
end
